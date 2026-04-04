module wings.trayicon; // Created on 30-July-2022 06:45 PM
/*==============================================TrayIcon Docs=====================================
    Constructor:
        this(string tooltip, string iconpath = "")

	Properties:	
        contextMenu     : ContextMenu
        menuTrigger     : TrayMenuTrigger
        tooltip         : string
        iconPath        : string
			
    Methods:
        addContextMenu
        showBalloon
        
    Events:
        TrayIconEventHandler - void delegate(TrayIcon, EventArgs)
            onBalloonShow
            onBalloonClose
            onBalloonClick    
            onMouseMove    
            onLeftMouseDown
            onLeftMouseUp    
            onRightMouseDown
            onRightMouseUp
            onLeftClick
            onRightClick
            onLeftDoubleClick       
=============================================================================================*/

import core.sys.windows.windows;
import std.utf;
import std.stdio;


import wings.enums: TrayMenuTrigger, BalloonIcon;
import wings.commons: print, CM_TRAY_MSG, fromHwndTo;
import wings.application: appData;
import wings.events;


enum wstring trayWndClass = "Wings_Tray_Msg_Window";
enum string exMsg = "More than one tray icon is not allowed";
enum uint 
    LIMG_FLAG            =   LR_DEFAULTCOLOR | LR_LOADFROMFILE,
    NIN_SELECT           =   (WM_USER + 0),
	NINF_KEY             =   0x1,
	NIN_KEYSELECT        =   (NIN_SELECT | NINF_KEY),
	NIN_BALLOONSHOW      =   (WM_USER + 2),
	NIN_BALLOONHIDE      =   (WM_USER + 3),
	NIN_BALLOONTIMEOUT   =   (WM_USER + 4),
	NIN_BALLOONUSERCLICK =   (WM_USER + 5),
	NIN_POPUPOPEN        =   (WM_USER + 6),
	NIN_POPUPCLOSE       =   (WM_USER + 7);
//------------------------------------------------------------------------


class TrayIcon 
{
    import wings.events: EventHandler;
    import wings.contextmenu: ContextMenu;        
    
    this(string tooltip, string iconpath = "")
    {
        // if (appData.trayHwnd) throw new Exception(exMsg);
        this.mTooltip = tooltip;
        this.mIcopath = iconpath;
        this.createMsgOnlyWindow();
        if (iconpath == "") {
            this.mTrayHicon = LoadIconW(null, IDI_WINLOGO);
        } else {
            this.mTrayHicon = LoadImageW(null, iconpath.toUTF16z, IMAGE_ICON, 0, 0, LIMG_FLAG);
            if (!this.mTrayHicon) {
                this.mTrayHicon = LoadIconW(null, IDI_WINLOGO);
                print("Can't create icon. Error -", GetLastError());
            } else {
                this.mDestroyIcon = true; // We can destroy the icon when we close.
            }

        }
        auto tlen = this.mTooltip.length;
        this.mNid.hWnd = this.mMsgHwnd;
        this.mNid.uID = 1;
        this.mNid.uVersion = 0;
        this.mNid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
        this.mNid.uCallbackMessage = CM_TRAY_MSG;
        this.mNid.hIcon = this.mTrayHicon;  
        this.mNid.szTip[0..tlen] = this.mTooltip.toUTF16;
        Shell_NotifyIconW(NIM_ADD, &this.mNid);
    }

    ~this()
    {        
        DestroyWindow(this.mMsgHwnd);
        Shell_NotifyIconW(NIM_DELETE, &this.mNid);
        if (this.mDestroyIcon) DestroyIcon(this.mTrayHicon);
        if (this.mCmenuUsed) this.mCmenu.destroy(); 
        print("TrayIcon dtor worked");  
    }
    
    /// Add a context menu to tray icon with menu items. 
    void addContextMenu(bool cdraw, TrayMenuTrigger trigger, string[] menuNames ...)
    {
        this.mCmenu = new ContextMenu(this, cdraw, menuNames);
        this.mCmenuUsed = true;
        this.mMenuTrigger = trigger;
    }

    /// Add a context menu to tray icon. 
    void addContextMenu()
    {
        this.mCmenu = new ContextMenu(this);
        this.mCmenuUsed = true;
        this.mMenuTrigger = TrayMenuTrigger.rightClick;
    }

