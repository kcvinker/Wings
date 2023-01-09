module wings.fonts;

import core.sys.windows.windows ;
import wings.enums : FontWeight;

import std.utf;
import wings.commons : print;
//int num = 1 ;

class Font {    
    final wstring name() {return this.mName;}
    final int size() {return this.mSize;}
    final bool underline() {return this.mUnderLine;}
    final bool italics() {return this.mItalis;}
    final FontWeight weight() {return this.mWeight;}
    final HFONT handle() {return this.mHandle;}
    final bool isCreated() {return this.mIsCreated;}

    this(   wstring fName, int fSize, 
            FontWeight fWeight = FontWeight.normal, 
            bool fItalics = false, bool fUnderline = false) 
    {
        this.mName = fName ;
        this.mSize = fSize ;
        this.mWeightIntern = cast(int) fWeight;   
        this.mWeight = fWeight ;
        this.mItalis = fItalics ;
        this.mUnderLine = fUnderline ;                 
    } 

    this(bool createNow, wstring fName, int fSize, 
            FontWeight fWeight = FontWeight.normal, 
            bool fItalics = false, bool fUnderline = false ) {
        
        this(fName, fSize, fWeight, fItalics, fUnderline);
        if (createNow) this.createFontHandle();
    }
    
    final void createFontHandle(HWND wHandle = null) {        
        import wings.wingdi : CreateFont;
        HDC dcHandle = GetDC(wHandle);
        immutable int iHeight = -MulDiv(this.size, GetDeviceCaps(dcHandle, LOGPIXELSY), 72) ;
        ReleaseDC(wHandle, dcHandle);
        //print("font name", this.mName); 
        this.mHandle = CreateFont(iHeight, 0, 0, 0, this.mWeightIntern, DWORD(this.mItalis),
                            DWORD(this.mUnderLine), DWORD(false), DWORD(1),
                            OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                            DEFAULT_QUALITY, DEFAULT_PITCH, 
                            this.mName.ptr); 
        this.mIsCreated = true;   
        print(iHeight) ;
    }

    final void setHandle(void* hfont) {
        this.mHandle = cast(HFONT) hfont;
        this.mIsCreated = true;
    }

    final void setCreated(bool value) {
        this.mIsCreated = value;
    }

    private :
        wstring mName;
        int mSize;
        int mWeightIntern;
        FontWeight mWeight;
        bool mUnderLine;
        bool mItalis;
        bool mIsCreated;
        HFONT mHandle;

}


