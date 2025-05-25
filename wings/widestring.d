// Created on 25-May-25 12:00

module wings.widestring;

import core.sys.windows.windows;
import std.stdio;


class WideString {
    import wings.controls: finalProperty;
    
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

    static void fillBuffer(WCHAR* buffer, string txt) {
        int tlen = cast(int)txt.length;
        int slen = MultiByteToWideChar(CP_UTF8, 0, txt.ptr, tlen, null, 0);
        if (slen) {
            MultiByteToWideChar(CP_UTF8, 0, txt.ptr, tlen, buffer, slen);
        }
        buffer[slen] = 0;
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