module winglib.commons;

import std.stdio ;
private import std.utf;
private import core.sys.windows.windows;
private import core.sys.windows.commctrl;
private import winglib.controls;
private import winglib.colors;



//import winglib.events;


void msgBox(wstring value) {MessageBoxW(null, value.toDWString, "WingLib Message".toDWString, 0 ) ;}
int xFromLparam(LPARAM lpm){ return cast(int) (cast(short) LOWORD(lpm));}
int yFromLparam(LPARAM lpm){ return cast(int) (cast(short) HIWORD(lpm));}

/// Converts D string into wchar*
wchar* toWinStr(string value){ return toUTFz!(wchar*)(value) ;}

/// Converts D string into Const(wchar)*
auto toDWString(S)(S s) { return toUTFz!(const(wchar)*)(s); }

auto  getXFromLp(LPARAM lp) {return cast(int) cast(short) LOWORD(lp) ;}
auto  getYFromLp(LPARAM lp) {return cast(int) cast(short) HIWORD(lp) ;}

///
T getControl(T)(DWORD_PTR refData){ return cast(T) (cast(void*) refData) ;}

Control toControl(DWORD_PTR refData) { return cast(Control) (cast(void*) refData);}

/// A wrapper for SendMessage function.
public void sendMsg(wpT, lpT)(HWND hw, UINT msg, wpT wPm, lpT lPm){ 
    SendMessage(hw, msg, cast(WPARAM) wPm, cast(LPARAM) lPm);
} 

void printRgb(uint clr) {
    RgbColor rr = RgbColor(clr) ;
    writefln("red : ") ;
}

struct Dpoint{ int x ; int y ;}

struct SubClassData {
    HWND parent;
    HWND controlHandle;
    SUBCLASSPROC controlWndProc;
    int subClassId;
}






/* void setControlFont(HWND hwnd, string fName, int fSize) {    
    
    HFONT fHandle = createFontHandle(hwnd, fName, fSize);
    sendMsg(hwnd, WM_SETFONT, fHandle, true);

}
 */
  

 