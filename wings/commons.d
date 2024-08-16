module wings.commons;

import std.stdio;
import std.conv;
import std.utf;
import core.sys.windows.windows;
import core.sys.windows.commctrl;
import wings.controls;
import wings.colors;
import wings.enums;
import wings.fonts;
import wings.events;

package enum uint gBkColor = 0xF0F0F0; // 0xf5f5f5; // Global Back color for window
enum string mnf1 = "\"/manifestdependency:type='win32' name='Microsoft.Windows.Common-Controls' ";
enum string mnf2 = "version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'\"";
alias zstring = const(wchar)*; /// Alias for Const(wchar)*. A null terminated string
alias  HTHEME = HANDLE;
enum WINDOWTHEMEATTRIBUTETYPE : int { WTA_NONCLIENT = 1 }
extern (Windows) nothrow @nogc {
    HTHEME OpenThemeData(HWND, LPCWSTR);
    HRESULT DrawThemeEdge(HTHEME, HDC, int, int, LPRECT, UINT, UINT, LPRECT);
    HRESULT DrawThemeBackground(HTHEME, HDC, int, int, LPRECT, LPRECT);
    HRESULT SetWindowThemeAttribute(HWND, WINDOWTHEMEATTRIBUTETYPE, PVOID, DWORD);
    HRESULT CloseThemeData(HTHEME);
}

//pragma(linkerDirective, mnf1 ~ mnf2) // run this if you want to create a manifest file

//bool isReleaseVersion = false;

// We need this class to hold all the info we need right...
// befre we create our first window. And we need those info...
// will be accesible from all our winodows. So it will be...
// a global variable. Thus an instance of this class will be global.
package {
    alias intArray = int[];
    alias wsArray = wstring[];

    

    union StringOrInt
    {
        string svalue;
        int ivalue;
    }

    struct ColumnResult
    {
        bool isString;
        StringOrInt value;
    }

    ColumnResult getIntOrString(T)(T arg)
    {
        ColumnResult cres;
        static if (is(typeof(arg) == int)) {
            cres.value.ivalue = arg;
            cres.isString = false;
        } else static if (is(typeof(arg) == double)) {
           cres.isString = true;
           cres.svalue = arg;
        }
        return cres;
    }


    
    //alias Wstring = const(wchar)*;
    enum uint defBackColor = 0xFFFFFF;
    enum uint defForeColor = 0x000000;

    struct Area { int width, height; }


    // We need to hold the sub class info of a control.
    // Because, when a control will be destroyed, we need..
    // to remove sub classing.
    //struct SubClassData {SUBCLASSPROC fnPtr; int clsId;}

    // Form & Button are the control which supports gradient back colors.
    // So this struct will be helpful to store the required info.
    struct GradientColor
    {
        Color color1, color2;
        this(uint c1, uint c2)
        {
            this.color1 = Color(c1);
            this.color2 = Color(c2);
        }
    }



    int xFromLparam(LPARAM lpm){ return cast(int) (cast(short) LOWORD(lpm));}
    int yFromLparam(LPARAM lpm){ return cast(int) (cast(short) HIWORD(lpm));}
    auto getXFromLp(LPARAM lp) {return cast(int) cast(short) LOWORD(lp);}
    auto getYFromLp(LPARAM lp) {return cast(int) cast(short) HIWORD(lp);}
    auto getNmcdPtr(LPARAM lp) {return cast(NMCUSTOMDRAW*) lp;}
    POINT getMousePos(LPARAM lpm) {return POINT(cast(int) (cast(short) LOWORD(lpm)), cast(int) (cast(short) HIWORD(lpm)));}

    enum trueLresult = cast(LRESULT) true;
    enum falseLresult = cast(LRESULT) false;
    LRESULT toLresult(HBRUSH hbr) {return cast(LRESULT) hbr;}

    RECT adjustRect(RECT rc, int leftTop, int rightBottom)
    {
        RECT rct;
        rct.left = rc.left + leftTop;
        rct.top = rc.top + leftTop;
        rct.right = rc.right + rightBottom;
        rct.bottom = rc.bottom + rightBottom;
        return rct;
    }

    void adjustRect(RECT* rc, int leftTop, int rightBottom)
    {
        rc.left = rc.left + leftTop;
        rc.top = rc.top + leftTop;
        rc.right = rc.right + rightBottom;
        rc.bottom = rc.bottom + rightBottom;
    }





    T getControl(T)(DWORD_PTR refData){ return cast(T) (cast(void*) refData);}



    Control toControl(DWORD_PTR refData) { return cast(Control) (cast(void*) refData);}

    /// A wrapper for SendMessage function.
    public void sendMsg(T, U)(HWND hw, UINT msg, T wPm, U lPm)
    {
        SendMessage(hw, msg, cast(WPARAM) wPm, cast(LPARAM) lPm);
    }

    RECT copyRect(const RECT rc)
    {
        RECT nr;
        nr.top = rc.top;
        nr.bottom = rc.bottom;
        nr.right = rc.right;
        nr.left = rc.left;
        return nr;
    }

    /* Sometimes we need to allow user to enter data of any type into a function.
        In such situations, we need to make a string from user input.
        But if that value already a string, then no need to convert that to a string.
        This function does that check and returns a string. */
    wstring toString(T)(T value)
    {
        wstring result;
        static if (is(T == wstring)) {
            result = value;
        } else {
            result = value.to!wstring;
        }
        return result;
    }

    string makeString(T)(T item)
    {
        static if (is(T == string)) return item;
        return to!string(item);
    }

    void printWinMsg(uint msg)
    {
        debug {
            import wings.message_map;
            auto mm = cast(msgMap) msg;
            print("Message", mm);
        }

    }

    // Message Constants - Wing's own messages
        enum uint CM_LEFTCLICK = 9000;
        enum uint CM_RIGHTCLICK = 9001;
        enum uint CM_NOTIFY = 9002;
        enum uint CM_CTLCOMMAND = 9003;
        enum uint CM_COLOR_EDIT = 9004;
        enum uint CM_COLOR_STATIC = 9005;
        enum uint CM_COLOR_CMB_LIST = 9006;
        enum uint CM_COMBOTBCOLOR = 9007;
        enum uint CM_TBTXTCHANGED = 9008;
        enum uint CM_HSCROLL = 9009;
        enum uint CM_VSCROLL = 9010;
        enum uint CM_BUDDY_RESIZE = 9011;
        enum uint CM_MENU_ADDED = 9012;
        enum uint CM_WIN_THREAD_MSG = WM_USER + 5;




} // End of package block



