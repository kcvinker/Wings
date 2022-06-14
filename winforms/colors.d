module winglib.colors;

import std.stdio : log = writeln;
import std.stdio ;

private import core.sys.windows.windows ;

/// To hold color value
struct RgbColor {
    uint red;
    uint green ;
    uint blue ;
    float alpha;    

   // this() {}
    this(uint clr) {
        this.red = clr >> 16 ;
        this.green = (clr & 0x00ff00) >> 8;
        this.blue = clr & 0x0000ff ; 
         

    }
    // this(int zero, float a) {        
    //     this.red = zero ;
    //     this.green = zero ;
    //     this.blue = zero ; 
    //     this.alpha = a ;
    // }

    COLORREF clrRef() {return (this.blue << 16) | (this.green << 8) | this.red ;}    

    uint getUint()  {return cast(uint) (this.red << 16) | (this.green << 8) | this.blue ;}

    void printRgb() {
        writefln("Red - %d, Green - %d, Blue - %d", this.red, this.green, this.blue) ;
    }

    void lighter(float al) {
        this.alpha = al ;         
        immutable float bkg = 255 ;
        this.red = cast(uint) ((1 - al) * cast(float) bkg  + al * cast(float) this.red) ;
        this.green = cast(uint) ((1 - al) * cast(float) bkg + al * cast(float) this.green) ;
        this.blue = cast(uint) ((1 - al) * cast(float) bkg  + al * cast(float) this.blue) ;         
    }
    void darker(float al) {
        this.alpha = al ;         
        immutable float bkg = 0 ;
        this.red = cast(uint) ((1 - al) * cast(float) bkg  + al * cast(float) this.red) ;
        this.green = cast(uint) ((1 - al) * cast(float) bkg + al * cast(float) this.green) ;
        this.blue = cast(uint) ((1 - al) * cast(float) bkg  + al * cast(float) this.blue) ;         
    }
        

} // End struct RgbColor

RgbColor getRgbColor(uint value) {
    RgbColor rst ;
    rst.red = value >> 16 ;
    rst.green = (value & 0x00ff00) >> 8;
    rst.blue = value & 0x0000ff ;     
    return rst ;
}

COLORREF getClrRef(uint value )
{
    auto rgbc = getRgbColor(value) ;
    return (rgbc.blue << 16) | (rgbc.green << 8) | rgbc.red ;
}

COLORREF getClrRef(uint r, uint g, uint b ) {return (b << 16) | (g << 8) | r ;}

// COLORREF getClrRefEx(uint value, int alpha )
// {
//     auto immutable rgbc = getRgbColor(value) ;
//     return (alpha << 24) | (rgbc.blue << 16) | (rgbc.green << 8) | rgbc.red ;
// }

void RgbToHsl() {               
     import std.math : isNaN ;
     import std.stdio;
    const RgbColor r1 = getRgbColor(0xff0000) ;
    float min, max, l, s, maxClr, h  ;
    RgbColor emr ;
    emr.red = r1.red / 255 ;
    emr.green = r1.green / 255 ;
    emr.blue = r1.blue / 255 ;

    min = emr.red ;
    max = emr.red ;
    maxClr = 0 ;

    if (emr.green <= min) { min = emr.green ;}
    if (emr.green >= max) { max = emr.green ; maxClr = emr.green ;}

    if (emr.blue <= min) { min = emr.blue ;}
    if (emr.blue >= max) { max = emr.blue ; maxClr = emr.blue ;}

    if (maxClr == 0) { h = (emr.green - emr.blue) / (max - min) ;}
    if (maxClr == 1) { h = 2 + (emr.blue - emr.red) / (max - min) ;}
    if (maxClr == 2) { h = 4 + (emr.red - emr.green) / (max - min) ;}

    if (isNaN!float(h)) { h = 0 ;}
    h = h * 60 ;
    if (h < 0) { h = h + 360 ;}

    l = (min + max) / 2 ;
    if (min == max) {
        s = 0 ;
    }
    else {
       if ( l < 0.5 ){
            s = (max - min) / ( max + min) ;
       }
       else {
            s = (max - min) / (2 - max - min) ;
       }
    }

    //s = s ;
    writeln("h - ", h, " s - ", s, " l - ", l) ;
    writeln(100 * l) ;
 }