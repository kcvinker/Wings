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
        GetTextExtentPoint32(dc, pc.wtext.constPtr, pc.wtext.inputLen, &sz);  
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
        TextOut(this._hdc, x, y, pc.wtext.constPtr, pc.wtext.inputLen);
    }
    

    private:
        HWND _hwnd;
        HDC _hdc;
        bool _freeDC;
}


//===============================WideString=========================

class WideString {
    this(string txt) {
        this._inputLen = cast(int)txt.length;
        this._inputStr = txt;
        if (this._inputLen) {
            this.convertToWstring();
        } else {
            writeln("Can't create WideString, txt is empty");
        }
    }

    this(WideString src) {
        this.copyFrom(src);
    }

    void copyFrom(WideString src) {
        this._inputLen = cast(int)src.inputLen;
        this._inputStr = src.inputStr;
        this._bytes = src.bytes;
        if (this._inputLen < src.inputLen) {
            this._data = new wchar[](this._bytes);
        }
        this._data = src.data;
    }

    mixin finalProperty!("inputLen", this._inputLen);
    mixin finalProperty!("inputStr", this._inputStr);
    mixin finalProperty!("bytes", this._bytes);
    mixin finalProperty!("data", this._data);
    final const(wchar)* constPtr() {return cast(const(wchar)*)(this._data.ptr);}
    final wchar* ptr() {return this._data.ptr;}

    private:
        wchar[] _data;
        int _inputLen;
        int _bytes;
        string _inputStr;


        void convertToWstring() {
            int slen = MultiByteToWideChar(CP_UTF8, 0, this._inputStr.ptr, 
                                                this._inputLen, null, 0);
            if (slen) {
                this._bytes = (slen + 1) * 2;
                this._data = new wchar[](this._bytes);
                MultiByteToWideChar(CP_UTF8, 0, this._inputStr.ptr, 
                                    this._inputLen, this._data.ptr, slen);
                this._data[slen] = 0;
            }
        }

}