    /// Show balloon text in tray area.
    void showBalloon(string title, string message, 
                        uint timeout, 
                        bool noSound = false, 
                        BalloonIcon icon = BalloonIcon.info, 
                        string icoPath = "" )
    {
        auto ttLen = title.length;
        auto msgLen = message.length; 
		this.mNid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP | NIF_INFO;
		this.mNid.szInfoTitle[0..ttLen] = title.toUTF16;
		this.mNid.szInfo[0..msgLen] = message.toUTF16;
        if (icon == BalloonIcon.custom && icoPath != "") {
            this.mNid.hIcon  = LoadImageW(null, icoPath.toUTF16z, IMAGE_ICON, 0, 0, LIMG_FLAG);

            // If any error happened, we will use our base icon.
            if (!this.mNid.hIcon) {
                this.mNid.hIcon = this.mTrayHicon;
            } else { 
                /*-------------------------------------------------------------------
                So, we successfully created an icon handle from 'iconpath' parameter.
                So, for this balloon, we will show this icon. But We need to... 
                ...reset the old icon after this balloon vanished. 
                Otherwise, from now on we need to use this icon in Balloons and tray. 
                ----------------------------------------------------------------------*/
                this.mResetIcon = true;        
            }
        }
		this.mNid.dwInfoFlags = cast(DWORD)icon; 		
		this.mNid.uTimeout = timeout;        
        if (noSound) this.mNid.dwInfoFlags |= NIIF_NOSOUND;
		Shell_NotifyIconW(NIM_MODIFY, &this.mNid);
        this.mNid.dwInfoFlags = 0;
        this.mNid.uFlags = 0;
    }

    /// Get the context menu of this tray icon.
    final ContextMenu contextMenu() {return this.mCmenu;}

    /// Get the menu trigger of this tray icon.
    TrayMenuTrigger menuTrigger() {return this.mMenuTrigger;}

    /// Set the menu trigger of this tray icon.
    void menuTrigger(TrayMenuTrigger value) {this.mMenuTrigger = value;}

    /// Get the tooltip
    string tooltip() {return this.mTooltip;}

    /// Set the tooltip
    void tooltip(string value) 
    {
        this.mTooltip = value;
        this.mNid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
        auto tlen = this.mTooltip.length;
        this.mNid.szTip[0..tlen] = this.mTooltip.toUTF16;
        Shell_NotifyIconW(NIM_MODIFY, &this.mNid);
    }

    /// Get the icon path
    final string iconPath() {return this.mIcopath;}

    /// Set the user defined icon
    final void iconPath(string icopath)
    {
        this.mTrayHicon = LoadImageW(null, icopath.toUTF16z, IMAGE_ICON, 0, 0, LIMG_FLAG);
        if (!this.mTrayHicon) {
            this.mTrayHicon = LoadIconW(null, IDI_WINLOGO);
            print("Can't create icon with", icopath);   
        }
        this.mNid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP; // This is for safety,'cause flags might be zero.  
        this.mNid.hIcon = this.mTrayHicon;       
        Shell_NotifyIconW(NIM_MODIFY, &this.mNid);
    }

    

    
    EventHandler onBalloonShow;
    EventHandler onBalloonClose;
    EventHandler onBalloonClick;    
    EventHandler onMouseMove;    
    EventHandler onLeftMouseDown;
    EventHandler onLeftMouseUp;    
    EventHandler onRightMouseDown;
    EventHandler onRightMouseUp;
    EventHandler onLeftClick;
    EventHandler onRightClick;
    EventHandler onLeftDoubleClick;

    /// Users can store a void pointer in this field.
    void* userData;

    package:
    bool mCmenuUsed;
    TrayMenuTrigger mMenuTrigger;
    ContextMenu mCmenu;
    HWND mMsgHwnd;
    
    private:
    bool mResetIcon;
    bool mRetainIcon;
    bool mDestroyIcon;
    static bool stIsRegistered;
    string mTooltip;
    string mIcopath;    
    HICON mTrayHicon;    
    NOTIFYICONDATAW mNid;

