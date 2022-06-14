
module winglib.window;

private import core.runtime;
private import core.sys.windows.windows ;
private import core.sys.windows.commctrl;
private import std.stdio ;
private import std.math ;
private import std.utf;

private import winglib.controls;
private import winglib.commons;
private import winglib.events;
private import winglib.fonts;
private import winglib.enums;
private import winglib.winstyle_contsants;
private import winglib.colors;

HWND mainHwnd ; // A handle for main window


//immutable uint um_click = 101;
//Window[] winList;


///This class is a form class
class Window : Control {    
    //Control[] controls; // A list to hold all childs.

    @property WindowPos startPos() {return this.mStartPos;}
    @property void startPos(WindowPos value ) {this.mStartPos = value;}

    @property WindowStyle style() {return this.mWinStyle;}
    @property void style(WindowStyle value ) {this.mWinStyle = value;}

    @property bool topMost() {return this.mTopMost;}
    @property void topMost(bool value ) {this.mTopMost = value;}

    @property DisplayState windowState() {return this.mWinState;}
    @property void windowState(DisplayState value ) {this.mWinState = value;}
	
	@property void backColor(uint clr) {propBackColorSetter(clr) ;}
    @property uint backColor() {return this.mBackColor ;}

    bool maximizeBox ;
    bool minimizeBox ;

    EventHandler onMinimized  ; 
    EventHandler onMaximized  ; 
    EventHandler onRestored  ; 
    EventHandler onClosing  ; 
    EventHandler onClosed  ; 
    EventHandler onLoad  ; 
    EventHandler onActivate  ; 
    EventHandler onDeActivate  ; 
   
    ///the constructor of form class
    this() {
        mWinCount += 1 ;
        if (mWinCount == 1) { // It's the first window.
            mHInstance = GetModuleHandleW(null) ;
            mClassName = "WingLib_Window_Class" ;
            regWindowClass(mClassName, mHInstance);
            screenWidth = GetSystemMetrics(0);
            screenHeight = GetSystemMetrics(1);
        }

        this.mText = "Form_1" ;
        this.mWidth = 500 ;
        this.mHeight = 400 ;
        this.mXpos = CW_USEDEFAULT ;
        this.mYpos = CW_USEDEFAULT ;
        this.mStartPos = WindowPos.center ;
        this.maximizeBox = true ;
        this.minimizeBox = true ;
        this.mWinStyle = WindowStyle.normalWin ; 
        this.mBkDrawMode = WindowBkMode.normal ; 
        this.mFont = new Font("Tahoma", 13) ;                    
    }

    /// Creates the window
    void create() { 
        setStartPos() ;
        setWindowStyles() ;           
        this.mHandle = CreateWindowExW( this.mExStyle, 
                                        mClassName.toUTF16z, 
                                        this.mText.toUTF16z, 
                                        this.mStyle, 
                                        this.mXpos, 
                                        this.mYpos,
                                        this.mWidth,
                                        this.mHeight, 
                                        NULL,  
                                        menuHwnd, 
                                        mHInstance,
                                        NULL) ;
                                        
        if (this.mHandle ) {
            this.mIsCreated = true; 
            if (mainHwnd == NULL) mainHwnd = this.mHandle ;            
            SetWindowLongPtrW(this.mHandle, GWLP_USERDATA, (cast(LONG_PTR) cast(void*) this) ) ; 
            this.setFont() ;                  
        } 
        else {writeln("Window is not created...") ;} // Think is it needed ?          
    }
    
    /// This will show the form on the screen
    void show() {
        ShowWindow(this.mHandle, SW_SHOW) ;
        UpdateWindow(this.mHandle) ;
        if(!mMaiLoopStarted) {
            mMaiLoopStarted = true ;
            mainLoop() ;
        }
    }

    /// closes the window
    void close() { DestroyWindow(this.mHandle);} 

    /** Set a gradient back ground color for window.
     * Params:
     *  c1 = First color
     *  c2 = Second color
     *  GradientStyle = Enum (topToBottom = default, leftToRight)
     */ 
    void setGradientBackColor(uint c1, uint c2, GradientStyle gStyle = GradientStyle.topToBottom) {
        this.mClr1 = getRgbColor(c1) ;
        this.mClr2 = getRgbColor(c2) ;
        this.mBkDrawMode = WindowBkMode.gradient ;
        this.mGrStyle = gStyle ;         
        if (this.mIsCreated) {InvalidateRect(this.mHandle, null, true) ;}
    }  
    
