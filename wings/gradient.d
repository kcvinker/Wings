
module wings.gradient;

import core.sys.windows.windows;
import std.stdio;

import wings.colors;
import wings.enums;
import wings.commons;

struct GradColor {
    Color c1;
    Color c2;
}

struct Gradient {
	GradColor gcDef;
	GradColor gcHot;
    bool rtl;
    bool isActive;
    int iAdj = 20; // Value to add or subtract to/from RGB value.
	HPEN defPen;
	HPEN hotPen;

    void finalize()
    { // Destructor
        if (this.defPen) DeleteObject(this.defPen);
        if (this.hotPen) DeleteObject(this.hotPen);
        // print("GradDraw resources freed");
    }

    void setData(uint c1, uint c2, bool r2l = false)
    {
        this.gcDef.c1 = Color(c1);
        this.gcDef.c2 = Color(c2);
        // double hadj = this.gcDef.c1.isDark() ? 1.5 : 1.2;
        // double hadj2 = this.gcDef.c2.isDark() ? 1.5 : 1.2;

        this.gcHot.c1 = this.gcDef.c1.changeShadeColorEx(this.iAdj);
        this.gcHot.c2 = this.gcDef.c2.changeShadeColorEx(this.iAdj);
        Color frmRc = this.gcDef.c1.changeShadeColor(0.6);
        this.defPen = CreatePen(PS_SOLID, 1, frmRc.cref);
        this.hotPen = CreatePen(PS_SOLID, 1, this.gcHot.c1.makeFrameColor(0.3));
        this.rtl = r2l;
        this.isActive = true;
    }

    // Gradient changeColors(double value) const {
    //     auto c1 = this.clr1.changeColor(value);
    //     auto c2 = this.clr2.changeColor(value);
    //     Gradient gd = Gradient(c1, c2, this.orientation);
    //     return gd;
    // }
}

package HBRUSH createGradientBrush(HDC dc, RECT rct, Color c1, Color c2, bool t2b = true )
{
    
    HDC memHDC = CreateCompatibleDC(dc);
    HBITMAP hBmp = CreateCompatibleBitmap(dc, rct.right, rct.bottom);
    const int loopEnd = t2b ? rct.bottom : rct.right;
    scope(exit) {
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

        HBRUSH tBrush = CreateSolidBrush(getClrRef(r, g, b));
        scope(exit) DeleteObject(tBrush);

        tRct.left = t2b ? 0 : i;
        tRct.top =  t2b ? i : 0;
        tRct.right = t2b ? rct.right : i + 1;
        tRct.bottom = t2b ? i + 1 : loopEnd;

        FillRect(memHDC, &tRct, tBrush);
        DeleteObject(tBrush);
    }

    auto grBrush = CreatePatternBrush(hBmp);
    return grBrush;
}