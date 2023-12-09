
module wings.window;

// Tell the linker to link these libs when compiling.
pragma(lib, "user32.lib");
pragma(lib, "gdi32.lib");
pragma(lib, "comctl32.lib");
pragma(lib, "gdiplus.lib");

import std.stdio;
import wings.d_essentials;
import std.format;
import std.array;
import std.algorithm.mutation; // We have a function called 'remove'. So this must be renamed.
import std.string;

import wings.controls;
import wings.commons;
import wings.events;
import wings.fonts;
import wings.enums;
import wings.winstyle_contsants;
import wings.colors;
import wings.gradient;
import wings.menubar : MenuBar, MenuItem, getMenuItem;
import std.datetime.stopwatch;
package HWND mainHwnd; // A handle for main window

// Compile time values to use later
package enum string defWinFontName = "Tahoma";
package enum int defWinFontSize = 12;
package enum FontWeight defWinFontWeight = FontWeight.normal;

package bool isWindowInit = false;

DWORD newStyle = WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN | WS_CLIPSIBLINGS;

//Window[HWND] myDic; to be deleted

///This class is a form class
class Window : Control
{

    // properties
    mixin finalProperty!("startPos", this.mStartPos);
    mixin finalProperty!("style", this.mWinStyle);
    mixin finalProperty!("topMost", this.mTopMost);
    mixin finalProperty!("winState", this.mWinState);
    mixin finalProperty!("maximizeBox", this.mMaxBox);
    mixin finalProperty!("minimizeBox", this.mMinBox);

    //final override uint backColor() const {return this.mBackColor;}
    final override void backColor(uint clr) {propBackColorSetter(clr);}
    final HINSTANCE hInstace() {return appData.hInstance;}


    EventHandler onMinimized, onMaximized, onRestored, onClosing, onClosed, onLoad;
    EventHandler onActivate, onDeActivate, onMoving, onMoved;
    SizeEventHandler onSized, onSizing;
    HotKeyEventHandler onHotKeyPress;
    ThreadMsgHandler onThreadMsg;



    ///the constructor of form class
    private this(string txt, int x, int y, int w, int h)
    {
        if (!isWindowInit)  // It's the first window.
        {
            isWindowInit = true;
            appData = new ApplicationData( defWinFontName, defWinFontSize, defWinFontWeight);
            regWindowClass(appData.className, appData.hInstance);
            // this.checkWinVwesion();
        }

        this.mText = txt;
        this.mWidth = w;
        this.mHeight = h;
        this.mXpos = x;
        this.mYpos = y;
        this.mStartPos = WindowPos.center;
        this.maximizeBox = true;
        this.minimizeBox = true;
        this.mWinStyle = WindowStyle.normalWin;
        this.mBkDrawMode = WindowBkMode.normal;
        //this.mWinState = WindowState.normal;
        this.mFont = appData.mainFont;
        this.controlType = ControlType.window;
        this.mBackColor = appData.appColor; // using opCall feature

        mWinCount += 1; // Incrementing private static variable
    }

    this () {
        string title = format("%s_%d", "Form", mWinCount + 1);
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

        //sw.stop();
        //print("window create speed in milli sec : ", sw.peek.total!"msecs");
        if (this.mHandle )
        {

            //myDic[this.mHandle] = this;   To be deleted

            this.mIsCreated = true;
            if (appData.mainWinHandle == null) appData.mainWinHandle = this.mHandle;
            SetWindowLongPtrW(this.mHandle, GWLP_USERDATA, (cast(LONG_PTR) cast(void*) this) );
            this.setFontInternal();
            // if (!this.mVisible) {
            //         SetWindowPos(   this.mHandle, null,
            //                         this.mXpos, this.mYpos,
            //                         this.mWidth, this.mHeight,
            //                         SWP_HIDEWINDOW | SWP_NOACTIVATE
            //                     );
            //     }

        }
        else {
            throw new Exception("Window is not created..."); // Do we need this ?
        }
    }

