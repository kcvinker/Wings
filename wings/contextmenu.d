// Created on 30-July-2022 06:52 PM

/* =========================================ContextMenu Docs=======================
Constructor:
    this()
    this(Control parent)
    this(TrayIcon tray)
    this(Control parent, string[] menuNames ...)
    this(TrayIcon tray, string[] menuNames ...)
    this(TrayIcon tray, string[] menuNames ...) 

Methods:
    MenuItem addMenuItem(string item)
    void addMenuItems(string[] menuNames ...)
    MenuItem opIndex(string name)
    MenuItem addMenuItem(string item, EventHandler evtFn)

Events:
    EventHandler onMenuShown; 
    EventHandler onMenuClose;

Properties:
    TODO: write this.


==================================================================================*/


module wings.contextmenu; 

import core.sys.windows.windows;

import wings.controls: Control;
import wings.menubar: MenuBase, MenuItem, getMenuItem, ParentKind;
import wings.events: EventHandler, EventArgs;
import wings.commons: getMousePoints, getMousePos, getAs, print;

enum wstring cmenuWndClass = "Wings_Cmenu_Msg_Window";
enum UINT tpm_flag = TPM_LEFTBUTTON | TPM_RETURNCMD;
//-----------------------------------------------------------------------

class ContextMenu : MenuBase 
{
    import wings.application: appData;
    import wings.trayicon: TrayIcon;
    import wings.colors: makeHBRUSH, getClrRef;
    import wings.fonts: Font;
    import wings.enums: MenuType;

    this () 
    {
        this.mHandle = CreatePopupMenu();
        this.mWidth = 120;
        this.mHeight = 25;
        this.mRightClick = true;
        this.mFont = new Font("Tahoma", 11);
        this.mDefBgBrush = makeHBRUSH(0xe9ecef);
        this.mHotBgBrush = makeHBRUSH(0x90e0ef);
        this.mBorderBrush = makeHBRUSH(0x0077b6);
        this.mGrayBrush = makeHBRUSH(0xced4da);
        this.mGrayCref = getClrRef(0x979dac);
        if (!mMsgWinRegistered) {
            appData.registerMsgOnlyWindow(cmenuWndClass.ptr, &cmenuWndProc);
            mMsgWinRegistered = true;
        }             
    }

    this(Control parent, string[] menuNames ...) 
    {
        this();
        this.mParent = parent;
        this.setMenuInternal(menuNames);
        this.createCmenuHandle(); 
    }

    this(TrayIcon tray, bool cdraw, string[] menuNames ...) 
    {
        this();
        this.mTray = tray;
        this.mCustDraw = cdraw;
        this.setMenuInternal(menuNames);
        this.createCmenuHandle();
    }

    this(Control parent) 
    {
        this();
        this.mParent = parent;
    }

    this(TrayIcon tray) 
    {
        this();
        this.mTray = tray;
    }

    ~this()
    {
        /*----------------------------------------------------------
        When context menu dissappers, the backing message-only window
        wil be destroyed. However, we can destroy our menu related 
        resources when program ends.
        ------------------------------------------------------------*/
        if (this.mMenus.length > 0) {
            foreach (menu; this.mMenus) menu.finalize();
        }
        DeleteObject(this.mDefBgBrush);
        DeleteObject(this.mHotBgBrush);
        DeleteObject(this.mBorderBrush);
        DeleteObject(this.mGrayBrush);
        DestroyMenu(this.mHandle);
        // writeln("Context menu dtor worked");
    }

    /// Add a menu item or a separator('|') to this context menu. 
    MenuItem addMenuItem(string item) 
    {
        MenuType mtyp = item == "|" ? MenuType.separator : MenuType.normalMenu;
        MenuItem mi = new MenuItem(item, mtyp, this.mHandle, this.mMenuCount);
        mi.mParentKind = ParentKind.contextMenu;
        this.mMenuCount += 1;
        this.mMenus ~= mi;
        return mi;
    }

    /// Add menu items to this context menu. Use '|' for a separator.
    void addMenuItems(string[] menuNames ...) { this.setMenuInternal(menuNames);}

    /// Get menu item with given name.
    MenuItem opIndex(string name) 
    { 
        if (this.mMenus.length > 0) {
            foreach (menu; this.mMenus) {
                if (menu.mText == name) return menu;
            }
        }
        return null;
    }

    /// Add a menu item with event handler for onClick event.
    MenuItem addMenuItem(string item, EventHandler evtFn)
    {
        auto mi = this.addMenuItem(item);
        if (mi.mType != MenuType.separator) mi.onClick = evtFn;
        return mi;
    }

