
module wings.window;
pragma(lib, "user32");


import wings.d_essentials;
private import std.format;


private import wings.controls;
private import wings.commons;
private import wings.events;
private import wings.fonts;
private import wings.enums;
private import wings.winstyle_contsants;
private import wings.colors;
private import wings.gradient ;
private import wings.combobox : ComboInfo;


package HWND mainHwnd ; // A handle for main window

// Compile time values to use later
package enum uint gBkColor = 0xf5f5f5 ; // Global Back color for window
package enum string defWinFontName = "Ebrima" ;
package enum int defWinFontSize = 14 ;
package enum FontWeight defWinFontWeight = FontWeight.normal ;

package bool isWindowInit = false;

///This class is a form class
class Window : Control {    
    


    // properties
        final WindowPos startPos() {return this.mStartPos;}
        final void startPos(WindowPos value ) {this.mStartPos = value;}

        final WindowStyle style() {return this.mWinStyle;}
        final void style(WindowStyle value ) {this.mWinStyle = value;}

        final bool topMost() {return this.mTopMost;}
        final void topMost(bool value ) {this.mTopMost = value;}

        final WindowState windowState() {return this.mWinState;}
        final void windowState(WindowState value ) {this.mWinState = value;}
       
        final override uint backColor() const {return this.mBackColor ;}
        final override void backColor(uint clr) {propBackColorSetter(clr) ;}

        final bool maximizeBox() const {return this.mMaxBox ;}
        final void maximizeBox(bool value) {this.mMaxBox = value ;}

        final bool minimizeBox() const {return this.mMinBox ;}
        final void minimizeBox(bool value) {this.mMinBox = value ;}       
    

    EventHandler onMinimized, onMaximized, onRestored, onClosing, onClosed, onLoad ;
    EventHandler onActivate, onDeActivate, onMoving, onMoved ;
    SizeEventHandler onSized, onSizing ;



   
    ///the constructor of form class
    private this(string txt, int x, int y, int w, int h) {        
        if (!isWindowInit) { // It's the first window.
            isWindowInit = true;            
            appData = new ApplicationData( defWinFontName, defWinFontSize, defWinFontWeight);
            regWindowClass(appData.className, appData.hInstance);
        }

        this.mText = txt ;
        this.mWidth = w ;
        this.mHeight = h ;
        this.mXpos = x ;
        this.mYpos = y ;
        this.mStartPos = WindowPos.center ;
        this.maximizeBox = true ;
        this.minimizeBox = true ;
        this.mWinStyle = WindowStyle.normalWin ; 
        this.mBkDrawMode = WindowBkMode.normal ; 
        this.mFont = appData.mainFont;   
        this.controlType = ControlType.window ;  
        this.mBackColor = gBkColor ; 
        mWinCount += 1 ; // Incrementing private static variable             
    }

    this () {
        string title = format("%s_%d", "Form", mWinCount + 1) ;
        this(title, 0, 0, 500, 400);
    }

    this(string title) {
        this(title, 0, 0, 500, 400);
    }

    this(string title, int w, int h) {
        this(title, 0, 0, w, h);
    }

    /// Creates the window
    final void create() { 
        setStartPos() ;
        setWindowStyles() ;           
        this.mHandle = CreateWindowExW( this.mExStyle, 
                                        appData.className.toUTF16z, 
                                        this.mText.toUTF16z, 
                                        this.mStyle, 
                                        this.mXpos, 
                                        this.mYpos,
                                        this.mWidth,
                                        this.mHeight, 
                                        null,  
                                        menuHwnd, 
                                        appData.hInstance,
                                        null) ;
                                        
        if (this.mHandle ) {
            this.mIsCreated = true; 
            if (appData.mainWinHandle == null) appData.mainWinHandle = this.mHandle ;            
            SetWindowLongPtrW(this.mHandle, GWLP_USERDATA, (cast(LONG_PTR) cast(void*) this) ) ;              
            this.setFontInternal() ;                             
        } 
        else throw new Exception("Window is not created...") ; // Do we need this ?          
    }
    
    /// This will show the form on the screen
    final void show() {
        ShowWindow(this.mHandle, SW_SHOW) ;
        UpdateWindow(this.mHandle) ;
        if(!mMainLoopStarted) {
            mMainLoopStarted = true ;
            mainLoop() ;
        }
    }

    /// This will set the gradient background color for this window.
    final void setGradientColors(uint c1, uint c2, GradientStyle gStyle = GradientStyle.topToBottom) {        
        this.mBkDrawMode = WindowBkMode.gradient ;        
        this.gradData = Gradient(c1, c2, gStyle) ;       
        this.reDraw() ;
    }