    /// This will show the form on the screen
    final void show(DWORD swParam = SW_SHOW)
    {
        this.createControlHandles();
        ShowWindow(this.mHandle, swParam);
        UpdateWindow(this.mHandle);

        if (this.mWinState == WindowState.minimized) {CloseWindow(this.mHandle); }
        if(!mMainLoopStarted)
        {
            mMainLoopStarted = true;
            mainLoop();
        }
    }

    /// This will set the gradient background color for this window.
    final void setGradientColors(uint c1, uint c2, bool r2l = false)
    {
        this.mBkDrawMode = WindowBkMode.gradient;
        this.mGdraw.c1 = Color(c1);
        this.mGdraw.c2 = Color(c2);
        this.mGDR2L = r2l;
        this.checkRedrawNeeded();
    }

    /// closes the window
    final void close() { DestroyWindow(this.mHandle);}

    /// An handy feature for design time.
    final void enablePrintPoint()
    {
        this.onMouseUp = &printFormPoints;
    }

    // final void printPoint(MouseEventArgs e)
    // {
    //     import std.stdio;
    //     static int x = 1;
    //     writefln("[%s] X : %s, Y : %s", x, e.xPos, e.yPos);
    //     ++x;
    // }

    final void registerHotKey(HotKeyStruct* hks)
    {
        if (this.mIsCreated)
        {
            uint fsMod;
            if (hks.altKey) fsMod |= 0x0001;
            if (hks.ctrlKey) fsMod |= 0x0002;
            if (hks.shiftKey) fsMod |= 0x0004;
            if (hks.winKey) fsMod |= 0x0008;
            if (!hks.repeat) fsMod |= 0x4000;
            if (!hks.altKey && !hks.ctrlKey && !hks.shiftKey && !hks.winKey ) return;
            uint vKey = cast(uint) hks.hotKey;
            ++mGlobalHotKeyID; // A static variable of Window class.
            if (RegisterHotKey(this.mHandle, mGlobalHotKeyID, fsMod, vKey))
            {
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
        if (menuNames.length > 0) mbar.addItems(true, menuNames);
        this.mMenubarCreated = true;
        return mbar;
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
        WindowBkMode mBkDrawMode;
        HWND[HWND] cmb_dict;
        // COLORREF mMenuGrayCref;
        // HBRUSH mMenuGrayBrush;
        // HBRUSH mMenuDefBgBrush;
        // HBRUSH mMenuHotBgBrush;
        // HBRUSH mMenuFrameBrush;
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

            if (this.mBkDrawMode == WindowBkMode.singleColor ) {
                hBr = CreateSolidBrush(this.mBackColor.cref);
            }
            else if (this.mBkDrawMode == WindowBkMode.gradient) {
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
        static int mWinCount;
        static bool mMainLoopStarted;
        static int screenWidth;
        static int screenHeight;
        static int mGlobalHotKeyID = 100;
        int iNumber;
        int[] mHotKeyIDList;
        bool isLoaded;
        bool mTopMost;
        bool mMaxBox;
        bool mMinBox;
        bool mGDR2L; // Gradient draw right to left

        HMENU menuHwnd;
        DWORD winStyle = WS_OVERLAPPEDWINDOW;
        WindowPos mStartPos;
        WindowStyle mWinStyle;
        WindowState mWinState;
        GradColor mGdraw;
        MenuItem[] mMenuItems; // dictionary(key = uint, value = MenuItem)


        void setStartPos() { // Private
            switch (this.mStartPos) {
                case WindowPos.center :
                    this.mXpos = (appData.screenWidth - this.mWidth) / 2;
                    this.mYpos = (appData.screenHeight - this.mHeight) / 2;
                    break;

                case WindowPos.topLeft  : break;
                case WindowPos.manual   : break;

                case WindowPos.topMid   :
                    this.mXpos = (appData.screenWidth - this.mWidth) / 2; break;
                case WindowPos.topRight :
                    this.mXpos = appData.screenWidth - this.mWidth; break;
                case WindowPos.midLeft  :
                    this.mYpos = (appData.screenHeight - this.mHeight) / 2; break;
                case WindowPos.midRight :
                    this.mXpos = appData.screenWidth - this.mWidth;
                    this.mYpos = (appData.screenHeight - this.mHeight) / 2; break;
                case WindowPos.bottomLeft :
                    this.mYpos = appData.screenHeight - this.mHeight; break;
                case WindowPos.bottomMid :
                    this.mXpos = (appData.screenWidth - this.mWidth) / 2;
                    this.mYpos = appData.screenHeight - this.mHeight; break;
                case WindowPos.bottomRight :
                    this.mXpos = appData.screenWidth - this.mWidth;
                    this.mYpos = appData.screenHeight - this.mHeight; break;
                default: break;
            }

        }

        void setWindowStyles() { // Private
            switch(this.mWinStyle) {
                case WindowStyle.fixed3D :
                    this.mExStyle = fixed3DExStyle;
                    this.mStyle = fixed3DStyle;
                    if (!this.maximizeBox) this.mStyle = this.mStyle ^ WS_MAXIMIZEBOX;
                    if (!this.minimizeBox) this.mStyle = this.mStyle ^ WS_MINIMIZEBOX;
                break;
                case WindowStyle.fixedDialog :
                    this.mExStyle = fixedDialogExStyle;
                    this.mStyle = fixedDialogStyle;
                    if (!this.maximizeBox) this.mStyle = this.mStyle ^ WS_MAXIMIZEBOX;
                    if (!this.minimizeBox) this.mStyle = this.mStyle ^ WS_MINIMIZEBOX;
                break;
                case WindowStyle.fixedSingle :
                    this.mExStyle = fixedSingleExStyle;
                    this.mStyle = fixedSingleStyle;
                    if (!this.maximizeBox) this.mStyle = this.mStyle ^ WS_MAXIMIZEBOX;
                    if (!this.minimizeBox) this.mStyle = this.mStyle ^ WS_MINIMIZEBOX;
                break;
                case WindowStyle.normalWin :
                    this.mExStyle = normalWinExStyle;
                    this.mStyle = normalWinStyle;
                    if (!this.maximizeBox) this.mStyle = this.mStyle ^ WS_MAXIMIZEBOX;
                    if (!this.minimizeBox) this.mStyle = this.mStyle ^ WS_MINIMIZEBOX;
                break;
                case WindowStyle.fixedTool :
                    this.mExStyle = fixedToolExStyle;
                    this.mStyle = fixedToolStyle;
                break;
                case WindowStyle.sizableTool :
                    this.mExStyle = sizableToolExStyle;
                    this.mStyle = sizableToolStyle;
                break;
                case WindowStyle.hidden:
                    this.mExStyle = WS_EX_TOOLWINDOW;
                    this.mStyle = WS_BORDER;
                break;
                default : break;
            }

            if (this.mTopMost) this.mExStyle = this.mExStyle | WS_EX_TOPMOST;
            if (this.mWinState == WindowState.maximized) this.mStyle = this.mStyle | WS_MAXIMIZE;
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

    	void propBackColorSetter(uint clr) {   // private
    		this.mBackColor(clr);
    		this.mBkDrawMode = WindowBkMode.singleColor;
    		if (this.mIsCreated) InvalidateRect(this.mHandle, null, false);
    	}

        void checkWinVwesion() {
            import  std.stdio;

            OSVERSIONINFOW ovi;
            ovi.dwOSVersionInfoSize = OSVERSIONINFOW.sizeof;
            GetVersionExW(&ovi);
            // string b;
            // b.reserve(ovi.szCSDVersion.length);
            // foreach (wchar c; ovi.szCSDVersion){
            //     b ~= c;
            // }
            writefln("OS Version : %s.%s.%s.%s", ovi.dwMajorVersion,
                ovi.dwMinorVersion, ovi.dwPlatformId, ovi.dwBuildNumber);
        }

        void setDataAtMoveMsg(int x, int y) {
            this.mXpos = x;
            this.mYpos = y;
        }

        void setDataAtSizeMsg(RECT rct) {
            this.mWidth = rct.right - rct.left;
            this.mHeight = rct.bottom - rct.top;
        }

        void finalize() {
            // If there is un managed hotkeys, remove all of them.
            if (this.mHotKeyIDList.length > 0) {
                foreach (int key; mHotKeyIDList) {
                    UnregisterHotKey(this.mHandle, key);
                    print("hot key id un registered", key);
                }
                this.mHotKeyIDList.length = 0;
            }
        }

        void createControlHandles() {
            if (this.mMenubarCreated && !this.mMenubar.mIsCreated) this.mMenubar.createHandle();
            if (this.mControls.length) {
                foreach (ctl; this.mControls) {
                    if (!ctl.mIsCreated) ctl.createHandle();
                }
            }
        }


}
//==========================END of Window CLASS=====================

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

HICON getWingsIcon()
{
    /* We need to make sure that the compiler get the icon path
     * regardless of the working directory. */
    import std.path;
    auto modulebase = dirName(__FILE_FULL_PATH__);
    auto icopath = format("%s\\wings_icon.ico", modulebase);
    return LoadImageW(null, icopath.toUTF16z(), IMAGE_ICON, 0, 0, LR_LOADFROMFILE | LR_DEFAULTSIZE);
}

void regWindowClass(wstring clsN,  HMODULE hInst)
{
    // auto x = getIconName();
    // auto icon = "wings\\np-wings.ico".toUTF16z();
    WNDCLASSEXW wcEx;
    wcEx.style         = CS_HREDRAW | CS_VREDRAW  | CS_OWNDC;
    wcEx.lpfnWndProc   = &mainWndProc;
    wcEx.cbClsExtra    = 0;
    wcEx.cbWndExtra    = 0;
    wcEx.hInstance     = hInst;
    wcEx.hIcon         = getWingsIcon();//LoadIconW(null, IDI_APPLICATION);
    wcEx.hCursor       = LoadCursorW(null, IDC_ARROW);
    wcEx.hbrBackground = CreateSolidBrush(appData.appColor.cref);//COLOR_WINDOW;
    wcEx.lpszMenuName  = null;
    wcEx.lpszClassName = clsN.ptr;

    RegisterClassExW(&wcEx);
}

// Some good back colors - 0xE8E9EB, 0xF5F5F5, 0xF2F3F5

void mainLoop()
{
    MSG uMsg;
    while (GetMessage(&uMsg, null, 0, 0) != 0) {
        TranslateMessage(&uMsg);
        DispatchMessage(&uMsg);
    }
}

void trackMouseMove(HWND hw)
{
    TRACKMOUSEEVENT tme;
    tme.cbSize = tme.sizeof;
    tme.dwFlags = TME_HOVER | TME_LEAVE;
    tme.dwHoverTime = HOVER_DEFAULT;
    tme.hwndTrack = hw;
    TrackMouseEvent(&tme);
}



/// WndProc function for Window class
extern(Windows)
LRESULT mainWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) nothrow {
    try {
        auto win = cast(Window) (cast(void *) GetWindowLongPtrW(hWnd, GWLP_USERDATA));
        switch (message) {
            case CM_WIN_THREAD_MSG: // Users can send this msg from different threads.
                if (win.onThreadMsg) {
                    win.onThreadMsg(wParam, lParam);
                }
            break;

            case WM_SHOWWINDOW :
                if (!win.mIsLoaded) {
                    win.mIsLoaded = true;
                    if (win.onLoad) win.onLoad(win, new EventArgs());
                }
                return 0;
            break;

            case WM_ACTIVATEAPP:
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

            case WM_NOTIFY :
                auto nm = cast(NMHDR*) lParam;
                return SendMessageW(nm.hwndFrom, CM_NOTIFY, wParam, lParam);
            break;

            case WM_CTLCOLOREDIT :
                auto ctlHwnd = cast(HWND) lParam;
                return SendMessageW(ctlHwnd, CM_COLOR_EDIT, wParam, lParam);
            break;

            case WM_CTLCOLORSTATIC :
                auto ctlHwnd = cast(HWND) lParam;
                //auto receiver = win.findComboInfo(ctlHwnd, false);
                //if (receiver) {
                //    return SendMessage(receiver, CM_COMBOTBCOLOR, wParam, lParam);
                //} else {
                //    return SendMessage(ctlHwnd, CM_COLOR_STATIC, wParam, lParam);
                //}
                return SendMessageW(ctlHwnd, CM_COLOR_STATIC, wParam, lParam);
            break;

            case WM_CTLCOLORLISTBOX :
                auto ctlHwnd = cast(HWND) lParam;
                // If user uses a ComboBox, it contains a ListBox in it.
                // So, 'ctlHwnd' might be a handle of that ListBox. Or it might be a normal ListBox too.
                // So, we need to check it before dispatch this message to that listbox.
                // Because, if it is from Combo's listbox, there is no Wndproc function for that ListBox.

                auto cmb = win.cmb_dict.get(ctlHwnd, null);
                if (cmb) {
                    return SendMessageW(cmb, CM_COLOR_CMB_LIST, wParam, lParam);
                } else {
                    return SendMessageW(ctlHwnd, CM_COLOR_EDIT, wParam, lParam);
                }
            break;

            case WM_COMMAND :
				// writefln("WM_COMMAND 1 - wpm hiw %d", HIWORD(wParam));
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
						// writeln("WM_COMMAND 2");
                        auto ctlHwnd = cast(HWND) lParam;
                        return SendMessageW(ctlHwnd, CM_CTLCOMMAND, wParam, lParam);
                    break;
                }

            break;


            case WM_KEYUP, WM_SYSKEYUP :
                if (win.onKeyUp) {
                    auto ea = new KeyEventArgs(wParam);
                    win.onKeyUp(win, ea);
                }
            break;

            case WM_KEYDOWN, WM_SYSKEYDOWN :
                if (win.onKeyDown) {
                    auto ea = new KeyEventArgs(wParam);
                    win.onKeyDown(win, ea);
                }
            break;

            case WM_CHAR :
                if (win.onKeyPress) {
                    auto ea = new KeyPressEventArgs(wParam);
                    win.onKeyPress(win, ea);
                }
            break;

            case WM_LBUTTONDOWN :
                win.lDownHappened = true;
                if (win.onMouseDown) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    win.onMouseDown(win, ea);
                    return 0;
                }
            break;

            case WM_LBUTTONUP :
                if (win.onMouseUp) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    win.onMouseUp(win, ea);
                }

                if (win.lDownHappened) {
                    win.lDownHappened = false;
                    sendMsg(win.mHandle, CM_LEFTCLICK, 0, 0);
                }
            break;

            case CM_LEFTCLICK :
                if (win.onMouseClick) {
                    auto ea = new EventArgs();
                    win.onMouseClick(win, ea);
                }
            break;

            case WM_RBUTTONDOWN :
                win.rDownHappened = true;
                if (win.onRightMouseDown) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    win.onRightMouseDown(win, ea);
                }
            break;

            case WM_RBUTTONUP :
                if (win.onRightMouseUp) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    win.onRightMouseUp(win, ea);
                }

                if (win.rDownHappened) {
                    win.rDownHappened = false;
                    sendMsg(win.mHandle, CM_RIGHTCLICK, 0, 0);
                }
            break;

            case CM_RIGHTCLICK :
                if (win.onRightClick) {
                    auto ea = new EventArgs();
                    win.onRightClick(win, ea);
                }
            break;

            case WM_MOUSEWHEEL :
                if (win.onMouseWheel) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    win.onMouseWheel(win, ea);
                }
            break;

