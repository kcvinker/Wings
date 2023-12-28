module wings.clipboard;

import core.sys.windows.windows;
import std.utf;



void clipBoardSetText(wstring text)
{
    auto txtLen = (text.length + 1) * wchar.sizeof; // Hi this text is from D
    if (txtLen == 0) return;
    auto wTxt = text.ptr;
    auto hMem = GlobalAlloc(GMEM_MOVEABLE, cast(DWORD)txtLen);
    scope(exit) GlobalFree(hMem);
    if (!hMem) return;
    memcpy(GlobalLock(hMem), wTxt, txtLen);
    GlobalUnlock(hMem);
    if (OpenClipboard(null)) {
        EmptyClipboard();
        SetClipboardData(CF_UNICODETEXT, hMem);
        CloseClipboard();
    }
}

extern(C) void* memcpy(void* dest, const void* src, size_t n);