    void createMsgOnlyWindow()
    {
        if (!stIsRegistered) {
            appData.registerMsgOnlyWindow(trayWndClass.ptr, &trayWndProc);
            stIsRegistered = true;
        }
        this.mMsgHwnd = CreateWindowExW(0, trayWndClass.ptr, null, 
                                        0, 0, 0, 0, 0, HWND_MESSAGE, 
                                        null, appData.hInstance, cast(PVOID)this);
        if (this.mMsgHwnd) {
            // SetWindowLongPtrW(this.mMsgHwnd, GWLP_USERDATA, (cast(LONG_PTR) cast(void*) this));
            appData.trayHwnds ~= this.mMsgHwnd;
            // print("tray icon message-only window created");
        } else {
            print("Can't create messge-only window for tray icon. Error -", GetLastError());
        }
    }

    void resetIconInternal()
    {
        this.mNid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
        this.mNid.hIcon = this.mTrayHicon;
        Shell_NotifyIconW(NIM_MODIFY, &this.mNid);
        this.mResetIcon = false; // Revert to default state.
    }

    
}

int xFromWparam(WPARAM wpm){ return cast(int) (cast(short) LOWORD(wpm));}
int yFromWparam(WPARAM wpm){ return cast(int) (cast(short) HIWORD(wpm));}
extern(Windows)
private LRESULT trayWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) nothrow
{
    try {
        // print("TrayIcon Wndproc rcvd", message);
        auto self = fromHwndTo!TrayIcon(hWnd);
        if (self is null) {
            if (message == WM_NCCREATE) {
                CREATESTRUCT* cs = cast(CREATESTRUCT*)lParam;
                self = cast(TrayIcon) cs.lpCreateParams;
                self.mMsgHwnd = hWnd;			
                SetWindowLongPtr(hWnd, GWLP_USERDATA,  cast(LONG_PTR) cast(void*)self);                
                return 1; // Continue window creation
            }
            return DefWindowProc(hWnd, message, wParam, lParam);
        }
        switch (message) {
            case WM_DESTROY:                  
                appData.removeTrayHwnd(self.mMsgHwnd);
                // print("Tray icon Message only window got WM_DESTROY");
                // return 0;
            break;
            case CM_TRAY_MSG:	
                switch(lParam) {
                    case NIN_BALLOONSHOW:                    
                        if (self.onBalloonShow) self.onBalloonShow(self, new EventArgs());
                    break;
                    case NIN_BALLOONTIMEOUT:                    
                        if (self.onBalloonClose) self.onBalloonClose(self, new EventArgs());
                        if (self.mResetIcon) self.resetIconInternal(); // Need to revert the default icon
                    break;
                    case NIN_BALLOONUSERCLICK:
                        if (self.onBalloonClick) self.onBalloonClick(self, new EventArgs());
                        if (self.mResetIcon) self.resetIconInternal(); // Need to revert the default icon
                    break;
                    case WM_LBUTTONDOWN:
                        if (self.onLeftMouseDown) self.onLeftMouseDown(self, new EventArgs());                    
                    break;
                    case WM_LBUTTONUP:                    
                        if (self.onLeftMouseUp) self.onLeftMouseUp(self, new EventArgs());
                        if (self.onLeftClick) self.onLeftClick(self, new EventArgs());
                        if (self.mCmenuUsed && (self.mMenuTrigger & TrayMenuTrigger.leftClick))
                            self.mCmenu.showMenu(0);
                    break;
                    case WM_LBUTTONDBLCLK:
                        if (self.onLeftDoubleClick) self.onLeftDoubleClick(self, new EventArgs());
                        if (self.mCmenuUsed && (self.mMenuTrigger & TrayMenuTrigger.leftDoubleClick)) 
                            self.mCmenu.showMenu(0);
                    break;
                    case WM_RBUTTONDOWN:
                        if (self.onRightMouseDown) self.onRightMouseDown(self, new EventArgs());
                    break;
                    case WM_RBUTTONUP:
                        if (self.onRightMouseUp) self.onRightMouseUp(self, new EventArgs());
                        if (self.onRightClick) self.onRightClick(self, new EventArgs());
                        if (self.mCmenuUsed && (self.mMenuTrigger & TrayMenuTrigger.rightClick)) 
                            self.mCmenu.showMenu(0);
                    break;
                    case WM_MOUSEMOVE:
                        if (self.onMouseMove) self.onMouseMove(self, new EventArgs());
                    break;
                    default: break;
                } 
            break;   
            default: break;
        }
    }
    catch (Exception e){}
    return DefWindowProcW(hWnd, message, wParam, lParam);
}

