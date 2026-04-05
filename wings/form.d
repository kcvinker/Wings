    
/*==============================================Form Docs=====================================
    Constructor : Control 
        this ()
        this(string title)
        this(string title, int w, int h)

	Properties:
		Form inheriting all Control class properties	
        startPos
        style
        topMost
        formState
        maximizeBox
        minimizeBox
        createChildHandles
			
    Methods:
        createHandle
        show
        setGradientColors
        close
        enablePrintPoint
        addHotKey
        removeHotKey
        addMenuBar
        addTimer
        
    Events:
        All public events inherited from Control class. (See controls.d)
        EventHandler - void delegate(Object, EventArgs)
            onMinimized
            onMaximized
            onRestored
            onClosing
            onClosed
            onLoad
            onActivate
            onDeActivate
            onMoving
            onMoved
	    SizeEventHandler - void delegate(Object, SizeEventArgs)
            onSized
            onSizing
        ThreadMsgHandler - void delegate(WPARAM, LPARAM)
            onThreadMsg  
                  
=============================================================================================*/
module wings.form;


import std.stdio;
import std.datetime.stopwatch;
import std.algorithm.mutation; // We have a function called 'remove'. So this must be renamed.
import wings.d_essentials;

import wings.events;
import wings.fonts;
import wings.enums;
import wings.controls;
import wings.commons;
import wings.application: appData, formClass, GEA;
import wings.menubar : MenuBar, MenuItem, getMenuItem;
import wings.timer;


// Compile time values to use later
package enum string defWinFontName = "Tahoma";
package enum int defWinFontSize = 12;
package enum FontWeight defWinFontWeight = FontWeight.normal;


DWORD newStyle = WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN | WS_CLIPSIBLINGS;


///This class is a form class
class Form : Control 
{
    // Imports---------------
    import wings.gradient;  
    import wings.winstyle_contsants;
    import wings.colors;

    // properties------------------------------
    mixin finalProperty!("startPos", this.mStartPos);
    mixin finalProperty!("style", this.mWinStyle);
    mixin finalProperty!("topMost", this.mTopMost);
    mixin finalProperty!("formState", this.mWinState);
    mixin finalProperty!("maximizeBox", this.mMaxBox);
    mixin finalProperty!("minimizeBox", this.mMinBox);
    mixin finalProperty!("createChildHandles", this.mAutoCreate);
    

    //final override uint backColor() const {return this.mBackColor;}
    final override void backColor(uint clr) {propBackColorSetter(clr);}
    // final HINSTANCE hInstace() {return appData.hInstance;}

    EventHandler onMinimized, onMaximized, onRestored, onClosing, onClosed, onLoad;
    EventHandler onActivate, onDeActivate, onMoving, onMoved;
    SizeEventHandler onSized, onSizing;
    // HotKeyEventHandler onHotKeyPress;
    ThreadMsgHandler onThreadMsg;


    ///the constructor of form class
    private this(string txt, int x, int y, int w, int h)
    {
        if (!appData.isFormInit) appData.initWindowMode();
        appData.frmCount += 1;
        this.callDtor = true;
        this.mWindowID = mFormCount;
        this.mText = txt;
        this.mWidth = w;
        this.mHeight = h;
        this.mXpos = x;
        this.mYpos = y;
        this.mStartPos = FormPos.center;
        this.maximizeBox = true;
        this.minimizeBox = true;
        this.mWinStyle = FormStyle.normalWin;
        this.mBkDrawMode = FormBkMode.normal;
        this.mFont = new Font(appData.appFont);
        this.controlType = ControlType.window;
        this.mBackColor = appData.appColor; // using opCall feature
        mFormCount += 1; // Incrementing private static variable
    }

    this () {
        string title = format("%s_%d", "Form", mFormCount + 1);
        this(title, 0, 0, 500, 450);
    }

    this(string title)
    {
        this(title, 0, 0, 500, 450);
    }

    this(string title, int w, int h)
    {
        this(title, 0, 0, w, h);
    }

    // ~this() 
    // {
    //     // if (this.callDtor) {
    //     //     this.finalize();
    //     // } else {
    //     //     // writeln("Form class dtor worked");
    //     // }
    // }