            case WM_MOUSEMOVE :
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

            case WM_MOUSEHOVER :
                if (win.mIsMouseTracking) {win.mIsMouseTracking = false;}
                if (win.onMouseHover) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    win.onMouseHover(win, ea);
                }
            break;

            case WM_MOUSELEAVE :
                if (win.mIsMouseTracking) {
                    win.mIsMouseTracking = false;
                    win.mIsMouseEntered = false;
                }
                if (win.onMouseLeave) {
                    auto ea = new EventArgs();
                    win.onMouseLeave(win, ea);
                }
            break;

            case WM_HSCROLL: return SendMessageW(cast(HWND) lParam, CM_HSCROLL, wParam, lParam);
            case WM_VSCROLL: return SendMessageW(cast(HWND) lParam, CM_VSCROLL, wParam, lParam);

            case WM_SIZING :
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

            case WM_SIZE :
                win.mSizingStarted = false;
                if (win.onSized) {
                    auto sea = new SizeEventArgs(message, wParam, lParam);
                    win.onSized(win, sea);
                    return 1;
                }

            break;

            case WM_MOVE :
                win.setDataAtMoveMsg(xFromLparam(lParam), yFromLparam(lParam));
                if (win.onMoved) {
                    auto ea = new EventArgs();
                    win.onMoved(win, ea);
                }
                return 0;
            break;

            case WM_MOVING :
                auto rct = cast(RECT*) lParam;
                win.setDataAtMoveMsg(rct.left, rct.top);
                if (win.onMoving) {
                    auto ea = new EventArgs();
                    win.onMoving(win, ea);
                    return 1;
                }
                return 0;
            break;

            case WM_SYSCOMMAND :
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

            case WM_ERASEBKGND :
                if (win.mBkDrawMode != WindowBkMode.normal) {
                    auto dch = cast(HDC) wParam;
                    win.setBkClrInternal(dch);
                    return cast(LRESULT)1; // We must return non zero value if handle this message.
                }
                // Do not return zero here. It will cause static controls's back ground looks ugly.
            break;

            case WM_HOTKEY :
                if (win.onHotKeyPress) {
                    auto hea = new HotKeyEventArgs(wParam, lParam);
                    win.onHotKeyPress(win, hea);
                }
            break;

            case WM_CLOSE :
                if (win.onClosing) {
                    auto ea = new EventArgs();
                    win.onClosing(win, ea);
                }
            break;

            case WM_DESTROY :
                if (win.onClosed) {
                    auto ea = new EventArgs();
                    win.onClosed(win, ea);
                }
                win.finalize; // Doing some housekeeping for this window.

                if (hWnd == appData.mainWinHandle) PostQuitMessage(0);
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
                if (dis.itemState == 320 || dis.itemState == 257) {
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
                // De-reference the pointer and put the menu item in our dict
                win.mMenuItemDict[cast(uint)wParam] = *(cast(MenuItem*) (cast(void*)lParam));
                // writeln("Added menu name : ", win.mMenuItemDict[cast(uint)wParam].mText);
                return 0;
            break;

            case WM_MENUSELECT:
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
                auto menu = win.getMenuFromHmenu(cast(HMENU) wParam);
                if (menu && menu.onPopup) menu.onPopup(menu, new EventArgs());
            break;

            case WM_UNINITMENUPOPUP:
                auto menu = win.getMenuFromHmenu(cast(HMENU) wParam);
                if (menu && menu.onCloseup) menu.onCloseup(menu, new EventArgs());
            break;

            default: return DefWindowProcW(hWnd, message, wParam, lParam); break;
        }
    }
    catch (Exception e){}
    return DefWindowProcW(hWnd, message, wParam, lParam);
}

