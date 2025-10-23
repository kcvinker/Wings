
module wings.application;

import std.stdio;
import core.sys.windows.windows;
import core.sys.windows.commctrl;
import wings.commons: print, ptf;


import wings.events: EventArgs;
// import core.runtime ;
// import std.string;

// Tell the linker to link these libs when compiling.
pragma(lib, "user32.lib");
pragma(lib, "gdi32.lib");
pragma(lib, "comctl32.lib");
pragma(lib, "gdiplus.lib");
pragma(lib, "Shcore.lib");
pragma(lib, "UxTheme.lib");

extern(Windows) nothrow {
    int GetScaleFactorForDevice(int);
}


package ApplicationData appData;
package EventArgs GEA;
package wstring formClass = "Wings_Form_in_D";
package wstring mowClass = "Wings_MsgForm_in_D";

static this() 
{    
    ptf("Application started", 0);
    appData = new ApplicationData();
    //stdout.setvbuf(0, _IOLBF);
    
}

static ~this()
{    
    ptf("Application closed", 0);    
}

class ApplicationData
{
    import wings.colors;
    import wings.enums;
    import wings.fonts;    

    HWND mainHwnd;
    HWND[] trayHwnds;
    bool isMainLoopOn;
    bool isDtpInit;
    bool isFormInit;
    bool isMowInint;
    wstring className;
    HINSTANCE hInstance;
    HICON appIcon;
    int screenWidth;
    int screenHeight;
    int frmCount;
    int sysDPI;
    int globalHotKeyID;
    double scaleF;
    Color appColor;
    Font appFont;
    INITCOMMONCONTROLSEX iccEx;
    LOGFONTW logfont;

    this()
    {        
        this.hInstance = GetModuleHandleW(null);        
        this.prepareAppIcon();
        this.globalHotKeyID = 100;
        GEA = new EventArgs();
    }

    void initWindowMode()
    {
        // this.className = 
        this.appFont = new Font("Tahoma", 11);
        this.appColor = Color(0xF0F0F0);
        this.screenWidth = GetSystemMetrics(0);
        this.screenHeight = GetSystemMetrics(1);
        this.iccEx.dwSize = INITCOMMONCONTROLSEX.sizeof;
        this.iccEx.dwICC = ICC_STANDARD_CLASSES;
        this.scaleF = cast(double) GetScaleFactorForDevice(0);
        this.regWindowClass();
        this.getSystemDPI();
        InitCommonControlsEx(&this.iccEx);
    }

    void initMowMode() // Init Message-Only window mode.
    {
        import wings.msgform : msgFormWndProc;
        
        WNDCLASSEXW wc;
        wc.lpfnWndProc   = &msgFormWndProc;
        wc.hInstance     = this.hInstance;
        wc.lpszClassName = mowClass.ptr;
        auto x = RegisterClassExW(&wc);
        if (x) this.isMowInint = true;
    }

    void regWindowClass()
    {
        import wings.form : mainWndProc;

        WNDCLASSEXW wcEx;
        wcEx.style         = CS_HREDRAW | CS_VREDRAW  | CS_OWNDC;
        wcEx.lpfnWndProc   = &mainWndProc;
        wcEx.cbClsExtra    = 0;
        wcEx.cbWndExtra    = 0;
        wcEx.hInstance     = this.hInstance;
        wcEx.hIcon         = this.appIcon;//LoadIconW(null, IDI_APPLICATION);
        wcEx.hCursor       = LoadCursorW(null, IDC_ARROW);
        wcEx.hbrBackground = CreateSolidBrush(this.appColor.cref);//COLOR_WINDOW;
        wcEx.lpszMenuName  = null;
        wcEx.lpszClassName = formClass.ptr;
        auto x = RegisterClassExW(&wcEx);
        if (x) this.isFormInit = true;
        // writefln("window register result %d", x);
    }

    void registerMsgOnlyWindow(LPCWSTR clsName, WNDPROC pFunc)
    {
        WNDCLASSEXW wc;
        wc.lpfnWndProc   = pFunc;
        wc.hInstance     = this.hInstance;
        wc.lpszClassName = clsName;
        auto x = RegisterClassExW(&wc);
        // writefln("Message Only window register result %d", x);
    }

    void prepareAppIcon()
    {
        // We need to make sure that the compiler get the icon path
        // regardless of the working directory. 
        import std.path;
        import std.format;
        import std.utf;
        auto modulebase = dirName(__FILE_FULL_PATH__);
        auto icopath = format("%s\\wings_icon.ico", modulebase);
        this.appIcon = LoadImageW(null, icopath.toUTF16z(), IMAGE_ICON, 0, 0, LR_LOADFROMFILE | LR_DEFAULTSIZE);
    }

    void removeTrayHwnd(HWND item) {
        import std.algorithm.mutation: remove;
        ulong tindex;
        bool found = false;
        foreach (index, hwnd; this.trayHwnds) {
            if (hwnd == item) {
                tindex = index;
                found = true;
                break;
            }
        }
        if (found) {
            this.trayHwnds = this.trayHwnds.remove(tindex);
            this.trayHwnds.assumeSafeAppend();
        }
    }

    void getSystemDPI()
    {
        HDC hdc = GetDC(null);
        scope(exit) ReleaseDC(null, hdc);
        this.sysDPI = GetDeviceCaps(hdc, LOGPIXELSY);        
    }

    void finalize()
    {
        DestroyIcon(appData.appIcon);
        if (this.trayHwnds.length) {
            foreach (hwnd; this.trayHwnds) {
                if (IsWindow(hwnd)) DestroyWindow(hwnd);
            }            
        }
        // writeln("App Icon destroyed in appdata finalize");
    }

    void mainLoop()
    {
        import wings.commons: CM_CMENU_DESTROY;
        
        this.isMainLoopOn = true;
        scope(exit) this.finalize();
        MSG uMsg;
        while (GetMessage(&uMsg, null, 0, 0) != 0) {
            TranslateMessage(&uMsg);
            DispatchMessage(&uMsg);
        }
        // writeln("Main loop returned");
                
    }

    //~this()
    //{
    //    DestroyIcon(this.appIcon);
    //    writeln("App Icon destroyed");
    //}
}