    /// Creates the window
    override void createHandle()
    {
        import std.stdio;
        setStartPos();
        setWindowStyles();
        //auto sw = StopWatch(AutoStart.no);
        //sw.start();

        this.mHandle = CreateWindowExW( this.mExStyle,
                                        formClass.ptr,
                                        this.mText.toUTF16z,
                                        this.mStyle,
                                        this.mXpos,
                                        this.mYpos,
                                        this.mWidth,
                                        this.mHeight,
                                        null,
                                        menuHwnd,
                                        appData.hInstance,
                                        cast(PVOID)this);

        if (this.mHandle ) {
            this.mIsCreated = true;
            if (appData.mainHwnd == null) appData.mainHwnd = this.mHandle;
            // setThisPtrOnWindows(this, this.mHandle);
            this.mFont.mHwndParent = this.mHandle;
            this.setFontInternal();
        } else {
            throw new Exception("Form is not created..."); // Do we need this ?
        }
    }

    /// This will show the form on the screen
    final void show(DWORD swParam = SW_SHOW)
    {
        this.createControlHandles();
        ShowWindow(this.mHandle, swParam);
        UpdateWindow(this.mHandle);

        if (this.mWinState == FormState.minimized) {CloseWindow(this.mHandle); }

        // Only start the main loop if it is not already started.
        if(!appData.isMainLoopOn) appData.mainLoop();
    }

    /// This will set the gradient background color for this window.
    final void setGradientColors(uint c1, uint c2, bool r2l = false)
    {
        this.mBkDrawMode = FormBkMode.gradient;
        this.mGdraw.c1 = Color(c1);
        this.mGdraw.c2 = Color(c2);
        this.mGDR2L = r2l;
        this.checkRedrawNeeded();
    }

    /// closes the window
    final void close() { CloseWindow(this.mHandle);}

    /// An handy feature for design time.
    final void enablePrintPoint()
    {
        import std.functional;
        this.onMouseUp = toDelegate(&printFormPoints);
    }

    final int addHotKey(Key[] keyList, EventHandler pFunc, bool noRepeat = false)
    {
        int res = -1;
        if (this.mIsCreated) {
            int hkid = regNewHotKey(this.mHandle, keyList, noRepeat);
            if (hkid > -1) {
                this.mHkeyMap[hkid] = pFunc;
                res = hkid;
            }            
        }
        return res;
    }

    final bool removeHotKey(int hkeyID)
    {
        bool res = false;
        if (hkeyID in this.mHkeyMap) {
            BOOL x = UnregisterHotKey(this.mHandle, hkeyID);
            if (x != 0) {
                this.mHkeyMap.remove(hkeyID);
                res = true;
            }
        }
        return res;
    }

    final MenuBar addMenuBar(bool cdraw, string[] menuNames...)
    {
        auto mbar = new MenuBar(this, cdraw);
        mbar.mFont = new Font(this.font);
        if (menuNames.length > 0) mbar.addItems(menuNames);
        this.mMenubarCreated = true;
        return mbar;
    }

    final Timer addTimer(EventHandler tickHandler, UINT interval = 100, )
    {
        auto timer = new Timer(this.mHandle, interval, tickHandler);
        this.mTimerMap[timer.mIdNum] = timer;
        return timer;
    }

    

    // final void hideWindow() {
    //     this.sendMsg(WM_SHOWWINDOW, false, )
    // }

    package : //----------------------------------
        bool misBkClrChanged;
        bool mIsLoaded;
        bool mIsMouseTracking;
        bool mIsMouseEntered;
        bool mSizingStarted;
        bool mMenubarCreated;
        bool mAutoCreate;
        FormBkMode mBkDrawMode;
        HWND[HWND] cmb_dict;
        Font mMenuFont;
        MenuItem[uint] mMenuItemDict;
        Control[] mControls;
        HBRUSH tbBrush;
        MenuBar mMenubar;


