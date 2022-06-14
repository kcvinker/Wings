module wings.commons;

import std.stdio ;
import std.conv;
private import std.utf;
private import core.sys.windows.windows;
private import core.sys.windows.commctrl;
private import wings.controls;
private import wings.colors;
private import wings.enums;
private import wings.fonts;



// We need this class to hold all the info we need right...
// befre we create our first window. And we need those info...
// will be accesible from all our winodows. So it will be...
// a global variable. Thus an instance of this class will be global.
package {
    class ApplicationData {
        HWND mainWinHandle;
        bool isMainLoopOn;
        bool isDtpInit ;
        string className;
        static HINSTANCE hInstance;
        int screenWidth;
        int screenHeight;
        int windowCount;
        //WindowState winState;
        Font mainFont ;
        INITCOMMONCONTROLSEX iccEx;

        this(string fontName, int fontSize, FontWeight fw = FontWeight.normal) {
            this.className = "Wing window - created in D";
            this.mainFont = new Font(fontName, fontSize, fw) ;
            this.hInstance = GetModuleHandleW(null) ;
            this.screenWidth = GetSystemMetrics(0);
            this.screenHeight = GetSystemMetrics(1);
            this.iccEx.dwSize = INITCOMMONCONTROLSEX.sizeof;
            this.iccEx.dwICC = ICC_STANDARD_CLASSES ;
            InitCommonControlsEx(&this.iccEx) ;
        }
    }


    ApplicationData appData ;
    alias Wstring = const(wchar)* ; 
    enum uint defBackColor = 0xFFFFFF ;
    enum uint defForeColor = 0x000000 ;

    struct Area { int width, height; }
    

    // We need to hold the sub class info of a control.
    // Because, when a control will be destroyed, we need..
    // to remove sub classing. 
    //struct SubClassData {SUBCLASSPROC fnPtr ; int clsId ;}

    // Window & Button are the control which supports gradient back colors.
    // So this struct will be helpful to store the required info.
    struct GradientColor {
        RgbColor color1, color2;
        this(uint c1, uint c2) {
            this.color1 = RgbColor(c1);
            this.color2 = RgbColor(c2);
        }
    }

    int xFromLparam(LPARAM lpm){ return cast(int) (cast(short) LOWORD(lpm));}
    int yFromLparam(LPARAM lpm){ return cast(int) (cast(short) HIWORD(lpm));}
    auto getXFromLp(LPARAM lp) {return cast(int) cast(short) LOWORD(lp) ;}
    auto getYFromLp(LPARAM lp) {return cast(int) cast(short) HIWORD(lp) ;}


    T getControl(T)(DWORD_PTR refData){ return cast(T) (cast(void*) refData) ;}

    Control toControl(DWORD_PTR refData) { return cast(Control) (cast(void*) refData);}

    /// A wrapper for SendMessage function.
    public void sendMsg(T, U)(HWND hw, UINT msg, T wPm, U lPm){ 
        SendMessage(hw, msg, cast(WPARAM) wPm, cast(LPARAM) lPm);
    } 

    RECT copyRect(const RECT rc) {
        RECT nr ;
        nr.top = rc.top ;
        nr.bottom = rc.bottom ;
        nr.right = rc.right ;
        nr.left = rc.left ;
        return nr ;
    }

    /* Sometimes we need to allow user to enter data of any type into a function.
        In such situations, we need to make a string from user input.
        But if that value already a string, then no need to convert that to a string.
        This function does that check and returns a string. */
    string toString(T)(T value) {
        string result;
        static if (is(T == string)) 
        {
            result = value ;
        } else {            
            result = value.to!string ;
        }
        return result;
    }

    void printWinMsg(uint msg) {
        import wings.message_map;
        auto mm = cast(msgMap) msg;
        print("Message", mm);
    }

    // Message Constants - Wing's own messages
        enum uint CM_LEFTCLICK = 9000;
        enum uint CM_RIGHTCLICK = 9001;
        enum uint CM_NOTIFY = 9002;
        enum uint CM_CTLCOMMAND = 9003;
        enum uint CM_CTLCOLOR = 9004;
        enum uint CM_COLORSTATIC = 9005;
        enum uint CM_COMBOLBCOLOR = 9006 ;
        enum uint CM_COMBOTBCOLOR = 9007;
        enum uint CM_TBTXTCHANGED = 9008;


}



void msgBox(wstring value) {MessageBoxW(null, value.toDWString, "Wing Message".toDWString, 0 ) ;}
void msgBox(string value) {MessageBoxW(null, value.toDWString, "Wing Message".toDWString, 0 ) ;}




POINT getMousePoints() {
    auto value = GetMessagePos();
    auto x = cast(int) (cast(short) LOWORD(value));
    auto y = cast(int) (cast(short) HIWORD(value));
    return POINT(x, y);
}



/// Converts D string into wchar*
wchar* toWchrPtr(string value){ return toUTFz!(wchar*)(value) ;}

/// Converts D string into Const(wchar)*
auto toDWString(S)(S s) { return toUTFz!(const(wchar)*)(s); }


///


void printRect(const RECT rc) {
    writefln("Left - %d", rc.left);
    writefln("Top - %d", rc.top);
    writefln("Right - %d", rc.right);
    writefln("Bottom - %d", rc.bottom);
    writeln("-------------------------------------------------") ;
}
void printRect(const RECT* rc) {
    writefln("Left - %d", rc.left);
    writefln("Top - %d", rc.top);
    writefln("Right - %d", rc.right);
    writefln("Bottom - %d", rc.bottom);
    writeln("-------------------------------------------------") ;
}

void print(T)(string msg, T obj) {
    import std.stdio; 
    static x = 1 ;
    writefln("[%d]%s - %s", x, msg, obj) ;      
    ++x ;
}

void print(T)(T value) {
    import std.stdio;
    static x = 1;
    writefln("[%d] %s", x, value);
    
}


struct Dpoint{ int x ; int y ;}
struct Size {
    int width ; 
    int height ;
    bool valueReady() {return (this.width > -1 && this.height > -1) ? true : false;}
}

// struct SubClassDataOld {
//     HWND parent;
//     HWND controlHandle;
//     SUBCLASSPROC controlWndProc;
//     int subClassId;
// }



int arraySearch(t, u)(t[] aArray, u item ) {    
    for (int i = 0; i < aArray.length; ++i) {
        if (aArray[i] == item) return i ;         
    }
    return -1;
}
                       


// Wing's own messages




 