    /// closes the window
    final void close() { DestroyWindow(this.mHandle);} 

    final void printPoint(MouseEventArgs e) {
        import std.stdio;        
        static int x = 1 ;
        writefln("[%s] X : %s, Y : %s", x, e.xPos, e.yPos) ;
        ++x ;
    }

    
    
    package : //----------------------------------
        bool misBkClrChanged ;
        bool mIsLoaded ;
        bool mIsMouseTracking ;
        bool mIsMouseEntered ;   
        WindowBkMode mBkDrawMode ;           
       // static HMODULE mHInstance ;
        ComboInfo[] cmbInfoList ;


        // This function is responsible for changing back color of window..
        // in the WndProc function, in the occurance of WM_ERASEKBGND
        final void setBkClrInternal(HDC dcHandle) { // package
            RECT rct;
            GetClientRect(this.mHandle, &rct) ;
            HBRUSH hBr ;
            scope(exit) DeleteObject(hBr) ;

            if (this.mBkDrawMode == WindowBkMode.singleColor ) {
                hBr = CreateSolidBrush(getClrRef(this.mBackColor)) ;
            }
            else if (this.mBkDrawMode == WindowBkMode.gradient) {
                hBr = createGradientBrush(dcHandle, &rct, this.gradData) ; 
            }

            FillRect(dcHandle, &rct, hBr) ;            
        }

        final saveComboInfo(ref ComboInfo ci) { // Package
            if (this.cmbInfoList.length > 0) {
                bool found ;
                foreach (c ; this.cmbInfoList) {
                    if (c.comboId == ci.comboId) {
                        c.changeData(ci);
                        found = true ;
                        break ;
                    }
                    if (!found) this.cmbInfoList ~= ci ;
                }
            } else {
                this.cmbInfoList ~= ci ;
            }            
        }

        final HWND findComboInfo(HWND hw, bool searchLB) { // Package
            HWND result = null ;
            if (this.cmbInfoList.length > 0) {
                if (searchLB) {
                    foreach (ci; this.cmbInfoList) {
                        if (ci.lbHwnd == hw) {
                            result = ci.cmbHwnd ;
                            break ;
                        }
                    }
                } else {
                    foreach (ci; this.cmbInfoList) {
                        if (ci.tbHwnd == hw) {
                            result = ci.cmbHwnd ;
                            break ;
                        }
                    }  
                } 
            }
            return result;            
        }

     

     
    private : //-------------------------------
        static int mWinCount  ;
        static bool mMainLoopStarted ;
        
        static string mClassName ;
        static int screenWidth ;
        static int screenHeight ;

        int iNumber ;
        bool isLoaded ; 
        bool mTopMost ;   
        bool mMaxBox;
        bool mMinBox;       
    	
        HMENU menuHwnd ;
        DWORD winStyle = WS_OVERLAPPEDWINDOW ;
        WindowPos mStartPos ;
        WindowStyle mWinStyle ;
        WindowState mWinState ;
        Gradient gradData ;



        void setStartPos() { // Private
            switch (this.mStartPos) {   
                case WindowPos.center :
                    this.mXpos = (appData.screenWidth - this.mWidth) / 2  ;
                    this.mYpos = (appData.screenHeight - this.mHeight) / 2  ;
                    break ;

                case WindowPos.topLeft  : break ;
                case WindowPos.manual   : break ;

                case WindowPos.topMid   : 
                    this.mXpos = (appData.screenWidth - this.mWidth) / 2  ; break ;
                case WindowPos.topRight :  
                    this.mXpos = appData.screenWidth - this.mWidth ; break ;
                case WindowPos.midLeft  : 
                    this.mYpos = (appData.screenHeight - this.mHeight) / 2 ; break ;   
                case WindowPos.midRight :
                    this.mXpos = appData.screenWidth - this.mWidth ;
                    this.mYpos = (appData.screenHeight - this.mHeight) / 2  ; break ;
                case WindowPos.bottomLeft : 
                    this.mYpos = appData.screenHeight - this.mHeight ; break ;
                case WindowPos.bottomMid :
                    this.mXpos = (appData.screenWidth - this.mWidth) / 2  ;
                    this.mYpos = appData.screenHeight - this.mHeight ; break ;
                case WindowPos.bottomRight :
                    this.mXpos = appData.screenWidth - this.mWidth  ;
                    this.mYpos = appData.screenHeight - this.mHeight ; break ;
                default: break;
            }
        }
        