        // This function is responsible for changing back color of window..
        // in the WndProc function, in the occurance of WM_ERASEKBGND
        final void setBkClrInternal(HDC dcHandle) { // package
            RECT rct;
            GetClientRect(this.mHandle, &rct);
            HBRUSH hBr;
            scope(exit) DeleteObject(hBr);

            if (this.mBkDrawMode == FormBkMode.singleColor ) {
                hBr = CreateSolidBrush(this.mBackColor.cref);
            }
            else if (this.mBkDrawMode == FormBkMode.gradient) {
                hBr = createGradientBrush(dcHandle, rct, this.mGdraw.c1, this.mGdraw.c2, this.mGDR2L);
            }

            FillRect(dcHandle, &rct, hBr);
        }

        final void setMenuClickHandler( MenuItem mi) { this.mMenuItems ~= mi;}

        final MenuItem getMenuFromHmenu(HMENU menuHandle) {
            foreach (key, menu; this.mMenuItemDict) {if (menu.mHandle == menuHandle) return menu;}
            return null;
        }




    private : //-------------------------------
        static int mFormCount;
        int mWindowID;
        static bool mMainLoopStarted;
        static int screenWidth;
        static int screenHeight;
        static int mGlobalHotKeyID = 100;
        int iNumber;
        EventHandler[int] mHkeyMap;
        Timer[UINT_PTR] mTimerMap;
        bool callDtor;
        bool isLoaded;
        bool mTopMost;
        bool mMaxBox;
        bool mMinBox;
        bool mGDR2L; // Gradient draw right to left
        
        HMENU menuHwnd;
        DWORD winStyle = WS_OVERLAPPEDWINDOW;
        FormPos mStartPos;
        FormStyle mWinStyle;
        FormState mWinState;
        GradColor mGdraw;
        MenuItem[] mMenuItems; // dictionary(key = uint, value = MenuItem)


        void setStartPos()
        { // Private
            switch (this.mStartPos) {
                case FormPos.center :
                    this.mXpos = (appData.screenWidth - this.mWidth) / 2;
                    this.mYpos = (appData.screenHeight - this.mHeight) / 2;
                    break;

                case FormPos.topLeft  : break;
                case FormPos.manual   : break;

                case FormPos.topMid   :
                    this.mXpos = (appData.screenWidth - this.mWidth) / 2; break;
                case FormPos.topRight :
                    this.mXpos = appData.screenWidth - this.mWidth; break;
                case FormPos.midLeft  :
                    this.mYpos = (appData.screenHeight - this.mHeight) / 2; break;
                case FormPos.midRight :
                    this.mXpos = appData.screenWidth - this.mWidth;
                    this.mYpos = (appData.screenHeight - this.mHeight) / 2; break;
                case FormPos.bottomLeft :
                    this.mYpos = appData.screenHeight - this.mHeight; break;
                case FormPos.bottomMid :
                    this.mXpos = (appData.screenWidth - this.mWidth) / 2;
                    this.mYpos = appData.screenHeight - this.mHeight; break;
                case FormPos.bottomRight :
                    this.mXpos = appData.screenWidth - this.mWidth;
                    this.mYpos = appData.screenHeight - this.mHeight; break;
                default: break;
            }

        }

