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


//===============================WideString=========================

class WideString {
    this(string txt) {
        this.mInpLen = cast(int)txt.length;
        this.mInpStr = txt;
        if (this.mInpLen) {
            this.convertToWstring();
        } else {
            writeln("Can't create WideString, txt is empty");
        }
    }

    this(WideString src) {
        this.copyFrom(src);
    }

    void copyFrom(WideString src) {
        this.mInpLen = cast(int)src.inputLen;
        this.mInpStr = src.inputStr;
        this.mBytes = src.bytes;
        this.mWlen = src.mWlen;
        if (this.mInpLen < src.inputLen) {
            this.mData = new wchar[](this.mWlen + 1);
        }
        this.mData = src.data;
    }

    void updateBuffer(string txt) {
        this.mInpStr = txt;
        int slen = MultiByteToWideChar(CP_UTF8, 0, this.mInpStr.ptr, this.mInpLen, null, 0);
        if (slen) {
            if (slen > this.mWlen) {
                this.mBytes = (slen + 1) * 2;
                this.mWlen = slen;
                this.mData.length = slen + 1;
            }
            MultiByteToWideChar(CP_UTF8, 0, this.mInpStr.ptr, 
                                    this.mInpLen, this.mData.ptr, slen);
        }
    }

    mixin finalProperty!("inputLen", this.mInpLen);
    mixin finalProperty!("inputStr", this.mInpStr);
    mixin finalProperty!("bytes", this.mBytes);
    mixin finalProperty!("data", this.mData);
    final const(wchar)* constPtr() {return cast(const(wchar)*)(this.mData.ptr);}
    final wchar* ptr() {return this.mData.ptr;}

    private:
        wchar[] mData;
        int mInpLen;
        int mBytes;
        int mWlen;
        string mInpStr;


        void convertToWstring() {
            int slen = MultiByteToWideChar(CP_UTF8, 0, this.mInpStr.ptr, 
                                                this.mInpLen, null, 0);
            if (slen) {
                this.mBytes = (slen + 1) * 2;
                this.mData = new wchar[](slen + 1);
                MultiByteToWideChar(CP_UTF8, 0, this.mInpStr.ptr, 
                                    this.mInpLen, this.mData.ptr, slen);
                this.mData[slen] = 0;
                this.mWlen = slen;
            }
        }

}
