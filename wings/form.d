
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
        registerHotKey
        unRegisterHotKey
        addMenuBar
        addTimer
        
    Events:
        All public events inherited from Control class. (See controls.d)
        EventHandler - void delegate(Control, EventArgs)
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
	    SizeEventHandler - void delegate(Control, SizeEventArgs)
            onSized
            onSizing
        HotKeyEventHandler - void delegate(Control, HotKeyEventArgs)
            onHotKeyPress
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
import wings.application: appData;
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
    HotKeyEventHandler onHotKeyPress;
    ThreadMsgHandler onThreadMsg;


    ///the constructor of form class
    private this(string txt, int x, int y, int w, int h)
    {
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
        this.mFont = appData.appFont;
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

    ~this() 
    {
        if (this.callDtor) {
            this.finalize();
        } else {
            writeln("Form class dtor worked");
        }
    }

    /// Creates the window
    override void createHandle()
    {
        import std.stdio;
        setStartPos();
        setWindowStyles();
        //auto sw = StopWatch(AutoStart.no);
        //sw.start();

        this.mHandle = CreateWindowExW( this.mExStyle,
                                        appData.className.ptr,
                                        this.mText.toUTF16z,
                                        this.mStyle,
                                        this.mXpos,
                                        this.mYpos,
                                        this.mWidth,
                                        this.mHeight,
                                        null,
                                        menuHwnd,
                                        appData.hInstance,
                                        null);

        if (this.mHandle ) {
            this.mIsCreated = true;
            if (appData.mainHwnd == null) appData.mainHwnd = this.mHandle;
            SetWindowLongPtrW(this.mHandle, GWLP_USERDATA, (cast(LONG_PTR) cast(void*) this) );
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

    final void registerHotKey(HotKeyStruct* hks)
    {
        if (this.mIsCreated) {
            uint fsMod;
            if (hks.altKey) fsMod |= 0x0001;
            if (hks.ctrlKey) fsMod |= 0x0002;
            if (hks.shiftKey) fsMod |= 0x0004;
            if (hks.winKey) fsMod |= 0x0008;
            if (!hks.repeat) fsMod |= 0x4000;
            if (!hks.altKey && !hks.ctrlKey && !hks.shiftKey && !hks.winKey ) return;
            uint vKey = cast(uint) hks.hotKey;
            ++mGlobalHotKeyID; // A static variable of Form class.
            if (RegisterHotKey(this.mHandle, mGlobalHotKeyID, fsMod, vKey)) {
                this.mHotKeyIDList ~= mGlobalHotKeyID;
                hks.hotKeyID = mGlobalHotKeyID;
                hks.result = true;
            }
        }
    }

    final bool unRegisterHotKey(int hkeyID)
    {
        auto res = UnregisterHotKey(this.mHandle, hkeyID);
        if (res != 0) remove!(a => a == hkeyID)(this.mHotKeyIDList);
        return cast(bool) res;
    }

    final MenuBar addMenuBar(string[] menuNames...)
    {
        auto mbar = new MenuBar(this);
        if (menuNames.length > 0) mbar.addItems(menuNames);
        this.mMenubarCreated = true;
        return mbar;
    }

    final Timer addTimer(UINT interval = 100, EventHandler tickHandler = null)
    {
        auto timer = new Timer(this.mHandle, interval, tickHandler);
        this.mTimerDic[timer.mIdNum] = timer;
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
        int[] mHotKeyIDList;
        bool callDtor;
        bool isLoaded;
        bool mTopMost;
        bool mMaxBox;
        bool mMinBox;
        bool mGDR2L; // Gradient draw right to left
        Timer[UINT_PTR] mTimerDic;
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
            if (this.mMenubarCreated && !this.mMenubar.mIsCreated) 
                this.mMenubar.createHandle();
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
            if (this.mHotKeyIDList.length > 0) {
                foreach (int key; mHotKeyIDList) {
                    UnregisterHotKey(this.mHandle, key);
                    print("hot key id un registered", key);
                }
                this.mHotKeyIDList.length = 0;
            }
            this.callDtor = false;
            writeln("Form finalize worked");
        }

}
//==========================END of Form CLASS=====================

void printFormPoints(Control sender, MouseEventArgs e)
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



void trackMouseMove(HWND hw)
{
    TRACKMOUSEEVENT tme;
    tme.cbSize = tme.sizeof;
    tme.dwFlags = TME_HOVER | TME_LEAVE;
    tme.dwHoverTime = HOVER_DEFAULT;
    tme.hwndTrack = hw;
    TrackMouseEvent(&tme);
}


 //int x = 1;
/// WndProc function for Form class
extern(Windows)
LRESULT mainWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) nothrow
{
    try {
        // print("Main wndproc message", message);
        switch (message) {            
            case WM_DESTROY: 
                auto win = getAs!Form(hWnd);                
                if (win.onClosed) win.onClosed(win, new EventArgs());              
            break;
            case WM_NCDESTROY:
                auto win = getAs!Form(hWnd);
                win.finalize(); // Do the housekeeping for this window.
                if (hWnd == appData.mainHwnd) PostQuitMessage(0); 
            break;
            case WM_CLOSE:
                auto win = getAs!Form(hWnd);
                auto ea = new EventArgs();                
                if (win.onClosing) win.onClosing(win, ea);
                if (ea.cancel) return 0; // User don't want to close the window
            break; 
            case CM_WIN_THREAD_MSG: // Users can send this msg from different threads.
                auto win = getAs!Form(hWnd);
                if (win.onThreadMsg) win.onThreadMsg(wParam, lParam); 
            break;
            case WM_TIMER:
                auto win = getAs!Form(hWnd);
                Timer timer = win.mTimerDic.get(cast(UINT_PTR) wParam, null);
                if (timer && timer.onTick) {
                    timer.onTick(win, new EventArgs());
                }
            break;
            case WM_SHOWWINDOW:
                auto win = getAs!Form(hWnd);
                if (!win.mIsLoaded) {
                    win.mIsLoaded = true;
                    if (win.onLoad) win.onLoad(win, new EventArgs());
                }
                return 0;
            break;
            case WM_ACTIVATEAPP:
                auto win = getAs!Form(hWnd);
                if (win.onActivate || win.onDeActivate) {
                    auto ea = new EventArgs();
                    immutable bool flag = cast(bool) wParam;
                    if (!flag) {
                        if (win.onDeActivate) win.onDeActivate(win, ea);
                        return 0;
                    } else {
                        if (win.onActivate) win.onActivate(win, ea);
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
                auto win = getAs!Form(hWnd);
                auto ctlHwnd = cast(HWND) lParam;
                /*----------------------------------------------------------------------------------
                If user uses a ComboBox, it contains a ListBox in it.
                So, 'ctlHwnd' might be a handle of that ListBox. Or it might be a normal ListBox too.
                So, we need to check it before dispatch this message to that listbox.
                Because, if it is from Combo's listbox, there is no Wndproc function for that ListBox.
                -------------------------------------------------------------------------------------*/
                auto cmb = win.cmb_dict.get(ctlHwnd, null);
                if (cmb) {
                    return SendMessageW(cmb, CM_COLOR_CMB_LIST, wParam, lParam);
                } else {
                    return SendMessageW(ctlHwnd, CM_COLOR_EDIT, wParam, lParam);
                }
            break;
            case WM_COMMAND:
				// writefln("WM_COMMAND 1 - wpm hiw %d", HIWORD(wParam));
                auto win = getAs!Form(hWnd);
                switch (lParam){
                    case 0: // It's from menu
                        if (HIWORD(wParam) == 0) {
                            auto mid = cast(uint)(LOWORD(wParam));
                            auto menu = win.mMenuItemDict.get(mid, null);
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
            case WM_KEYUP, WM_SYSKEYUP:
                auto win = getAs!Form(hWnd);
                if (win.onKeyUp) 
                    win.onKeyUp(win, new KeyEventArgs(wParam));
            break;
            case WM_KEYDOWN, WM_SYSKEYDOWN:
                print("form keydown");
                auto win = getAs!Form(hWnd);
                if (win.onKeyDown) 
                    win.onKeyDown(win, new KeyEventArgs(wParam));
            break;
            case WM_CHAR:
                auto win = getAs!Form(hWnd);
                if (win.onKeyPress)                
                    win.onKeyPress(win, new KeyPressEventArgs(wParam));                
            break;
            case WM_LBUTTONDOWN:
                auto win = getAs!Form(hWnd);
                win.lDownHappened = true;
                if (win.onMouseDown) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    win.onMouseDown(win, ea);
                    return 0;
                }
            break;
            case WM_LBUTTONUP:
                auto win = getAs!Form(hWnd);
                if (win.onMouseUp) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    win.onMouseUp(win, ea);
                }
                if (win.onClick) win.onClick(win, new EventArgs());
            break;
            case WM_RBUTTONDOWN:
                auto win = getAs!Form(hWnd);
                win.rDownHappened = true;
                if (win.onRightMouseDown) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    win.onRightMouseDown(win, ea);
                }
            break;
            case WM_RBUTTONUP:
                auto win = getAs!Form(hWnd);
                if (win.onRightMouseUp) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    win.onRightMouseUp(win, ea);
                }
                if (win.onRightClick) win.onRightClick(win, new EventArgs());
            break;
            case WM_MOUSEWHEEL:
                auto win = getAs!Form(hWnd);
                if (win.onMouseWheel) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    win.onMouseWheel(win, ea);
                }
            break;
            case WM_MOUSEMOVE:
                auto win = getAs!Form(hWnd);
                if (!win.mIsMouseTracking) {
                    win.mIsMouseTracking = true;
                    trackMouseMove(hWnd);
                    if (!win.mIsMouseEntered) {
                        if (win.onMouseEnter) {
                            win.mIsMouseEntered = true;
                            auto ea = new EventArgs();
                            win.onMouseEnter(win, ea);
                        }
                    }
                }
                if (win.onMouseMove) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    win.onMouseMove(win, ea);
                }
            break;
            case WM_MOUSEHOVER:
                auto win = getAs!Form(hWnd);
                if (win.mIsMouseTracking) {win.mIsMouseTracking = false;}
                if (win.onMouseHover) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    win.onMouseHover(win, ea);
                }
            break;
            case WM_MOUSELEAVE:
                auto win = getAs!Form(hWnd);
                if (win.mIsMouseTracking) {
                    win.mIsMouseTracking = false;
                    win.mIsMouseEntered = false;
                }
                if (win.onMouseLeave) win.onMouseLeave(win, new EventArgs());
                
            break;
            case WM_HSCROLL: return SendMessageW(cast(HWND) lParam, CM_HSCROLL, wParam, lParam);
            case WM_VSCROLL: return SendMessageW(cast(HWND) lParam, CM_VSCROLL, wParam, lParam);

            case WM_SIZING:
                auto win = getAs!Form(hWnd);
                win.mSizingStarted = true;
                auto sea = new SizeEventArgs(message, wParam, lParam);
                // win.width = sea.windowRect.right - sea.windowRect.left;
                // win.height = sea.windowRect.bottom - sea.windowRect.top;
                win.setDataAtSizeMsg(sea.windowRect);
                if (win.onSizing) {
                    win.onSizing(win, sea);
                    return 1;
                }
                return 0;
            break;
            case WM_SIZE:
                auto win = getAs!Form(hWnd);
                win.mSizingStarted = false;
                if (win.onSized) {
                    auto sea = new SizeEventArgs(message, wParam, lParam);
                    win.onSized(win, sea);
                    return 1;
                }
            break;
            case WM_MOVE:
                auto win = getAs!Form(hWnd);
                win.setDataAtMoveMsg(xFromLparam(lParam), yFromLparam(lParam));
                if (win.onMoved) win.onMoved(win, new EventArgs());
                return 0;
            break;
            case WM_MOVING:
                auto win = getAs!Form(hWnd);
                auto rct = cast(RECT*) lParam;
                win.setDataAtMoveMsg(rct.left, rct.top);
                if (win.onMoving) {
                    auto ea = new EventArgs();
                    win.onMoving(win, ea);
                    return 1;
                }
                return 0;
            break;
            case WM_SYSCOMMAND:
                auto win = getAs!Form(hWnd);
                auto uMsg = cast(UINT) (wParam & 0xFFF0);
                switch (uMsg) {
                    case SC_MINIMIZE:
                        if (win.onMinimized) win.onMinimized(win, new EventArgs());
                    break;

                    case SC_MAXIMIZE:
                        if (win.onMaximized) win.onMaximized(win, new EventArgs());
                    break;

                    case SC_RESTORE:
                        if (win.onRestored) win.onRestored(win, new EventArgs());
                    break;
                    default: break;
                }
            break;
            case WM_ERASEBKGND:
                auto win = cast(Form) (cast(void *) GetWindowLongPtrW(hWnd, GWLP_USERDATA));
                if (win.mBkDrawMode != FormBkMode.normal) {
                    auto dch = cast(HDC) wParam;
                    win.setBkClrInternal(dch);
                    return cast(LRESULT)1; // We must return non zero value if handle this message.
                }
                // Do not return zero here. It will cause static controls's back ground looks ugly.
            break;
            case WM_HOTKEY:
                auto win = getAs!Form(hWnd);
                if (win.onHotKeyPress) {
                    auto hea = new HotKeyEventArgs(wParam, lParam);
                    win.onHotKeyPress(win, hea);
                }
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
                auto win = getAs!Form(hWnd);
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
                        FillRect(dis.hDC, &rc, win.mMenubar.mMenuHotBgBrush);
                        FrameRect(dis.hDC, &rc, win.mMenubar.mMenuFrameBrush);
                        txtClrRef = 0x00000000;
                    } else {
                        FillRect(dis.hDC, &dis.rcItem, win.mMenubar.mMenuGrayBrush);
                        txtClrRef = win.mMenubar.mMenuGrayCref;
                    }
                
                // Else we will draw normal menu text. No highlighting.
                } else {
                    FillRect(dis.hDC, &dis.rcItem, win.mMenubar.mMenuDefBgBrush);
                    if (!mi.mEnabled) txtClrRef = win.mMenubar.mMenuGrayCref;
                }

                SetBkMode(dis.hDC, 1);
                if (mi.mType == MenuType.baseMenu) {
                    dis.rcItem.left += 10;
                } else {
                    dis.rcItem.left += 25;
                }
                SelectObject(dis.hDC, win.mMenubar.mFont.mHandle);
                SetTextColor(dis.hDC, txtClrRef);
                DrawTextW(dis.hDC, mi.mWideText, -1, &dis.rcItem, DT_LEFT | DT_SINGLELINE | DT_VCENTER);
                return 0;
            break;
            case CM_MENU_ADDED:
                auto win = getAs!Form(hWnd);
                // De-reference the pointer and put the menu item in our dict
                win.mMenuItemDict[cast(uint)wParam] = *(cast(MenuItem*) (cast(void*)lParam));
                // writeln("Added menu name: ", win.mMenuItemDict[cast(uint)wParam].mText);
                return 0;
            break;
            case WM_MENUSELECT:
                auto win = getAs!Form(hWnd);
                auto pmenu = win.getMenuFromHmenu(cast(HMENU) lParam);
                immutable int mid = cast(int) LOWORD(wParam); // Could be an id of a child menu or index of a child menu
                immutable WORD hwwpm = HIWORD(wParam);
                if (pmenu) {
                    MenuItem menu;
                    switch (hwwpm) {
                        case 33_152: // A normal child menu. We can use mid ad menu id.
                            menu = win.mMenuItemDict[mid]; break;
                        case 33_168: // A popup child menu. We can use mid as index.
                            menu = pmenu.getChildFromIndex(mid); break;
                        default: break;
                    }
                    if (menu && menu.onFocus) menu.onFocus(menu, new EventArgs());
                }
            break;
            case WM_INITMENUPOPUP:
                auto win = getAs!Form(hWnd);
                auto menu = win.getMenuFromHmenu(cast(HMENU) wParam);
                if (menu && menu.onPopup) menu.onPopup(menu, new EventArgs());
            break;
            case WM_UNINITMENUPOPUP:
                auto win = getAs!Form(hWnd);
                auto menu = win.getMenuFromHmenu(cast(HMENU) wParam);
                if (menu && menu.onCloseup) menu.onCloseup(menu, new EventArgs());
            break;
            default: 
                return DefWindowProcW(hWnd, message, wParam, lParam); 
            break;
        }
    }
    catch (Exception e){}
    return DefWindowProcW(hWnd, message, wParam, lParam);
}

