module wings.fonts;

import core.sys.windows.windows;
import wings.enums : FontWeight;

import std.utf;
import std.conv;
import std.stdio;

import wings.commons : print;
import wings.widestring : WideString;

//int num = 1;

class Font {
    import wings.application: appData;
    
    final string name() {return this.mName;}
    final int size() {return this.mSize;}
    final bool underline() {return this.mUnderLine;}
    final bool italics() {return this.mItalis;}
    final FontWeight weight() {return this.mWeight;}
    final HFONT handle() {return this.mHandle;}
    final bool isCreated() {return this.mIsCreated;}

    this(   string fName, int fSize,
            FontWeight fWeight = FontWeight.normal,
            bool fItalics = false, bool fUnderline = false)
    {
        this.mName = fName;
        this.mSize = fSize;
        this.mWeightIntern = cast(int) fWeight;
        this.mWeight = fWeight;
        this.mItalis = fItalics;
        this.mUnderLine = fUnderline;
    }

    this(bool createNow, string fName, int fSize,
            FontWeight fWeight = FontWeight.normal,
            bool fItalics = false, bool fUnderline = false ) {

        this(fName, fSize, fWeight, fItalics, fUnderline);
        if (createNow) this.createFontHandle();
    }

    this(Font src, string func = __FILE__) {
        this.copyFrom(src);
        this.mFunc = func;
    }

    ~this()
    {
        //import std.stdio;
        if (this.mHandle) DeleteObject(this.mHandle);
        // print("Font handle destroyed for", this.mFunc);
    }

    void createFontHandle(bool formFont = false) {
        double scale = appData.scaleF / 100;
        auto fsiz = cast(int)(scale * cast(double)this.size);  
        int iHeight = -MulDiv(fsiz , appData.sysDPI, 72); 
        LOGFONTW lf = LOGFONTW(); 
        LOGFONTW* plf;
        plf = formFont ? &appData.logfont : &lf;
        WideString.fillBuffer(&plf.lfFaceName[0], this.mName);
        plf.lfItalic = this.mItalis;
        plf.lfUnderline = this.mUnderLine;        
        plf.lfHeight = iHeight;
        plf.lfWeight = this.mWeightIntern;
        plf.lfCharSet = DEFAULT_CHARSET;
        plf.lfOutPrecision = OUT_STRING_PRECIS;
        plf.lfClipPrecision = CLIP_DEFAULT_PRECIS;
        plf.lfQuality = DEFAULT_QUALITY;
        plf.lfPitchAndFamily = 1;
        this.mHandle = CreateFontIndirectW(plf);
        this.mIsCreated = true;
    }

    void cloneParentHandle(HFONT pHandle) {
        if (pHandle) {
            LOGFONTW lf;
            if (GetObjectW(pHandle, LOGFONTW.sizeof, cast(LPVOID)&lf)) {
                this.mHandle = CreateFontIndirectW(&lf);
            }            
        } else {
            this.mHandle = CreateFontIndirectW(&appData.logfont);
        }
    }


    final void copyFrom(Font src) {
        this.mName = src.mName;
        this.mSize = src.mSize;
        this.mWeightIntern = src.mWeightIntern;
        this.mWeight = src.mWeight;
        this.mItalis = src.mItalis;
        this.mUnderLine = src.mUnderLine;
        if (src.mHandle) this.createFontHandle();
    }

    final void setHandle(void* hfont) {
        this.mHandle = cast(HFONT) hfont;
        this.mIsCreated = true;
    }

    final void setCreated(bool value) {
        this.mIsCreated = value;
    }



    package:
        HFONT mHandle;
        //WideString mWtext;
        string mFunc;
        string mName;
        int mSize;
        int mWeightIntern;
        FontWeight mWeight;
        bool mUnderLine;
        bool mItalis;
        bool mIsCreated;


}

//void testCopy(WCHAR* buffer, string txt) {
//    int tlen = cast(int)txt.length;
//    int slen = MultiByteToWideChar(CP_UTF8, 0, txt.ptr, tlen, null, 0);
//    if (slen) {
//        MultiByteToWideChar(CP_UTF8, 0, txt.ptr, tlen, buffer, slen);
//    }
//    buffer[slen] = 0;
//} 