        void setWindowStyles() { // Private
            switch(this.mWinStyle) {
                case WindowStyle.fixed3D :
                    this.mExStyle = fixed3DExStyle ;
                    this.mStyle = fixed3DStyle ;
                    if (!this.maximizeBox) this.mStyle = this.mStyle ^ WS_MAXIMIZEBOX ;
                    if (!this.minimizeBox) this.mStyle = this.mStyle ^ WS_MINIMIZEBOX ;
                    break ;
                case WindowStyle.fixedDialog :
                    this.mExStyle = fixedDialogExStyle ;
                    this.mStyle = fixedDialogStyle ;
                    if (!this.maximizeBox) this.mStyle = this.mStyle ^ WS_MAXIMIZEBOX ;
                    if (!this.minimizeBox) this.mStyle = this.mStyle ^ WS_MINIMIZEBOX ;
                    break ;
                case WindowStyle.fixedSingle :
                    this.mExStyle = fixedSingleExStyle ;
                    this.mStyle = fixedSingleStyle ;
                    if (!this.maximizeBox) this.mStyle = this.mStyle ^ WS_MAXIMIZEBOX ;
                    if (!this.minimizeBox) this.mStyle = this.mStyle ^ WS_MINIMIZEBOX ;
                    break ;            
                case WindowStyle.normalWin :
                    this.mExStyle = normalWinExStyle ;
                    this.mStyle = normalWinStyle ;
                    if (!this.maximizeBox) this.mStyle = this.mStyle ^ WS_MAXIMIZEBOX ;
                    if (!this.minimizeBox) this.mStyle = this.mStyle ^ WS_MINIMIZEBOX ;
                    break ;
                case WindowStyle.fixedTool :
                    this.mExStyle = fixedToolExStyle ;
                    this.mStyle = fixedToolStyle ;
                    break ;
                case WindowStyle.sizableTool :
                    this.mExStyle = sizableToolExStyle ;
                    this.mStyle = sizableToolStyle ;
                    break ;
                default : break ;
            }

            if (this.mTopMost) this.mExStyle = this.mExStyle | WS_EX_TOPMOST ;
    		
            final switch (this.mWinState) {
                case WindowState.normal : break ;
                case WindowState.maximized : 
                    this.mStyle = this.mStyle | WS_MAXIMIZE ;
                    break ;
                case WindowState.minimized : 
                    this.mStyle = this.mStyle | WS_MINIMIZE ;
                    break ;
            }                  
        }
    	
    	void propBackColorSetter(uint clr) {   // private			
    		this.mBackColor = clr ;
    		this.mBkDrawMode = WindowBkMode.singleColor ;
    		if (this.mIsCreated) InvalidateRect(this.mHandle, null, true) ;			
    	}

        

}
//==========================END CLASS=====================




void regWindowClass(string clsN,  HMODULE hInst) {   
    WNDCLASSEXW wcEx ;

    wcEx.style         = CS_HREDRAW | CS_VREDRAW | CS_DBLCLKS ;
    wcEx.lpfnWndProc   = &mainWndProc ;
    wcEx.cbClsExtra    = 0;
    wcEx.cbWndExtra    = 0;
    wcEx.hInstance     = hInst;
    wcEx.hIcon         = LoadIconW(null, IDI_APPLICATION);
    wcEx.hCursor       = LoadCursorW(null, IDC_ARROW);
    wcEx.hbrBackground = CreateSolidBrush(getClrRef(gBkColor)) ;//COLOR_WINDOW;
    wcEx.lpszMenuName  = null;
    wcEx.lpszClassName = clsN.toUTF16z;

    RegisterClassExW(&wcEx) ;             
} 

// Some good back colors - 0xE8E9EB, 0xF5F5F5, 0xF2F3F5

void mainLoop() {
    MSG uMsg ;
    while (GetMessage(&uMsg, null, 0, 0) != 0) {
        TranslateMessage(&uMsg);
        DispatchMessage(&uMsg);
    } 
}

void trackMouseMove(HWND hw) {
    TRACKMOUSEEVENT tme ;    
    tme.cbSize = tme.sizeof ;
    tme.dwFlags = TME_HOVER | TME_LEAVE ;
    tme.dwHoverTime = HOVER_DEFAULT ;
    tme.hwndTrack = hw ; 
    TrackMouseEvent(&tme) ;
}