        void setWindowStyles()
        { // Private
            switch(this.mWinStyle) {
                case FormStyle.fixed3D :
                    this.mExStyle = fixed3DExStyle;
                    this.mStyle = fixed3DStyle;
                    if (!this.maximizeBox) this.mStyle = this.mStyle ^ WS_MAXIMIZEBOX;
                    if (!this.minimizeBox) this.mStyle = this.mStyle ^ WS_MINIMIZEBOX;
                break;
                case FormStyle.fixedDialog :
                    this.mExStyle = fixedDialogExStyle;
                    this.mStyle = fixedDialogStyle;
                    if (!this.maximizeBox) this.mStyle = this.mStyle ^ WS_MAXIMIZEBOX;
                    if (!this.minimizeBox) this.mStyle = this.mStyle ^ WS_MINIMIZEBOX;
                break;
                case FormStyle.fixedSingle :
                    this.mExStyle = fixedSingleExStyle;
                    this.mStyle = fixedSingleStyle;
                    if (!this.maximizeBox) this.mStyle = this.mStyle ^ WS_MAXIMIZEBOX;
                    if (!this.minimizeBox) this.mStyle = this.mStyle ^ WS_MINIMIZEBOX;
                break;
                case FormStyle.normalWin :
                    this.mExStyle = normalWinExStyle;
                    this.mStyle = normalWinStyle;
                    if (!this.maximizeBox) this.mStyle = this.mStyle ^ WS_MAXIMIZEBOX;
                    if (!this.minimizeBox) this.mStyle = this.mStyle ^ WS_MINIMIZEBOX;
                break;
                case FormStyle.fixedTool :
                    this.mExStyle = fixedToolExStyle;
                    this.mStyle = fixedToolStyle;
                break;
                case FormStyle.sizableTool :
                    this.mExStyle = sizableToolExStyle;
                    this.mStyle = sizableToolStyle;
                break;
                case FormStyle.hidden:
                    this.mExStyle = WS_EX_TOOLWINDOW;
                    this.mStyle = WS_BORDER;
                break;
                default : break;
            }

            if (this.mTopMost) this.mExStyle = this.mExStyle | WS_EX_TOPMOST;
            if (this.mWinState == FormState.maximized) this.mStyle = this.mStyle | WS_MAXIMIZE;
            //if (!this.mVisible) this.mStyle &= ~(WS_VISIBLE); // flags -= flags & MY_FLAG

            //this.log(fixed3DExStyle, "fixed3DExStyle"); // Delete anytime.
            //this.log(fixed3DStyle, "fixed3DStyle");
            //this.log(fixedDialogExStyle, "fixedDialogExStyle");
            //this.log(fixedDialogStyle, "fixedDialogStyle");
            //this.log(fixedSingleExStyle, "fixedSingleExStyle");
            //this.log(fixedSingleStyle, "fixedSingleStyle");
            //this.log(normalWinExStyle, "normalWinExStyle");
            //this.log(normalWinStyle, "normalWinStyle");
            //this.log(fixedToolExStyle, "fixedToolExStyle");
            //this.log(fixedToolStyle, "fixedToolStyle");
            //this.log(sizableToolExStyle, "sizableToolExStyle");
            //this.log(sizableToolStyle, "sizableToolStyle");

        }

    	void propBackColorSetter(uint clr)
        {   // private
    		this.mBackColor(clr);
    		this.mBkDrawMode = FormBkMode.singleColor;
    		if (this.mIsCreated) InvalidateRect(this.mHandle, null, false);
    	}

        void checkWinVwesion()
        {
            import  std.stdio;
            OSVERSIONINFOW ovi;
            ovi.dwOSVersionInfoSize = OSVERSIONINFOW.sizeof;
            GetVersionExW(&ovi);
            writefln("OS Version : %s.%s.%s.%s", ovi.dwMajorVersion,
                ovi.dwMinorVersion, ovi.dwPlatformId, ovi.dwBuildNumber);
        }

        void setDataAtMoveMsg(int x, int y)
        {
            this.mXpos = x;
            this.mYpos = y;
        }

        void setDataAtSizeMsg(RECT rct)
        {
            this.mWidth = rct.right - rct.left;
            this.mHeight = rct.bottom - rct.top;
        }

        void createControlHandles()
        {
            if (this.mMenubarCreated && !this.mMenubar.mIsCreated) {
                this.mMenubar.createHandle();
            }
            if (this.mControls.length) {
                foreach (ctl; this.mControls) {
                    if (!ctl.mIsCreated) ctl.createHandle();
                }
            }
        }

        void finalize()
        {
            appData.frmCount -= 1;
            if (this.tbBrush) DeleteObject(this.tbBrush);
            if (this.menuHwnd) DestroyMenu(this.menuHwnd);
            if (this.mHkeyMap.length > 0) {
                foreach (int key; mHkeyMap.keys) {
                    UnregisterHotKey(this.mHandle, key);
                    print("hot key id un registered", key);
                }
                this.mHkeyMap.clear;
            }
            this.callDtor = false;
            // writeln("Form finalize worked");
        }

}
//==========================END of Form CLASS=====================

void printFormPoints(Object sender, MouseEventArgs e)
{
    import std.stdio;
    static int x = 1;
    writefln("[%s] X : %s, Y : %s", x, e.xPos, e.yPos);
    ++x;
    stdout.flush();
}

struct HotKeyStruct
{
    bool altKey;
    bool ctrlKey;
    bool shiftKey;
    bool winKey;
    bool repeat;
    bool result;
    int hotKeyID;
    Key hotKey;

}

