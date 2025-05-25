// Created on 12-May-2025 17:40
module wings.graphics;

import wings.d_essentials;
import wings.wings_essentials;
import std.stdio;


class Graphics {
    
    this(HWND hw) {
        this._hdc = GetDC(hw);
        this._freeDC = true;
        this._hwnd = hw;
    }

    this(WPARAM wp) {
        this._hdc = cast(HDC)(wp);        
    }

    ~this() {
        if (this._freeDC) {
            ReleaseDC(this._hwnd, this._hdc);
        }
    }

    static SIZE getTextSize(Control pc) {
        HDC dc = GetDC(pc.mHandle);
        scope(exit) ReleaseDC(pc.mHandle, dc);
        SIZE sz;    
        SelectObject(dc, pc.mFont.mHandle);
        GetTextExtentPoint32(dc, pc.mWtext.constPtr, pc.mWtext.inputLen, &sz);  
        return sz;      
    }

    void drawHLine(HPEN mPen, int sx, int y, int ex) {
        SelectObject(this._hdc, mPen);
        MoveToEx(this._hdc, sx, y, null);
        LineTo(this._hdc, ex, y);
    }

    void drawText(Control pc, int x, int y) {
        SetBkMode(this._hdc, 1);
        SelectObject(this._hdc, pc.font.mHandle);
        SetTextColor(this._hdc, pc.mForeColor.cref);
        TextOut(this._hdc, x, y, pc.mWtext.constPtr, pc.mWtext.inputLen);
    }
    

    private:
        HWND _hwnd;
        HDC _hdc;
        bool _freeDC;
}



