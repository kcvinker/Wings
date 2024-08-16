module wings.fonts;

import core.sys.windows.windows;
import wings.enums : FontWeight;

import std.utf;
import std.conv;
import wings.commons : print;
//int num = 1;

class Font {
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

    ~this()
    {
        import std.stdio;
        DeleteObject(this.mHandle);
        writeln("Font handle destroyed");
    }

    void createFontHandle(HWND wHandle = null) {
        // import wings.wingdi : CreateFont;
        HDC dcHandle = GetDC(wHandle);
        immutable int iHeight = -MulDiv(this.size, GetDeviceCaps(dcHandle, LOGPIXELSY), 72);
        ReleaseDC(wHandle, dcHandle);
        //print("font name", this.mName);
        // this.mHandle = CreateFont(iHeight, 0, 0, 0, this.mWeightIntern, DWORD(this.mItalis),
        //                     DWORD(this.mUnderLine), DWORD(false), DWORD(1),
        //                     OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        //                     DEFAULT_QUALITY, DEFAULT_PITCH,
        //                     this.mName.ptr);

        // Changed to LOGFONT in 19-01-2023
        LOGFONTW lf = LOGFONTW();
        lf.lfItalic = this.mItalis;
        lf.lfUnderline = this.mUnderLine;
        lf.lfFaceName[0..this.mName.length] = this.mName.toUTF16; // This idea got from AndrejMitrovic's DWinProgramming repo.
        lf.lfHeight = iHeight;
        lf.lfWeight = this.mWeightIntern;
        lf.lfCharSet = DEFAULT_CHARSET;
        lf.lfOutPrecision = OUT_STRING_PRECIS;
        lf.lfClipPrecision = CLIP_DEFAULT_PRECIS;
        lf.lfQuality = DEFAULT_QUALITY;
        lf.lfPitchAndFamily = 1;
        this.mHandle = CreateFontIndirectW(&lf);

        this.mIsCreated = true;
        // print(iHeight);
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

    private :
        string mName;
        int mSize;
        int mWeightIntern;
        FontWeight mWeight;
        bool mUnderLine;
        bool mItalis;
        bool mIsCreated;


}


