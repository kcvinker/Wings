
module wings.gradient;

import core.sys.windows.windows ;
import std.stdio ;

import wings.colors ;
import wings.enums ;
import wings.commons ;

struct Gradient {
	RgbColor clr1;
	RgbColor clr2 ;    
	GradientStyle orientation ;    

	this(uint c1, uint c2, GradientStyle orient) {
		this.clr1 = RgbColor(c1) ;
		this.clr2 = RgbColor(c2) ;
		this.orientation = orient ;
	}

    this(RgbColor c1, RgbColor c2, GradientStyle orient) {
        this.clr1 = c1 ;
        this.clr2 = c2 ;
        this.orientation = orient ;
    }

    final Gradient changeColors(double value) const {
        auto c1 = this.clr1.changeColor(value) ;
        auto c2 = this.clr2.changeColor(value) ;
        Gradient gd = Gradient(c1, c2, this.orientation) ;        
        return gd ;
    }
}

package HBRUSH createGradientBrush(HDC dc, RECT* rct, Gradient gd ) {        
    HBRUSH tBrush ;
    HDC memHDC = CreateCompatibleDC(dc) ;
    HBITMAP hBmp = CreateCompatibleBitmap(dc, rct.right, rct.bottom) ;
    const int loopEnd = gd.orientation == GradientStyle.topToBottom ? rct.bottom : rct.right ;
    scope(exit) {
        DeleteDC(memHDC) ;
        DeleteObject(tBrush) ;
        DeleteObject(hBmp) ;
    }    
    
    SelectObject(memHDC, hBmp) ; 
    for (int i = 0; i < loopEnd; i++) {
        RECT tRct ; 
        uint r, g, b ;

        r = gd.clr1.red + (i * cast(int)(gd.clr2.red - gd.clr1.red) / loopEnd) ;
        g = gd.clr1.green + (i * cast(int)(gd.clr2.green - gd.clr1.green) / loopEnd) ;
        b = gd.clr1.blue + (i * cast(int)(gd.clr2.blue - gd.clr1.blue) / loopEnd) ; 
     
        
        tBrush = CreateSolidBrush(getClrRef(r, g, b)) ;
        scope(exit) DeleteObject(tBrush) ; 

        tRct.left = gd.orientation == GradientStyle.topToBottom ? 0 : i ;
        tRct.top =  gd.orientation == GradientStyle.topToBottom ? i : 0 ;
        tRct.right = gd.orientation == GradientStyle.topToBottom ? rct.right : i + 1 ;
        tRct.bottom = gd.orientation == GradientStyle.topToBottom ? i + 1 : loopEnd ;
        
        FillRect(memHDC, &tRct, tBrush) ;              
    }

    auto grBrush = CreatePatternBrush(hBmp) ;        
    return grBrush ;
}