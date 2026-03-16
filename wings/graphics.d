// Created on 12-May-2025 17:40
module wings.graphics;

import wings.d_essentials;
import wings.wings_essentials;
import std.stdio;
import wings.gdiplus: GpGraphics;



class Graphics {
    
    this(HWND hw) {
        this.mHdc = GetDC(hw);
        this.mFreeDc = true;
        this.mHwnd = hw;
    }

    this(WPARAM wp) {
        this.mHdc = cast(HDC)(wp);        
    }

    ~this() {
        if (this.mFreeDc) {
            ReleaseDC(this.mHwnd, this.mHdc);
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
        SelectObject(this.mHdc, mPen);
        MoveToEx(this.mHdc, sx, y, null);
        LineTo(this.mHdc, ex, y);
    }

    void drawText(Control pc, int x, int y) {
        SetBkMode(this.mHdc, 1);
        SelectObject(this.mHdc, pc.font.mHandle);
        SetTextColor(this.mHdc, pc.mForeColor.cref);
        TextOut(this.mHdc, x, y, pc.mWtext.constPtr, pc.mWtext.inputLen);
    }
    

    private:
        HWND mHwnd;
        HDC mHdc;
        bool mFreeDc;
        GpGraphics* mGpGraphics;
}