    void addClickHandler(string menuName, EventHandler callback)
    {
        if (this.mMenus.length > 0) {
            foreach (menu; this.mMenus) {
                if (menu.mText == menuName) {
                    menu.onClick = callback;
                    break;
                }                 
            }
        }
    }

    void setMenuTag(string menuName, Object obj)
    {
        if (this.mMenus.length > 0) {
            foreach (menu; this.mMenus) {
                if (menu.mText == menuName) {
                    menu.mTag = obj;
                    break;
                }                 
            }
        }
    }

    package:
        Control mParent;
        TrayIcon mTray;
        bool mCmenuCreated;
        bool mCustDraw;
        Font mFont;
        HWND mDummyHwnd;

        // Display context menu on right click or short key press.
        // Both TrayIcon and Control class use this function.
        // When using from tray icon, lpm would be zero.
        void showMenu(LPARAM lpm) 
        {
            /*-------------------------------------------------------------------
            We are creating our message-only window here. We will destroy it
            when this scope exits. 
            --------------------------------------------------------------------*/
            this.setDummyWindow();
            scope(exit) {
                DestroyWindow(this.mDummyHwnd);
                this.mDummyHwnd = null; 
            }
            if (!this.mFont.handle) this.mFont.createFontHandle();
            if (this.mMenus.length) {
                POINT pt;
                getMousePos(pt, lpm);

                //print("dwd lpm ", cast(short)(cast(ushort)lpm));
                /*-------------------------------------------------
                If ContextMenu is generated by a keybord shortcut 
                like 'Ctrl + F10' or 'VK_APPS' key, x & y might be -1.
                So we need to find the mouse position on our own.
                    --------------------------------------------------*/
                if (pt.x == -1 && pt.y == -1) getMousePoints(pt);

                /*--------------------------------------------------------
                This is a hack. If context menu is displayed from a tray icon
                A window from this thread must be in forground, otherwise we 
                won't get any keyboard messages. If user wants to select any 
                menu item, we must activate any window. So we are bringing our
                tray's message-only window to foreground. 
                --------------------------------------------------------------*/  
                // print("lpm in showMenu ", lpm);              
                // if (!lpm) 
                SetForegroundWindow(this.mTray.mMsgHwnd);

                /*------------------------------------------------------------------------
                We are using TPM_RETURNCMD in the tpm_flag, so we don't get the 
                WM_COMMAND in our wndproc, we will get the selected menu id in return value.
                ----------------------------------------------------------------------------*/
                auto mid = TrackPopupMenu(this.mHandle, tpm_flag, pt.x, pt.y, 0, this.mDummyHwnd, null);

                // if (this.mTray) PostMessageW(this.mTray.mMsgHwnd, WM_NULL, 0, 0);
                /*-------------------------------------------------------------
                We got the result here. So if user has selected any menu item,
                we need to find the menu item and execute it's onClick handler.
                ---------------------------------------------------------------*/
                if (mid > 0) {
                    auto menu = this.getMenuItem(mid);
                    if (menu && menu.onClick && menu.mEnabled) {
                        menu.onClick(menu, new EventArgs());
                        return;
                    }
                    return;
                }
            } else {
                throw new Exception("No menu items added to ContextMenu");
            }
        }

        MenuItem getMenuItem(int idNum) {
            foreach (menu; this.mMenus) {                
                if (menu.mId == idNum) return menu;
            }
            return null;
        }        

    EventHandler onMenuShown;
    EventHandler onMenuClose; 
    
        
    private:
        int mWidth, mHeight, mMenuCount;
        bool mRightClick;
        static bool mMsgWinRegistered;
        COLORREF mGrayCref;
        HBRUSH mDefBgBrush, mHotBgBrush, mBorderBrush, mGrayBrush;

        void setMenuInternal(string[] menuNames) {
            if (menuNames.length > 0) {
                foreach (name; menuNames) {
                    auto mtyp = name == "|" ? MenuType.separator : MenuType.normalMenu;
                    auto mi = new MenuItem(name, mtyp, this.mHandle, this.mMenuCount);
                    mi.mParentKind = ParentKind.contextMenu;
                    this.mMenuCount += 1;
                    this.mMenus ~= mi;
                }
            }
        }

        void createCmenuHandle()
        {
            if (this.mMenus.length > 0) {
                UINT drawFlag = MF_STRING;
                if (this.mCustDraw) {
                    drawFlag = MF_OWNERDRAW;
                    HDC hdcmem = CreateCompatibleDC(null);
                    scope(exit) DeleteDC(hdcmem);
                    HGDIOBJ oldfont = SelectObject(hdcmem, cast(HGDIOBJ)this.mFont.mHandle);
                    scope(exit) SelectObject(hdcmem, oldfont);
                    foreach (menu; this.mMenus) {
                        GetTextExtentPoint32(hdcmem, menu.mWideText, 
                                            cast(int)menu.text.length, 
                                            &menu.mTxtSize);
                        // Ensure minimum width for base menus
                        if (menu.mType == MenuType.baseMenu) {
                            if (menu.mTxtSize.cx < 100) {
                                menu.mTxtSize.cx = 100; 
                            } else {
                                menu.mTxtSize.cx =+ 20;
                            }
                        } 
                    }
                }
                foreach (menu; this.mMenus) menu.insertCmenuInternal(drawFlag);
                this.mCmenuCreated = true;
            }            
        }

