module winglib.fonts;

private import core.sys.windows.windows ;
private import std.utf;


class Font {
    
    string  name;
    int     size;
    bool    bold;
    bool    underline;
    bool    italics;
    int     fontWeight;
    HFONT   fontHandle ;

    this(string fName, int fSize, bool fBold = false, bool fItalics = false, bool fUnderline = false) {
        this.name = fName ;
        this.size = fSize ;
        this.bold = fBold ;
        this.italics = fItalics ;
        this.underline = fUnderline ;
        this.fontWeight = fBold ? 600 : 400 ;            
    } 

    
    void createFontHandle(HWND wHandle = null) {        
        import winglib.wingdi : CreateFont;
        import winglib.commons : toDWString;             

        HDC dcHandle = GetDC(wHandle);
        immutable int iHeight = MulDiv(this.size, GetDeviceCaps(dcHandle, LOGPIXELSY), 72) ;
        ReleaseDC(wHandle, dcHandle);

        this.fontHandle = CreateFont(iHeight, 0, 0, 0, this.fontWeight, DWORD(this.italics),
                            DWORD(this.underline), DWORD(false), DWORD(1),
                            OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                            DEFAULT_QUALITY, DEFAULT_PITCH, 
                            this.name.toUTF16z);        
    }
}