HWND getActiveWindow() {return GetActiveWindow();}
void setActiveWindow(HWND wind) {SetForegroundWindow(wind);}



POINT getMousePoints()
{
    auto value = GetMessagePos();
    auto x = cast(int) (cast(short) LOWORD(value));
    auto y = cast(int) (cast(short) HIWORD(value));
    return POINT(x, y);
}

string getCurrentExeFullName()
{
    wchar[MAX_PATH] buffer;
    auto ret = GetModuleFileNameW(null, buffer.ptr, MAX_PATH);
    if (ret > 0) return buffer[0..ret].to!string;
    return "";
}

string getCurrentDirectory()
{
    wchar[MAX_PATH] buffer;
    auto ret = GetCurrentDirectoryW( MAX_PATH, buffer.ptr);
    if (ret > 0) return buffer[0..ret].to!string;
    return "";
}


/// Converts D string into wchar*
wchar* toWchrPtr(string value){ return toUTFz!(wchar*)(value);}

/// Converts D string into Const(wchar)*
//auto toDWString(S)(S s) { return toUTFz!(const(wchar)*)(s); }


///


void printRect(const RECT rc, string msg = "rc values")
{
    writeln(msg);
    writefln("Left: %d, Top: %d, Right: %d, Bottom: %d", rc.left, rc.top, rc.right, rc.bottom);
    writeln("-------------------------------------------------");
}

void printRect(const RECT* rc)
{
    writefln("Left - %d", rc.left);
    writefln("Top - %d", rc.top);
    writefln("Right - %d", rc.right);
    writefln("Bottom - %d", rc.bottom);
    writeln("-------------------------------------------------");
}

void print(T)(string msg, T obj)
{
    debug{
        import std.stdio;
        static x = 1;
        writefln("[%d]%s - %s", x, msg, obj);
        ++x;
    }
}

void print(T)(T value)
{
    debug{
        import std.stdio;
        static x = 1;
        writefln("[%d] %s", x, value);
        ++x;
    }

}
void print(T)(string msg, T value1, T value2)
{
    debug{
        import std.stdio;
        static x = 1;
        writefln("[%d] %s - %s,  - %s", x, msg, value1, value2);
        // writeln("----------------------------------------------------------------");
        ++x;
    }
}

void printf(T...)(string fmt, T values)
{
    debug{
        import std.stdio;
        writefln(fmt, values);
    }

}


struct Dpoint{ int x; int y;}
struct Size
{
    int width;
    int height;
    bool valueReady() {return (this.width > -1 && this.height > -1) ? true : false;}
}

// struct SubClassDataOld {
//     HWND parent;
//     HWND controlHandle;
//     SUBCLASSPROC controlWndProc;
//     int subClassId;
// }

void drawVLine(HDC hdc, int x, int y, int endp, COLORREF clrref, int penWid = 1)
{
    auto pen = CreatePen(PS_SOLID, penWid, clrref);
    MoveToEx(hdc, x, y, null);
    SelectObject(hdc, pen);
    LineTo(hdc, x, endp);
}



int arraySearch(t, u)(t[] aArray, u item )
{
    for (int i = 0; i < aArray.length; ++i) {
        if (aArray[i] == item) return i;
    }
    return -1;
}

mixin template EnableWindowsSubSystem(  )
{
    debug{}else {
        //enum string mnf1 = "\"/manifestdependency:type='Win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' ";
        //enum string mnf2 = "processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'\"";
        //enum string manifest = mnf1 ~ mnf2;
        pragma(linkerDirective, "/subsystem:windows");
        pragma(linkerDirective, "/entry:mainCRTStartup");
    }
}

// template RaiseEvent(alias obj, alias eventName) {
//     auto ea = new EventArgs();
//     obj.eventName(obj, ea);
// }



// Wing's own messages

void sendThreadMsg(int winhwnd, WPARAM wpm, LPARAM lpm)
{
    SendNotifyMessage(cast(HWND)winhwnd, CM_WIN_THREAD_MSG, wpm, lpm );
}





