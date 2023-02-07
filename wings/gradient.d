
module wings.gradient;

import core.sys.windows.windows ;
import std.stdio ;

import wings.colors ;
import wings.enums ;
import wings.commons ;

struct GradColor {
    RgbColor c1;
    RgbColor c2;
}

struct Gradient {
	GradColor gcDef;
	GradColor gcHot ;
    bool rtl;
    // Hbrush defGBrush;
	// Hbrush hotGBrush;
	HPEN defPen;
	HPEN hotPen;
    // HBRUSH frmBrush;
    // HBRUSH hotBrush;

	// this(uint c1, uint c2, GradientStyle orient) {
	// 	this.clr1 = RgbColor(c1) ;
	// 	this.clr2 = RgbColor(c2) ;
	// 	this.orientation = orient ;
	// }

    // this(RgbColor c1, RgbColor c2, GradientStyle orient) {
    //     this.clr1 = c1 ;
    //     this.clr2 = c2 ;
    //     this.orientation = orient ;
    // }

    ~this() {
        // if (this.frmBrush) DeleteObject(this.frmBrush);
        if (this.defPen) DeleteObject(this.defPen);
        if (this.hotPen) DeleteObject(this.hotPen);
        // if (this.hotBrush) DeleteObject(this.hotBrush);
    }

    void setData(uint c1, uint c2, bool r2l = false) {
        this.gcDef.c1 = RgbColor(c1);
        this.gcDef.c2 = RgbColor(c2);
        double hotAdj = this.gcDef.c1.isDark() ? 1.5 : 1.2;
        double hotAdj2 = this.gcDef.c2.isDark() ? 1.5 : 1.2;

        this.gcHot.c1 = this.gcDef.c1.changeShadeRGB(hotAdj);
        this.gcHot.c2 = this.gcDef.c2.changeShadeRGB(hotAdj2);
        RgbColor frmRc = this.gcDef.c1.changeShadeRGB(0.6);
        this.defPen = CreatePen(PS_SOLID, 1, frmRc.cref);
        this.hotPen = CreatePen(PS_SOLID, 1, this.gcHot.c1.makeFrameColor(0.3));
        this.rtl = r2l;
        print("def pen when created ", this.defPen);
        // this.frmBrush = CreateSolidBrush(this.gcDef.c1.makeFrameColor(0.5));
        // this.hotBrush = CreateSolidBrush(this.gcHot.c2.makeFrameColor(0.5));
    }

    // Gradient changeColors(double value) const {
    //     auto c1 = this.clr1.changeColor(value) ;
    //     auto c2 = this.clr2.changeColor(value) ;
    //     Gradient gd = Gradient(c1, c2, this.orientation) ;
    //     return gd ;
    // }
}

package HBRUSH createGradientBrush(HDC dc, RECT rct, RgbColor c1, RgbColor c2, bool t2b = true ) {
    HBRUSH tBrush;
    HDC memHDC = CreateCompatibleDC(dc);
    HBITMAP hBmp = CreateCompatibleBitmap(dc, rct.right, rct.bottom);
    const int loopEnd = t2b ? rct.bottom : rct.right;
    scope(exit) {

        DeleteObject(tBrush);
        DeleteObject(hBmp);
        DeleteDC(memHDC);
    }

    SelectObject(memHDC, hBmp);

    for (int i = 0; i < loopEnd; i++) {
        RECT tRct;
        uint r, g, b;

        r = c1.red + (i * cast(int) (c2.red - c1.red) / loopEnd);
        g = c1.green + (i * cast(int) (c2.green - c1.green) / loopEnd);
        b = c1.blue + (i * cast(int) (c2.blue - c1.blue) / loopEnd);

        tBrush = CreateSolidBrush(getClrRef(r, g, b));
        scope(exit) DeleteObject(tBrush);

        tRct.left = t2b ? 0 : i;
        tRct.top =  t2b ? i : 0 ;
        tRct.right = t2b ? rct.right : i + 1;
        tRct.bottom = t2b ? i + 1 : loopEnd;

        FillRect(memHDC, &tRct, tBrush);
    }

    auto grBrush = CreatePatternBrush(hBmp);
    return grBrush;
}