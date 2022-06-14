module wings.fonts;

private import core.sys.windows.windows ;
private import wings.enums : FontWeight;

private import std.utf;
//private import wings.commons : print;
//int num = 1 ;

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
        this.mName = fName ;
        this.mSize = fSize ;
        this.mWeightIntern = cast(int) fWeight;   
        this.mWeight = fWeight ;
        this.mItalis = fItalics ;
        this.mUnderLine = fUnderline ;                 
    } 

    
    final void createFontHandle(HWND wHandle = null) {        
        import wings.wingdi : CreateFont;
        import wings.commons : toDWString;             

        HDC dcHandle = GetDC(wHandle);
        immutable int iHeight = MulDiv(this.size, GetDeviceCaps(dcHandle, LOGPIXELSY), 72) ;
        ReleaseDC(wHandle, dcHandle);
        //print("font name", this.mName); 
        this.mHandle = CreateFont(iHeight, 0, 0, 0, this.mWeightIntern, DWORD(this.mItalis),
                            DWORD(this.mUnderLine), DWORD(false), DWORD(1),
                            OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                            DEFAULT_QUALITY, DEFAULT_PITCH, 
                            this.mName.toUTF16z()); 
        this.mIsCreated = true;       
    }
    private :
        string mName;
        int mSize;
        int mWeightIntern;
        FontWeight mWeight;
        bool mUnderLine;
        bool mItalis;
        bool mIsCreated;
        HFONT mHandle;

}