    package : //----------------------------------
    bool misBkClrChanged ;
    bool mIsLoaded ;
    bool mIsMouseTracking ;
    bool mIsMouseEntered ;

    
   
    WindowBkMode mBkDrawMode ;
    
    static HMODULE mHInstance ;

    
    void setBkClrInternal(HDC dcHandle) {
        RECT rct;
        GetClientRect(this.mHandle, &rct) ;
        HBRUSH hBr ;

        if (this.mBkDrawMode == WindowBkMode.singleColor ) {
            hBr = CreateSolidBrush(getClrRef(this.mBackColor)) ;
        }
        else if (this.mBkDrawMode == WindowBkMode.gradient) {
            hBr = createGreadientBrush(dcHandle, rct) ;
        }

        FillRect(dcHandle, &rct, hBr) ;
        DeleteObject(hBr) ;
    }

     

     
    private : //-------------------------------
    static int mWinCount ;
    static bool mMaiLoopStarted ;
    
    static string mClassName ;
    static int screenWidth ;
    static int screenHeight ;

    int iNumber ;
    bool isLoaded ; 
    bool mTopMost ;  

    RgbColor mClr1 ;
    RgbColor mClr2 ;
    GradientStyle mGrStyle ;
	
    HMENU menuHwnd ;
    DWORD winStyle = WS_OVERLAPPEDWINDOW ;
    WindowPos mStartPos ;
    WindowStyle mWinStyle ;
    DisplayState mWinState ;



    void setStartPos() {
        switch (this.mStartPos) {   
            case WindowPos.center :
                this.mXpos = (screenWidth - this.mWidth) / 2  ;
                this.mYpos = (screenHeight - this.mHeight) / 2  ;
                break ;

            case WindowPos.topLeft  : break ;
            case WindowPos.manual   : break ;

            case WindowPos.topMid   : 
                this.mXpos = (screenWidth - this.mWidth) / 2  ; break ;
            case WindowPos.topRight :  
                this.mXpos = screenWidth - this.mWidth ; break ;
            case WindowPos.midLeft  : 
                this.mYpos = (screenHeight - this.mHeight) / 2 ; break ;   
            case WindowPos.midRight :
                this.mXpos = screenWidth - this.mWidth ;
                this.mYpos = (screenHeight - this.mHeight) / 2  ; break ;
            case WindowPos.bottomLeft : 
                this.mYpos = screenHeight - this.mHeight ; break ;
            case WindowPos.bottomMid :
                this.mXpos = (screenWidth - this.mWidth) / 2  ;
                this.mYpos = screenHeight - this.mHeight ; break ;
            case WindowPos.bottomRight :
                this.mXpos = screenWidth - this.mWidth  ;
                this.mYpos = screenHeight - this.mHeight ; break ;
            default: break;
        }
    }
    