/// WndProc function for Window class
extern(Windows)
LRESULT mainWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) nothrow { 

    try {
        auto win = cast(Window) (cast(void *) GetWindowLongPtrW(hWnd, GWLP_USERDATA)) ;       
        switch (message) { 

            case WM_SHOWWINDOW : 
                if (!win.mIsLoaded) {
                    win.mIsLoaded = true ;
                    if (win.onLoad) {
                        auto ea = new EventArgs() ;
                        win.onLoad(win, ea) ;
                    }
                } break ;             
            
            case WM_ACTIVATEAPP : 
                if (win.onActivate || win.onDeActivate) {
                    auto ea = new EventArgs() ;
                    immutable bool flag = cast(bool) wParam ;
                    if (!flag) {
                        if (win.onDeActivate) {
                            win.onDeActivate(win, ea) ;
                        }
                        return 0 ;                        
                    }      else {
                        if (win.onActivate) {
                            win.onActivate(win, ea) ;
                        }
                    }
                } break ;

            case WM_CTLCOLOREDIT :
                auto ctlHwnd = cast(HWND) lParam;
                auto receiver = win.findComboInfo(ctlHwnd, false);
                if (receiver) {
                    return SendMessage(receiver, CM_COMBOTBCOLOR, wParam, lParam) ;
                } else {
                    return SendMessage(ctlHwnd, CM_CTLCOLOR, wParam, lParam) ;
                }                 
                break ;

            case WM_CTLCOLORSTATIC :                
                auto ctlHwnd = cast(HWND) lParam;
                
                auto receiver = win.findComboInfo(ctlHwnd, false);
                if (receiver) {
                    return SendMessage(receiver, CM_COMBOTBCOLOR, wParam, lParam) ;
                } else {
                    return SendMessage(ctlHwnd, CM_COLORSTATIC, wParam, lParam) ;
                }       
                //return SendMessage(ctlHwnd, CM_COLORSTATIC, wParam, lParam) ;
                break;

            case WM_CTLCOLORLISTBOX :
                auto ctlHwnd = cast(HWND) lParam ;
                // If user uses a ComboBox, it contains a ListBox in it.
                // So, 'ctlHwnd' might be a handle of that ListBox. Or it might be a normal ListBox too.
                // So, we need to check it before disptch this message to that listbox.
                // Because, if it is from Combo's listbox, there is no Wndproc function for that ListBox.
                auto receiver = win.findComboInfo(ctlHwnd, true);
                if (receiver) {
                    return SendMessage(receiver, CM_COMBOLBCOLOR, wParam, lParam) ;
                } else {
                    return SendMessage(ctlHwnd, CM_CTLCOLOR, wParam, lParam) ;
                }
                
                break ; 

            case WM_COMMAND :
                auto ctlHwnd = cast(HWND) lParam ;                
                return SendMessage(ctlHwnd, CM_CTLCOMMAND, wParam, lParam) ;
                break ;
            

            case WM_KEYUP, WM_SYSKEYUP : 
                if (win.onKeyUp) {
                    auto ea = new KeyEventArgs(wParam) ;
                    win.onKeyUp(win, ea) ;                    
                } break ;
            
            case WM_KEYDOWN, WM_SYSKEYDOWN :
                if (win.onKeyDown) {
                    auto ea = new KeyEventArgs(wParam) ;
                    win.onKeyDown(win, ea) ;
                } break ;
                
            case WM_CHAR : 
                if (win.onKeyPress) {
                    auto ea = new KeyPressEventArgs(wParam) ;
                    win.onKeyPress(win, ea) ;
                } break ;
                

            case WM_LBUTTONDOWN : 
                win.lDownHappened = true ;
                if (win.onMouseDown) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    win.onMouseDown(win, ea); 
                    return 0 ;                    
                } break ;
                
            case WM_LBUTTONUP :
                if (win.onMouseUp) {
                    auto ea = new MouseEventArgs(message, wParam, lParam) ;
                    win.onMouseUp(win, ea) ;
                } 

                if (win.lDownHappened) {
                    win.lDownHappened = false ;
                    sendMsg(win.handle, CM_LEFTCLICK, 0, 0) ;
                }
                break ;

            case CM_LEFTCLICK :
                if (win.onMouseClick) {
                    auto ea = new EventArgs() ;
                    win.onMouseClick(win, ea) ;
                } break ;

                
            case WM_RBUTTONDOWN :
                win.rDownHappened = true;
                if (win.onRightMouseDown) {
                    auto ea = new MouseEventArgs(message, wParam, lParam) ;
                    win.onRightMouseDown(win, ea) ;
                } break ;
            
            case WM_RBUTTONUP :
                if (win.onRightMouseUp) {
                    auto ea = new MouseEventArgs(message, wParam, lParam) ;
                    win.onRightMouseUp(win, ea) ;
                } 

                if (win.rDownHappened) {
                    win.rDownHappened = false ;
                    sendMsg(win.handle, CM_RIGHTCLICK, 0, 0) ;
                } break ;

            case CM_RIGHTCLICK :
                if (win.onRightClick) {
                    auto ea = new EventArgs() ;
                    win.onRightClick(win, ea) ;
                } break ;

            

                
            case WM_MOUSEWHEEL :
                if (win.onMouseWheel) {
                    auto ea = new MouseEventArgs(message, wParam, lParam) ;
                    win.onMouseWheel(win, ea) ;
                } break ;

            case WM_MOUSEMOVE :
                if (!win.mIsMouseTracking) {
                    win.mIsMouseTracking = true ;
                    trackMouseMove(hWnd);
                    if (!win.mIsMouseEntered) {
                        if (win.onMouseEnter) {
                            win.mIsMouseEntered = true ;
                            auto ea = new EventArgs() ;
                            win.onMouseEnter(win, ea) ;
                        }
                    }
                }
                if (win.onMouseMove) {
                    auto ea = new MouseEventArgs(message, wParam, lParam) ;
                    win.onMouseMove(win, ea) ;
                } break ;
            
            case WM_MOUSEHOVER :
                if (win.mIsMouseTracking) {win.mIsMouseTracking = false ;}
                if (win.onMouseHover) {
                    auto ea = new MouseEventArgs(message, wParam, lParam) ;
                    win.onMouseHover(win, ea) ;
                } break ;
                
            case WM_MOUSELEAVE :
                if (win.mIsMouseTracking) {
                    win.mIsMouseTracking = false ;
                    win.mIsMouseEntered = false ;
                }
                if (win.onMouseLeave) {
                    auto ea = new EventArgs() ;
                    win.onMouseLeave(win, ea) ;
                } break ;

            case WM_SIZING : 
                auto sea = new SizeEventArgs(message, wParam, lParam);
                win.width = sea.windowRect.right - sea.windowRect.left;
                win.height = sea.windowRect.bottom - sea.windowRect.top;
                if (win.onSizing) {
                    win.onSizing(win, sea);
                    return 1;
                } break ;

            case WM_SIZE : 
                auto sea = new SizeEventArgs(message, wParam, lParam);
                if (win.onSized) {
                    win.onSized(win, sea);
                    return 1;
                } break ;
                
            case WM_MOVE :  
                win.xPos = xFromLparam(lParam);
                win.yPos = yFromLparam(lParam);
                if (win.onMoved) {
                    auto ea = new EventArgs();
                    win.onMoved(win, ea);
                    return 0;
                }
                return 0;

            case WM_MOVING : 
                auto rct = cast(RECT*) lParam;
                win.xPos = rct.left;
                win.yPos = rct.top;
                if (win.onMoving) {
                    auto ea = new EventArgs();
                    win.onMoving(win, ea);
                    return 1;
                }
                return 0;

            case WM_NOTIFY :  
                auto nm = cast(NMHDR*) lParam;
                return SendMessage(nm.hwndFrom, CM_NOTIFY, wParam, lParam) ;
                break ;
            
            case WM_SYSCOMMAND :
                auto uMsg = cast(UINT) (wParam & 0xFFF0) ;
                switch (uMsg) {
                    case SC_MINIMIZE :
                        if (win.onMinimized) {
                            auto ea = new EventArgs() ;
                            win.onMinimized(win, ea) ;
                        } break ;
                    case SC_MAXIMIZE :
                        if (win.onMaximized) {
                            auto ea = new EventArgs() ;
                            win.onMaximized(win, ea) ;
                        } break ;
                    case SC_RESTORE :
                        if (win.onRestored) {
                            auto ea = new EventArgs() ;
                            win.onRestored(win, ea) ;
                        } break ;
                    default : break ;
                } break ;            
            
            case WM_ERASEBKGND : 
                if (win.mBkDrawMode != WindowBkMode.normal) {   
                    auto dch = cast(HDC) wParam ;
                    win.setBkClrInternal(dch) ;
                    return 1 ;                  
                } 
                break ;
                
            case WM_CLOSE :
                if (win.onClosing) {
                    auto ea = new EventArgs() ;
                    win.onClosing(win, ea) ;
                } break ;

            case WM_DESTROY :
                if (win.onClosed) {
                    auto ea = new EventArgs() ;
                    win.onClosed(win, ea) ;
                }

                if (hWnd == appData.mainWinHandle) PostQuitMessage(0);
                break;
            

            default: break ;
        }
    }
    catch (Exception e){}
    return DefWindowProcW(hWnd, message, wParam, lParam);
}

