
module wings.application;

import std.stdio;
import core.sys.windows.windows;
import core.sys.windows.commctrl;

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

static this() 
{
    
    
    writeln("Application started");
    appData = new ApplicationData();
    
}

static ~this()
{
    
    writeln("Application end");
    
}

class ApplicationData
{
    import wings.colors;
    import wings.enums;
    import wings.fonts;
    import wings.form : mainWndProc;
    

    HWND mainHwnd;
    HWND[] trayHwnds;
    bool isMainLoopOn;
    bool isDtpInit;
    wstring className;
    HINSTANCE hInstance;
    HICON appIcon;
    int screenWidth;
    int screenHeight;
    int frmCount;
    int sysDPI;
    double scaleF;
    Color appColor;
    Font appFont;
    INITCOMMONCONTROLSEX iccEx;
    LOGFONTW logfont;

    this()
    {
        this.className = "Wing_window";
        this.appFont = new Font("Tahoma", 11);
        this.appColor = Color(0xF0F0F0);
        this.hInstance = GetModuleHandleW(null);
        this.screenWidth = GetSystemMetrics(0);
        this.screenHeight = GetSystemMetrics(1);
        this.iccEx.dwSize = INITCOMMONCONTROLSEX.sizeof;
        this.iccEx.dwICC = ICC_STANDARD_CLASSES;
        this.scaleF = cast(double) GetScaleFactorForDevice(0);
        this.prepareAppIcon();
        this.regWindowClass();
        this.getSystemDPI();
        InitCommonControlsEx(&this.iccEx);
        GEA = new EventArgs();
    }

    void regWindowClass()
    {
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
        wcEx.lpszClassName = this.className.ptr;
        auto x = RegisterClassExW(&wcEx);
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
        
        foreach (index, hwnd; this.trayHwnds) {
            if (hwnd == item) {
                this.trayHwnds = this.trayHwnds.remove(index);
                this.trayHwnds.assumeSafeAppend();
                break;
            }
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
        MSG uMsg;
        while (GetMessage(&uMsg, null, 0, 0) != 0) {
            TranslateMessage(&uMsg);
            DispatchMessage(&uMsg);
        }
        // writeln("Main loop returned");
        scope(exit) this.finalize();        
    }

    //~this()
    //{
    //    DestroyIcon(this.appIcon);
    //    writeln("App Icon destroyed");
    //}
}