        void setDummyWindow() 
        {
            this.mDummyHwnd = CreateWindowExW(0, cmenuWndClass.ptr, null, 
                                                0, 0, 0, 0, 0, HWND_MESSAGE, 
                                                null, appData.hInstance, null);
            if (this.mDummyHwnd) {
                SetWindowLongPtrW(this.mDummyHwnd, GWLP_USERDATA, (cast(LONG_PTR) cast(void*) this));
                // writeln("Context menu message-only window created");
            } 
        }

} // End of ContextMenu class

enum MenuStyle {
    leftToRight = 0x400,
    rightToLeft = 0x800,
    topToBottom = 0x1000,
    bottomToTop = 0x2000,
    none = 0x4000
}

enum MenuPosition {
    leftAlign,
    topAlign = 0,
    centerAlign = 4,
    rightAlign = 8,
    vCenterAlign = 10,
    bottomAlign = 20
}



extern(Windows)
private LRESULT cmenuWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) nothrow
{
    try {
        // print("Cmenu Wndproc rcvd", message);
        switch (message) {            
            // case WM_DESTROY:        
            //     writeln("Cmenu Message only window got WM_DESTROY");
            // break;
            case WM_MEASUREITEM:
                auto cm = getAs!ContextMenu(hWnd);
                auto pmi = cast(LPMEASUREITEMSTRUCT) lParam;
                pmi.itemWidth = UINT(cm.mWidth);
                pmi.itemHeight = UINT(cm.mHeight);
                return 1;
            break;
            case WM_DRAWITEM:
                auto cm = getAs!ContextMenu(hWnd);
                auto dis = cast(LPDRAWITEMSTRUCT) lParam;
                auto mi = getMenuItem(dis.itemData);
                COLORREF txtClrRef = mi.mFgColor.cref;
                if (dis.itemState & 1) {
                    if (mi.mEnabled) {
                        auto rc = RECT(dis.rcItem.left + 4, dis.rcItem.top + 2, 
                                        dis.rcItem.right, dis.rcItem.bottom - 2);
                        FillRect(dis.hDC, &rc, cm.mHotBgBrush);
                        FrameRect(dis.hDC, &rc, cm.mBorderBrush);
                        txtClrRef = 0x00000000;
                    } else {
                        FillRect(dis.hDC, &dis.rcItem, cm.mGrayBrush);
                        txtClrRef = cm.mGrayCref;
                    }
                } else {
                    FillRect(dis.hDC, &dis.rcItem, cm.mDefBgBrush);
                    if (!mi.mEnabled) txtClrRef = cm.mGrayCref;
                }
                SetBkMode(dis.hDC, 1);
                dis.rcItem.left += 25;
                SelectObject(dis.hDC, cm.mFont.handle);
                SetTextColor(dis.hDC, txtClrRef);
                DrawTextW(dis.hDC, mi.mWideText, -1, &dis.rcItem, DT_LEFT | DT_SINGLELINE | DT_VCENTER);
                return 0;
            break;
            case WM_ENTERMENULOOP: 
                auto cm = getAs!ContextMenu(hWnd);
                if (cm.onMenuShown) cm.onMenuShown(cm.mParent, new EventArgs()); 
                // print("Cmenu Wndproc WM_ENTERMENULOOP");
            break;
            case WM_EXITMENULOOP: 
                auto cm = getAs!ContextMenu(hWnd);
                if (cm.onMenuClose) cm.onMenuClose(cm.mParent, new EventArgs()); 
                // print("Cmenu Wndproc WM_EXITMENULOOP");           
            break;
            case WM_MENUSELECT:
                auto cm = getAs!ContextMenu(hWnd);
                immutable int idNum = cast(int) (LOWORD(wParam));
                auto hMenu = cast(HMENU) lParam;
                if (hMenu && idNum > 0) {
                    auto menu = cm.getMenuItem(idNum);
                    if (menu && menu.mEnabled) {
                        if (menu.onFocus) menu.onFocus(menu, new EventArgs());
                    }
                }
            break;         
            default: break;
        }
    }
    catch (Exception e){}
    return DefWindowProcW(hWnd, message, wParam, lParam);
}