// Some good back colors - 0xE8E9EB, 0xF5F5F5, 0xF2F3F5



 //int x = 1;
/// WndProc function for Form class
extern(Windows)
LRESULT mainWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) nothrow
{
    try {
        // print("Main wndproc message", message);
        auto self = fromHwndTo!Form(hWnd);
        if (self is null) {
            if (message == WM_NCCREATE) {
                CREATESTRUCT* cs = cast(CREATESTRUCT*)lParam;
                self = cast(Form) cs.lpCreateParams;
                self.mHandle = hWnd;			
                SetWindowLongPtr(hWnd, GWLP_USERDATA,  cast(LONG_PTR) cast(void*)self);                
                return 1; // Continue window creation
            }
            return DefWindowProc(hWnd, message, wParam, lParam);
        }

        auto res = self.commonMsgHandler(hWnd, message, wParam, lParam);
        if (res == MsgHandlerResult.callDefProc) {
            return DefWindowProcW(hWnd, message, wParam, lParam);
        } else if (res == MsgHandlerResult.returnZero || res == MsgHandlerResult.returnOne) {
            return cast(LRESULT) res;
        }

        switch (message) {            
            case WM_DESTROY:                 
                if (self.onClosed) self.onClosed(self, new EventArgs());              
            break;
            case WM_NCDESTROY:
                self.finalize(); // Do the housekeeping for this window.
                if (hWnd == appData.mainHwnd) PostQuitMessage(0); 
            break;
            case WM_CLOSE:
                auto ea = new EventArgs();                
                if (self.onClosing) self.onClosing(self, ea);
                if (ea.cancel) return 0; // User don't want to close the window
            break; 
            case CM_WIN_THREAD_MSG: // Users can send this msg from different threads.
                if (self.onThreadMsg) self.onThreadMsg(wParam, lParam); 
            break;
            case WM_TIMER:
                Timer timer = self.mTimerMap.get(cast(UINT_PTR)wParam, null);
                if (timer && timer.onTick) timer.onTick(self, GEA);
                return 0;
            break;
            case WM_SHOWWINDOW:
                if (!self.mIsLoaded) {
                    self.mIsLoaded = true;
                    if (self.onLoad) self.onLoad(self, new EventArgs());
                }
                return 0;
            break;
            case WM_ACTIVATEAPP:
                if (self.onActivate || self.onDeActivate) {
                    auto ea = new EventArgs();
                    immutable bool flag = cast(bool) wParam;
                    if (!flag) {
                        if (self.onDeActivate) self.onDeActivate(self, ea);
                        return 0;
                    } else {
                        if (self.onActivate) self.onActivate(self, ea);
                    }
                }
            break;
            case WM_NOTIFY:
                auto nm = cast(NMHDR*) lParam;
                // writefln("WM_NOTIFY nmhdr.hwndFrom: %d, nmhdr.idFrom: %d, nmhdr.code: %d", nm.hwndFrom, nm.idFrom, nm.code);
                return SendMessageW(nm.hwndFrom, CM_NOTIFY, wParam, lParam);
            break;
            case WM_CTLCOLOREDIT:
                auto ctlHwnd = cast(HWND) lParam;
                return SendMessageW(ctlHwnd, CM_COLOR_EDIT, wParam, lParam);
            break;
            case WM_CTLCOLORSTATIC:
                auto ctlHwnd = cast(HWND) lParam;
                return SendMessageW(ctlHwnd, CM_COLOR_STATIC, wParam, lParam);
            break;
            case WM_CTLCOLORLISTBOX:
                auto ctlHwnd = cast(HWND) lParam;
                /*----------------------------------------------------------------------------------
                If user uses a ComboBox, it contains a ListBox in it.
                So, 'ctlHwnd' might be a handle of that ListBox. Or it might be a normal ListBox too.
                So, we need to check it before dispatch this message to that listbox.
                Because, if it is from Combo's listbox, there is no Wndproc function for that ListBox.
                -------------------------------------------------------------------------------------*/
                auto cmb = self.cmb_dict.get(ctlHwnd, null);
                if (cmb) {
                    return SendMessageW(cmb, CM_COLOR_CMB_LIST, wParam, lParam);
                } else {
                    return SendMessageW(ctlHwnd, CM_COLOR_EDIT, wParam, lParam);
                }
            break;
            case WM_COMMAND:
				// writefln("WM_COMMAND 1 - wpm hiw %d", HIWORD(wParam));
                switch (lParam){
                    case 0: // It's from menu
                        if (HIWORD(wParam) == 0) {
                            auto mid = cast(uint)(LOWORD(wParam));
                            auto menu = self.mMenuItemDict.get(mid, null);
                            if (menu && menu.onClick) menu.onClick(menu, new EventArgs());
                            return 0;
                        } else { // It's from accelerator key
                            break;
                        }
                    break;
                    default: // It's from a control
                        auto ctlHwnd = cast(HWND) lParam;
                        return SendMessageW(ctlHwnd, CM_CTLCOMMAND, wParam, lParam);
                    break;
                }
            break;
            case WM_SYSKEYUP:
                if (self.onKeyUp) 
                    self.onKeyUp(self, new KeyEventArgs(wParam));
            break;
            case WM_SYSKEYDOWN:
                print("form keydown");
                if (self.onKeyDown) 
                    self.onKeyDown(self, new KeyEventArgs(wParam));
            break;
            case WM_CHAR:
                if (self.onKeyPress)                
                    self.onKeyPress(self, new KeyPressEventArgs(wParam));                
            break;
            case WM_HSCROLL: return SendMessageW(cast(HWND) lParam, CM_HSCROLL, wParam, lParam);
            case WM_VSCROLL: return SendMessageW(cast(HWND) lParam, CM_VSCROLL, wParam, lParam);

            case WM_SIZING:
                self.mSizingStarted = true;
                auto sea = new SizeEventArgs(message, wParam, lParam);
                // self.width = sea.windowRect.right - sea.windowRect.left;
                // self.height = sea.windowRect.bottom - sea.windowRect.top;
                self.setDataAtSizeMsg(sea.windowRect);
                if (self.onSizing) {
                    self.onSizing(self, sea);
                    return 1;
                }
                return 0;
            break;
            case WM_SIZE:
                self.mSizingStarted = false;
                if (self.onSized) {
                    auto sea = new SizeEventArgs(message, wParam, lParam);
                    self.onSized(self, sea);
                    return 1;
                }
            break;
            case WM_MOVE:
                self.setDataAtMoveMsg(xFromLparam(lParam), yFromLparam(lParam));
                if (self.onMoved) self.onMoved(self, new EventArgs());
                return 0;
            break;
            case WM_MOVING:
                auto rct = cast(RECT*) lParam;
                self.setDataAtMoveMsg(rct.left, rct.top);
                if (self.onMoving) {
                    auto ea = new EventArgs();
                    self.onMoving(self, ea);
                    return 1;
                }
                return 0;
            break;
            case WM_SYSCOMMAND:
                auto uMsg = cast(UINT) (wParam & 0xFFF0);
                switch (uMsg) {
                    case SC_MINIMIZE:
                        if (self.onMinimized) self.onMinimized(self, new EventArgs());
                    break;

                    case SC_MAXIMIZE:
                        if (self.onMaximized) self.onMaximized(self, new EventArgs());
                    break;

                    case SC_RESTORE:
                        if (self.onRestored) self.onRestored(self, new EventArgs());
                    break;
                    default: break;
                }
            break;
            case WM_ERASEBKGND:
                if (self.mBkDrawMode != FormBkMode.normal) {
                    auto dch = cast(HDC) wParam;
                    self.setBkClrInternal(dch);
                    return cast(LRESULT)1; // We must return non zero value if handle this message.
                }
                // Do not return zero here. It will cause static controls's back ground looks ugly.
            break;
            case WM_HOTKEY:
                int hkid = cast(int)wParam;
                EventHandler pFunc = self.mHkeyMap.get(hkid, null);
                if (pFunc) pFunc(self, GEA);
                return 0;
            break;   
            case WM_MEASUREITEM:
                auto pmi = cast(LPMEASUREITEMSTRUCT)lParam;
                auto mi = getMenuItem(pmi.itemData);
                if (mi.mType == MenuType.baseMenu) {
                    auto hdc = GetDC(hWnd);
                    scope(exit) ReleaseDC(hWnd, hdc);
                    SIZE size;
                    GetTextExtentPoint32W(hdc, cast(wchar*) mi.mWideText, cast(int)mi.mText.length, &size);
                    pmi.itemWidth = size.cx + 3;
                    pmi.itemHeight = size.cy;
                } else {
                    pmi.itemWidth = 100;
                    pmi.itemHeight = 25;
                }
                return 1;
            break;
            case WM_DRAWITEM:
                auto dis = cast(LPDRAWITEMSTRUCT) lParam;
                auto mi = getMenuItem(dis.itemData);
                COLORREF txtClrRef = mi.mFgColor.cref;
                // print("dis item state ", dis.itemState);

                // If item state is ods_selected or ods_hotlight, we will highlight.
                if (dis.itemState & 0x0001 || dis.itemState & 0x0040) {
                    if (mi.mEnabled) {
                        immutable RECT rc = RECT(   dis.rcItem.left + 5,
                                                    dis.rcItem.top + 1,
                                                    dis.rcItem.right,
                                                    dis.rcItem.bottom);
                        FillRect(dis.hDC, &rc, self.mMenubar.mMenuHotBgBrush);
                        FrameRect(dis.hDC, &rc, self.mMenubar.mMenuFrameBrush);
                        txtClrRef = 0x00000000;
                    } else {
                        FillRect(dis.hDC, &dis.rcItem, self.mMenubar.mMenuGrayBrush);
                        txtClrRef = self.mMenubar.mMenuGrayCref;
                    }
                
                // Else we will draw normal menu text. No highlighting.
                } else {
                    FillRect(dis.hDC, &dis.rcItem, self.mMenubar.mMenuDefBgBrush);
                    if (!mi.mEnabled) txtClrRef = self.mMenubar.mMenuGrayCref;
                }

                SetBkMode(dis.hDC, 1);
                if (mi.mType == MenuType.baseMenu) {
                    dis.rcItem.left += 10;
                } else {
                    dis.rcItem.left += 25;
                }
                SelectObject(dis.hDC, self.mMenubar.mFont.mHandle);
                SetTextColor(dis.hDC, txtClrRef);
                DrawTextW(dis.hDC, mi.mWideText, -1, &dis.rcItem, DT_LEFT | DT_SINGLELINE | DT_VCENTER);
                return 0;
            break;
            case CM_MENU_ADDED:
                // De-reference the pointer and put the menu item in our dict
                self.mMenuItemDict[cast(uint)wParam] = *(cast(MenuItem*) (cast(void*)lParam));
                // writeln("Added menu name: ", self.mMenuItemDict[cast(uint)wParam].mText);
                return 0;
            break;
            case WM_MENUSELECT:
                auto pmenu = self.getMenuFromHmenu(cast(HMENU) lParam);
                immutable int mid = cast(int) LOWORD(wParam); // Could be an id of a child menu or index of a child menu
                immutable WORD hwwpm = HIWORD(wParam);
                if (pmenu) {
                    MenuItem menu;
                    switch (hwwpm) {
                        case 33_152: // A normal child menu. We can use mid ad menu id.
                            menu = self.mMenuItemDict[mid]; break;
                        case 33_168: // A popup child menu. We can use mid as index.
                            menu = pmenu.getChildFromIndex(mid); break;
                        default: break;
                    }
                    if (menu && menu.onFocus) menu.onFocus(menu, new EventArgs());
                }
            break;
            case WM_INITMENUPOPUP:
                auto menu = self.getMenuFromHmenu(cast(HMENU) wParam);
                if (menu && menu.onPopup) menu.onPopup(menu, new EventArgs());
            break;
            case WM_UNINITMENUPOPUP:
                auto menu = self.getMenuFromHmenu(cast(HMENU) wParam);
                if (menu && menu.onCloseup) menu.onCloseup(menu, new EventArgs());
            break;
            case CM_FONT_CHANGED:
                self.updateFontHandle();
                return 0;
            break;
            default: 
                return DefWindowProcW(hWnd, message, wParam, lParam); 
            break;
        }
    }
    catch (Exception e){}
    return DefWindowProcW(hWnd, message, wParam, lParam);
}