    void setWindowStyles() {
        switch(this.mWinStyle) {
            case WindowStyle.fixed3D :
                this.mExStyle = fixed3DExStyle ;
                this.mStyle = fixed3DStyle ;
                if (!this.maximizeBox) {this.mStyle = this.mStyle ^ WS_MAXIMIZEBOX ;}
                if (!this.minimizeBox) {this.mStyle = this.mStyle ^ WS_MINIMIZEBOX ;}
                break ;
            case WindowStyle.fixedDialog :
                this.mExStyle = fixedDialogExStyle ;
                this.mStyle = fixedDialogStyle ;
                if (!this.maximizeBox) {this.mStyle = this.mStyle ^ WS_MAXIMIZEBOX ;}
                if (!this.minimizeBox) {this.mStyle = this.mStyle ^ WS_MINIMIZEBOX ;}
                break ;
            case WindowStyle.fixedSingle :
                this.mExStyle = fixedSingleExStyle ;
                this.mStyle = fixedSingleStyle ;
                if (!this.maximizeBox) {this.mStyle = this.mStyle ^ WS_MAXIMIZEBOX ;}
                if (!this.minimizeBox) {this.mStyle = this.mStyle ^ WS_MINIMIZEBOX ;}
                break ;            
            case WindowStyle.normalWin :
                this.mExStyle = normalWinExStyle ;
                this.mStyle = normalWinStyle ;
                if (!this.maximizeBox) {this.mStyle = this.mStyle ^ WS_MAXIMIZEBOX ;}
                if (!this.minimizeBox) {this.mStyle = this.mStyle ^ WS_MINIMIZEBOX ;}
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

        if (this.mTopMost) {this.mExStyle = this.mExStyle | WS_EX_TOPMOST ;}
		
        final switch (this.mWinState) {
            case DisplayState.normal : break ;
            case DisplayState.maximized : 
                this.mStyle = this.mStyle | WS_MAXIMIZE ;
                break ;
            case DisplayState.minimized : 
                this.mStyle = this.mStyle | WS_MINIMIZE ;
                break ;
        }                  
    }
	
	void propBackColorSetter(uint clr) {   			
		this.mBackColor = clr ;
		this.mBkDrawMode = WindowBkMode.singleColor ;
		if (this.mIsCreated) {InvalidateRect(this.mHandle, null, true) ;}			
	}

    HBRUSH createGreadientBrush(HDC dcHandle, RECT rct) {              
        HBRUSH tBrush ;
        HDC memHDC = CreateCompatibleDC(dcHandle) ;
        HBITMAP hBmp = CreateCompatibleBitmap(dcHandle, rct.right, rct.bottom) ;
        const int loopEnd = this.mGrStyle == GradientStyle.topToBottom ? rct.bottom : rct.right ;             

        SelectObject(memHDC, hBmp) ;            

        for (int i = 0; i < loopEnd; i++) {
            RECT tRct ; 
            uint r, g, b ;

            r = this.mClr1.red + (i * (this.mClr2.red - this.mClr1.red) / loopEnd) ;
            g = this.mClr1.green + (i * (this.mClr2.green - this.mClr1.green) / loopEnd) ;
            b = this.mClr1.blue + (i * (this.mClr2.blue - this.mClr1.blue) / loopEnd) ;                
            
            tBrush = CreateSolidBrush(getClrRef(r, g, b)) ;

            tRct.left = this.mGrStyle == GradientStyle.topToBottom ? 0 : i ;
            tRct.top =  this.mGrStyle == GradientStyle.topToBottom ? i : 0 ;
            tRct.right = this.mGrStyle == GradientStyle.topToBottom ? rct.right : i + 1 ;
            tRct.bottom = this.mGrStyle == GradientStyle.topToBottom ? i + 1 : loopEnd ;

            FillRect(memHDC, &tRct, tBrush) ;
            DeleteObject(tBrush) ;   
        }

        auto grBrush = CreatePatternBrush(hBmp) ;
        DeleteDC(memHDC) ;
        DeleteObject(tBrush) ;
        DeleteObject(hBmp) ;
        return grBrush ;
    }   

}
//========================================================END CLASS=====================




void regWindowClass(string clsN,  HMODULE hInst) {
    import winglib.wnd_proc_module : fnWndProc = mainWndProc;
    WNDCLASSEXW wcEx ;

    wcEx.style         = CS_HREDRAW | CS_VREDRAW | CS_DBLCLKS ;
    wcEx.lpfnWndProc   = &fnWndProc ;
    wcEx.cbClsExtra    = 0;
    wcEx.cbWndExtra    = 0;
    wcEx.hInstance     = hInst;
    wcEx.hIcon         = LoadIconW(null, IDI_APPLICATION);
    wcEx.hCursor       = LoadCursorW(null, IDC_ARROW);
    wcEx.hbrBackground = CreateSolidBrush(getClrRef(0xD5D0AC)) ;//COLOR_WINDOW;
    wcEx.lpszMenuName  = null;
    wcEx.lpszClassName = clsN.toUTF16z;

    RegisterClassExW(&wcEx) ;             
} 

void mainLoop() {
    MSG uMsg ;
    while (GetMessage(&uMsg, null, 0, 0) != 0) {
        TranslateMessage(&uMsg);
        DispatchMessage(&uMsg);
    } 
}

