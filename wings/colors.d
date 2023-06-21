module wings.colors;

import std.stdio : log = writeln;
import std.stdio ;
import std.algorithm ;
import core.stdc.math;

private import core.sys.windows.windows ;



struct Color  // This struct is used to hold the color values for all control's back & fore color.
{
    uint value;
    uint red;
    uint green;
    uint blue;
    COLORREF cref;

    this(uint clr) {
        this.value = clr;
        this.red = clr >> 16 ;
        this.green = (clr & 0x00ff00) >> 8;
        this.blue = clr & 0x0000ff ;
        this.cref = cast(COLORREF) ((this.blue << 16) | (this.green << 8) | this.red);
    }

    this(int red, int green, int blue) {
        this.value = cast(uint) (red << 16) | (green << 8) | blue;
        this.red = red;
        this.green = green;
        this.blue = blue;
        this.cref = cast(COLORREF) ((blue << 16) | (green << 8) | red);
    }

    void opCall(uint clr) {
        this.value = clr;
        this.red = clr >> 16 ;
        this.green = (clr & 0x00ff00) >> 8;
        this.blue = clr & 0x0000ff ;
        this.cref = cast(COLORREF) ((this.blue << 16) | (this.green << 8) | this.red);
    }

    void opCall(int red, int green, int blue) {
        this.value = cast(uint) (red << 16) | (green << 8) | blue;
        this.red = red;
        this.green = green;
        this.blue = blue;
        this.cref = cast(COLORREF) ((blue << 16) | (green << 8) | red);
    }

    void opCall(Color clr) { // Initiate with existing color
        this.value = clr.value;
        this.red = clr.red;
        this.green = clr.green;
        this.blue = clr.blue;
        this.cref = clr.cref;
    }

    void updateColor(uint clr) {
        this.value = clr;
        this.red = clr >> 16;
        this.green = (clr & 0x00ff00) >> 8;
        this.blue = clr & 0x0000ff ;
        this.cref = cast(COLORREF) ((this.blue << 16) | (this.green << 8) | this.red);
    }

    Color changeShade(double changeValue) { // Color.changeShade
        Color clr;
        clr.red = clip(this.red * changeValue) ;
        clr.green = clip(this.green * changeValue);
        clr.blue = clip(this.blue * changeValue) ;
        clr.value = cast(uint) (clr.red << 16) | (clr.green << 8) | clr.blue;
        clr.cref = cast(COLORREF) ((clr.blue << 16) | (clr.green << 8) | clr.red);
        return clr;
    }

    HBRUSH getBrush() {return CreateSolidBrush(this.cref);} // Color.getBrush

    HBRUSH getHotBrush(double adj) { // Color.getHotBrush
        /* Sometimes, we need to use a special color for mouse hover event.
        In such cases, we have already a back color. But we need to make...
        an hbrush with slightly different color. This function create...
        an hbrush for that purpose. It will create a different color with...
        given value 'adj'. Try with a 1.2 */
        auto red = clip(this.red + (adj * 8));
        auto green = clip(this.green + (adj * 16));
        auto blue = clip(this.blue + (adj * 32));
        auto cref = cast(COLORREF) ((blue << 16) | (green << 8) | red);
        return CreateSolidBrush(cref);
    }

    HBRUSH getHotBrushEx(int adj) { // Color.getHotBrush
        /* Sometimes, we need to use a special color for mouse hover event.
        In such cases, we have already a back color. But we need to make...
        an hbrush with slightly different color. This function create...
        an hbrush for that purpose. It will create a different color with...
        given value 'adj'. Try with a 1.2 */
        auto red = clip(this.red + adj);
        auto green = clip(this.green + adj);
        auto blue = clip(this.blue + adj);
        auto cref = cast(COLORREF) ((blue << 16) | (green << 8) | red);
        return CreateSolidBrush(cref);
    }

    HPEN getFramePen(double adj, int pwidth = 1) { // Color.getFramePen
        auto red = clip(this.red + (adj * 8));
        auto green = clip(this.green + (adj * 16));
        auto blue = clip(this.blue + (adj * 32));
        auto cref = cast(COLORREF) ((blue << 16) | (green << 8) | red);
        return CreatePen(PS_SOLID, pwidth, cref);
    }


    int darkRange() { // Color.darkRange
		int x = cast(int)((this.red * 0.2126) + (this.green * 0.7152) + (this.blue * 0.0722));
		return x;
	}

    bool isDark() { // Color.isDark
		int x = cast(int)((this.red * 0.2126) + (this.green * 0.7152) + (this.blue * 0.0722));
		return x < 40;
    }

    COLORREF mouseFocusColor(float adj) {
        auto red = this.red + (adj * (255 - this.red));
        auto green = this.green + (adj * (255 - this.green));
        auto blue = this.blue + (adj * (255 - this.blue));
        uint r = clip(cast(uint)(red));
        uint g = clip(cast(uint)(green));
        uint b = clip(cast(uint)(blue));
        return cast(COLORREF)((b << 16) | (g << 8) | r); // rgb(2, 62, 138), rgb(0, 150, 199)
    }


    COLORREF makeFrameColor(double adj) {
        uint r = clip(cast(uint)(this.red * adj));
        uint g = clip(cast(uint)(this.green * adj));
        uint b = clip(cast(uint)(this.blue * adj));
        return cast(COLORREF)((b << 16) | (g << 8) | r);
    }

    COLORREF makeHotRef(uint adj) {
        auto r = clip(cast(uint) (this.red * (100 + adj) / 100));
        auto g = clip(cast(uint) (this.green * (100 + adj) / 100));
        auto b = clip(cast(uint) (this.blue * (100 + adj) / 100));
        // writefln("red : %s,   r : %s", red, r);
        return cast(COLORREF)((b << 16) | (g << 8) | r);
    }

    Color changeShadeColor(double adj) {
        Color rc;
        rc.red = clip(cast(uint) (cast(double)this.red *  adj) );
        rc.green = clip(cast(uint) (cast(double)this.green * adj));
        rc.blue = clip(cast(uint) (cast(double)this.blue * adj));
        rc.value = cast(uint) (rc.red << 16) | (rc.green << 8) | rc.blue;
        rc.cref = cast(COLORREF) ((rc.blue << 16) | (rc.green << 8) | rc.red) ;
        return rc;
    }

    Color changeShadeColorEx(int change) {
        Color rc;
        rc.red = clip(this.red +  change);
        rc.green = clip(this.green + change);
        rc.blue = clip(this.blue + change);
        rc.value = cast(uint) (rc.red << 16) | (rc.green << 8) | rc.blue;
        rc.cref = cast(COLORREF) ((rc.blue << 16) | (rc.green << 8) | rc.red) ;
        return rc;
    }

} // End Color

HBRUSH makeHBRUSH(uint clr) {
    auto c = Color(clr);
    return CreateSolidBrush(c.cref);
}

int clip(double num) {
    import std.algorithm : clamp;
    import std.math;
    return cast(int) round(clamp(num, 0, 255));
}

COLORREF getClrRef(uint r, uint g, uint b ) {return cast(COLORREF) ((b << 16) | (g << 8) | r) ;}
COLORREF getClrRef(uint clr ) {
    auto r = clr >> 16 ;
    auto g = (clr & 0x00ff00) >> 8;
    auto b = clr & 0x0000ff ;
    return cast(COLORREF) ((b << 16) | (g << 8) | r) ;
}

uint fromRgb(uint red, uint green, uint blue) { return ((red << 16) | (green << 8) | blue) ;}


struct  HSV {
    double hue;
    double saturation;
    double value;

    static HSV fromRGB(uint r, uint g, uint b ) {
        float sr, sg, sb;
        float maxVal = 255.0;
        HSV hsv;
        sr = r / maxVal;
        sg = g / maxVal;
        sb = b / maxVal;

        float cmax = max(sr, sg, sb);
        float cmin = min(sr, sg, sb);
        float diff = cmax - cmin;

        if (cmax == cmin) {
            hsv.hue = 0;
        } else if (cmax == sr) {
            hsv.hue = (60 * ((sg - sb) / diff) + 360) % 360;
        } else if (cmax == sg) {
            hsv.hue = (60 * ((sb - sr) / diff) + 120) % 360;
        } else if (cmax == sb) {
            hsv.hue = (60 * ((sr - sg) / diff) + 240) % 360;
        }
        if (cmax == 0) {
            hsv.saturation = 0;
        } else {
            hsv.saturation = (diff / cmax) * 100;
        }
        hsv.value = fabsf(cmax * 100);
        return hsv;
    }

    // static HSV fromRGB(uint r, uint g, uint b) {
    //     double M = 0.0, m = 0.0, c = 0.0;
    //     HSV hsv;
    //     M = cast(double)max(r, g, b);
    //     m = cast(double)min(r, g, b);
    //     c = M - m;
    //     hsv.value = M;
    //     if (c != 0.0) {
    //         if (M == r) {
    //             hsv.hue = fmod(((g - b) / c), 6.0);
    //         } else if (M == g) {
    //             hsv.hue = (b - r) / c + 2.0;
    //         } else /*if(M==b)*/ {
    //             hsv.hue = (r - g) / c + 4.0;
    //         }
    //         hsv.hue *= 60.0;
    //         hsv.saturation = c / hsv.value;
    //     }
    //     return hsv;
    // }

    // static HSV fromRGB(uint ur, uint ug, uint ub) {
    //     // R, G, B values are divided by 255
    //     // to change the range from 0..255 to 0..1:
    //     float h, s, v;
    //     float r = ur / 255.0;
    //     float g = ug / 255.0;
    //     float b = ub / 255.0;
    //     writefln("Inside func r: %f, g: %f, b: %f", r, g, b);
    //     float cmax = max(r, g, b); // maximum of r, g, b
    //     float cmin = min(r, g, b); // minimum of r, g, b
    //     float diff = cmax-cmin; // diff of cmax and cmin.
    //     if (cmax == cmin)
    //         h = 0;
    //     else if (cmax == r)
    //         h = fmod((60 * ((g - b) / diff) + 360), 360.0);
    //     else if (cmax == g)
    //         h = fmod((60 * ((b - r) / diff) + 120), 360.0);
    //     else if (cmax == b)
    //         h = fmod((60 * ((r - g) / diff) + 240), 360.0);
    //     // if cmax equal zero
    //         if (cmax == 0)
    //             s = 0;
    //         else
    //             s = (diff / cmax) * 100;
    //     // compute v
    //     v = cmax * 100;
    //     // printf("h s v=(%f, %f, %f)
    //     // ", h, s, v );
    //     return HSV(h, s, v);
    // }

    // RgbColor toRGB() {
    //     // convert an HSV value to RGB.
    //     struct tRgb {
    //         double r;
    //         double g;
    //         double b;
    //     }

    //     double c = 0.0, m = 0.0, x = 0.0;
    //     tRgb t;

    //     c = this.value * this.saturation;
    //     x = c * (1.0 - fabs(fmod(this.hue / 60.0, 2) - 1.0));
    //     m = this.value - c;
    //     if (this.hue >= 0.0 && this.hue < 60.0) {
    //         t = tRgb(c + m, x + m, m);

    //     } else if (this.hue >= 60.0 && this.hue < 120.0) {
    //         t = tRgb(x + m, c + m, m);
    //     } else if (this.hue >= 120.0 && this.hue < 180.0) {
    //         t = tRgb(m, c + m, x + m);
    //     } else if (this.hue >= 180.0 && this.hue < 240.0) {
    //         t = tRgb(m, x + m, c + m);
    //     } else if (this.hue >= 240.0 && this.hue < 300.0) {
    //         t = tRgb(x + m, m, c + m);
    //     } else if (this.hue >= 300.0 && this.hue < 360.0) {
    //         t = tRgb(c + m, m, x + m);
    //     } else {
    //         t = tRgb(m, m, m);
    //     }
    //     RgbColor rc;
    //     rc.red = clip(cast(uint)(t.r * 255));
    //     rc.green = clip(cast(uint)(t.g * 255));
    //     rc.blue = clip(cast(uint)(t.b * 255));
    //     // writefln("value : %f", this.value);
    //     return rc;
    // }

    void setValue(int percentage, bool reduce = false) {
        double x = percentage / 100;
        if (reduce) {
            x -= 1;
        } else {
            x += 1;
        }
        this.value = min((this.value * x), 1);
    }
}




// void rgbToHsl() {
//      import std.math : isNaN ;
//      import std.stdio;
//     const RgbColor r1 = getRgbColor(0xff0000) ;
//     float min, max, l, s, maxClr, h  ;
//     RgbColor emr ;
//     emr.red = r1.red / 255 ;
//     emr.green = r1.green / 255 ;
//     emr.blue = r1.blue / 255 ;

//     min = emr.red ;
//     max = emr.red ;
//     maxClr = 0 ;

//     if (emr.green <= min) { min = emr.green ;}
//     if (emr.green >= max) { max = emr.green ; maxClr = emr.green ;}

//     if (emr.blue <= min) { min = emr.blue ;}
//     if (emr.blue >= max) { max = emr.blue ; maxClr = emr.blue ;}

//     if (maxClr == 0) { h = (emr.green - emr.blue) / (max - min) ;}
//     if (maxClr == 1) { h = 2 + (emr.blue - emr.red) / (max - min) ;}
//     if (maxClr == 2) { h = 4 + (emr.red - emr.green) / (max - min) ;}

//     if (isNaN!float(h)) { h = 0 ;}
//     h = h * 60 ;
//     if (h < 0) { h = h + 360 ;}

//     l = (min + max) / 2 ;
//     if (min == max) {
//         s = 0 ;
//     }
//     else {
//        if ( l < 0.5 ){
//             s = (max - min) / ( max + min) ;
//        }
//        else {
//             s = (max - min) / (2 - max - min) ;
//        }
//     }

//     //s = s ;
//     writeln("h - ", h, " s - ", s, " l - ", l) ;
//     writeln(100 * l) ;
// }

// void printRgb(uint clr) {
//     RgbColor rr = RgbColor(clr) ;
//     writefln("red : ") ;
// }

// void pritest(RgbColor rc) {
//     writefln("red: %s, green: %s, blue: %s", rc.red, rc.green, rc.blue);
// }


enum Colors {
    airForceBlue1 = 0x5d8aa8,
    airForceBlue2 = 0x00308f,
    airSuperiorityBlue = 0x72a0c1,
    alabamaCrimson = 0xa32638,
    aliceBlue = 0xf0f8ff,
    alizarinCrimson = 0xe32636,
    alloyOrange = 0xc46210,
    almond = 0xefdecd,
    amaranth = 0xe52b50,
    amber = 0xffbf00,
    amberSeaFace = 0xff7e00,
    americanRose = 0xff033e,
    amethyst = 0x96c000,
    androidGreen = 0xa4c639,
    antiFlashWhite = 0xf2f3f4,
    antiqueBrass = 0xcd9575,
    antiqueFuchsia = 0x915c83,
    antiqueRuby = 0x841b2d,
    antiqueWhite = 0xfaebd7,
    aoEnglish = 0x008000,
    appleGreen = 0x8db600,
    apricot = 0xfbceb1,
    aqua = 0x0ff000,
    aquamarine = 0x7fffd4,
    armyGreen = 0x4b5320,
    arsenic = 0x3b444b,
    arylideYellow = 0xe9d66b,
    ashGrey = 0xb2beb5,
    asparagus = 0x87a96b,
    atomicTangerine = 0xf96000,
    auburn = 0xa52a2a,
    aureolin = 0xfdee00,
    aurometalsaurus = 0x6e7f80,
    avocado = 0x568203,
    azure = 0x007fff,
    azureMistWeb = 0xf0ffff,
    babyBlue = 0x89cff0,
    babyBlueEyes = 0xa1caf1,
    babyPink = 0xf4c2c2,
    ballBlue = 0x21abcd,
    bananaMania = 0xfae7b5,
    bananaYellow = 0xffe135,
    barnRed = 0x7c0a02,
    battleshipGrey = 0x848482,
    bazaar = 0x98777b,
    beauBlue = 0xbcd4e6,
    beaver = 0x9f8170,
    beige = 0xf5f5dc,
    bigDipRuby = 0x9c2542,
    bisque = 0xffe4c4,
    bistre = 0x3d2b1f,
    bittersweet = 0xfe6f5e,
    bitterSweetShimmer = 0xbf4f51,
    black = 0x000000,
    blackBean = 0x3d0c02,
    blackLeatherJacket = 0x253529,
    blackOlive = 0x3b3c36,
    blanchedAlmond = 0xffebcd,
    blastOffBronze = 0xa57164,
    bleuDeFrance = 0x318ce7,
    blizzardBlue = 0xace5ee,
    blond = 0xfaf0be,
    blue = 0x0000ff,
    blueBell = 0xa2a2d0,
    blueCrayola = 0x1f75fe,
    blueGray = 0x69c000,
    blueGreen = 0x0d98ba,
    blueMunsell = 0x0093af,
    blueNcs = 0x0087bd,
    bluePigment = 0x339000,
    blueRyb = 0x0247fe,
    blueSapphire = 0x126180,
    blueViolet = 0x8a2be2,
    blush = 0xde5d83,
    bole = 0x79443b,
    bondiBlue = 0x0095b6,
    bone = 0xe3dac9,
    bostonUniversityRed = 0xc00000,
    bottleGreen = 0x006a4e,
    boysenberry = 0x873260,
    brandeisBlue = 0x0070ff,
    brass = 0xb5a642,
    brickRed = 0xcb4154,
    brightCerulean = 0x1dacd6,
    brightGreen = 0x6f0000,
    brightLavender = 0xbf94e4,
    brightMaroon = 0xc32148,
    brightPink = 0xff007f,
    brightTurquoise = 0x08e8de,
    brightUbe = 0xd19fe8,
    brilliantLavender = 0xf4bbff,
    brilliantRose = 0xff55a3,
    brinkPink = 0xfb607f,
    britishRacingGreen = 0x004225,
    bronze = 0xcd7f32,
    brownTraditional = 0x964b00,
    brownWeb = 0xa52a2a,
    bubbleGum = 0xffc1cc,
    bubbles = 0xe7feff,
    buff = 0xf0dc82,
    bulgarianRose = 0x480607,
    burgundy = 0x800020,
    burlywood = 0xdeb887,
    burntOrange = 0xc50000,
    burntSienna = 0xe97451,
    burntUmber = 0x8a3324,
    byzantine = 0xbd33a4,
    byzantium = 0x702963,
    cadet = 0x536872,
    cadetBlue = 0x5f9ea0,
    cadetGrey = 0x91a3b0,
    cadmiumGreen = 0x006b3c,
    cadmiumOrange = 0xed872d,
    cadmiumRed = 0xe30022,
    cadmiumYellow = 0xfff600,
    cafAuLait = 0xa67b5b,
    cafNoir = 0x4b3621,
    californiaGold = 0xb78727,
    calPolyGreen = 0x1e4d2b,
    cambridgeBlue = 0xa3c1ad,
    camel = 0xc19a6b,
    cameoPink = 0xefbbcc,
    camouflageGreen = 0x78866b,
    canaryYellow = 0xffef00,
    candyAppleRed = 0xff0800,
    candyPink = 0xe4717a,
    capri = 0x00bfff,
    caputMortuum = 0x592720,
    cardinal = 0xc41e3a,
    caribbeanGreen = 0x0c9000,
    carmine = 0x960018,
    carmineMP = 0xd70040,
    carminePink = 0xeb4c42,
    carmineRed = 0xff0038,
    carnationPink = 0xffa6c9,
    carnelian = 0xb31b1b,
    carolinaBlue = 0x99badd,
    carrotOrange = 0xed9121,
    catalinaBlue = 0x062a78,
    ceil = 0x92a1cf,
    celadon = 0xace1af,
    celadonBlue = 0x007ba7,
    celadonGreen = 0x2f847c,
    celesteColour = 0xb2ffff,
    celestialBlue = 0x4997d0,
    cerise = 0xde3163,
    cerisePink = 0xec3b83,
    cerulean = 0x007ba7,
    ceruleanBlue = 0x2a52be,
    ceruleanFrost = 0x6d9bc3,
    cgBlue = 0x007aa5,
    cgRed = 0xe03c31,
    chamoisee = 0xa0785a,
    champagne = 0xfad6a5,
    charcoal = 0x36454f,
    charmPink = 0xe68fac,
    chartreuseTraditional = 0xdfff00,
    chartreuseWeb = 0x7fff00,
    cherry = 0xde3163,
    cherryBlossomPink = 0xffb7c5,
    chestnut = 0xcd5c5c,
    chinaPink = 0xde6fa1,
    chinaRose = 0xa8516e,
    chineseRed = 0xaa381e,
    chocolateTraditional = 0x7b3f00,
    chocolateWeb = 0xd2691e,
    chromeYellow = 0xffa700,
    cinereous = 0x98817b,
    cinnabar = 0xe34234,
    cinnamon = 0xd2691e,
    citrine = 0xe4d00a,
    classicRose = 0xfbcce7,
    cobalt = 0x0047ab,
    cocoaBrown = 0xd2691e,
    coffee = 0x6f4e37,
    columbiaBlue = 0x9bddff,
    congoPink = 0xf88379,
    coolBlack = 0x002e63,
    coolGrey = 0x8c92ac,
    copper = 0xb87333,
    copperCrayola = 0xda8a67,
    copperPenny = 0xad6f69,
    copperRed = 0xcb6d51,
    copperRose = 0x966000,
    coquelicot = 0xff3800,
    coral = 0xff7f50,
    coralPink = 0xf88379,
    coralRed = 0xff4040,
    cordovan = 0x893f45,
    corn = 0xfbec5d,
    cornellRed = 0xb31b1b,
    cornflowerBlue = 0x6495ed,
    cornsilk = 0xfff8dc,
    cosmicLatte = 0xfff8e7,
    cottonCandy = 0xffbcd9,
    cream = 0xfffdd0,
    crimson = 0xdc143c,
    crimsonGlory = 0xbe0032,
    cyan = 0x0ff000,
    cyanProcess = 0x00b7eb,
    daffodil = 0xffff31,
    dandelion = 0xf0e130,
    darkBlue = 0x00008b,
    darkBrown = 0x654321,
    darkByzantium = 0x5d3954,
    darkCandyAppleRed = 0xa40000,
    darkCerulean = 0x08457e,
    darkChestnut = 0x986960,
    darkCoral = 0xcd5b45,
    darkCyan = 0x008b8b,
    darkElectricBlue = 0x536878,
    darkGoldenrod = 0xb8860b,
    darkGray = 0xa9a9a9,
    darkGreen = 0x013220,
    darkImperialBlue = 0x00416a,
    darkJungleGreen = 0x1a2421,
    darkKhaki = 0xbdb76b,
    darkLava = 0x483c32,
    darkLavender = 0x734f96,
    darkMagenta = 0x8b008b,
    darkMidnightBlue = 0x036000,
    darkOliveGreen = 0x556b2f,
    darkOrange = 0xff8c00,
    darkOrchid = 0x9932cc,
    darkPastelBlue = 0x779ecb,
    darkPastelGreen = 0x03c03c,
    darkPastelPurple = 0x966fd6,
    darkPastelRed = 0xc23b22,
    darkPink = 0xe75480,
    darkPowderBlue = 0x039000,
    darkRaspberry = 0x872657,
    darkRed = 0x8b0000,
    darkSalmon = 0xe9967a,
    darkScarlet = 0x560319,
    darkSeaGreen = 0x8fbc8f,
    darkSienna = 0x3c1414,
    darkSlateBlue = 0x483d8b,
    darkSlateGray = 0x2f4f4f,
    darkSpringGreen = 0x177245,
    darkTan = 0x918151,
    darkTangerine = 0xffa812,
    darkTaupe = 0x483c32,
    darkTerraCotta = 0xcc4e5c,
    darkTurquoise = 0x00ced1,
    darkViolet = 0x9400d3,
    darkYellow = 0x9b870c,
    dartmouthGreen = 0x00703c,
    davySGrey = 0x555000,
    debianRed = 0xd70a53,
    deepCarmine = 0xa9203e,
    deepCarminePink = 0xef3038,
    deepCarrotOrange = 0xe9692c,
    deepCerise = 0xda3287,
    deepChampagne = 0xfad6a5,
    deepChestnut = 0xb94e48,
    deepCoffee = 0x704241,
    deepFuchsia = 0xc154c1,
    deepJungleGreen = 0x004b49,
    deepLilac = 0x95b000,
    deepMagenta = 0xc0c000,
    deepPeach = 0xffcba4,
    deepPink = 0xff1493,
    deepRuby = 0x843f5b,
    deepSaffron = 0xf93000,
    deepSkyBlue = 0x00bfff,
    deepTuscanRed = 0x66424d,
    denim = 0x1560bd,
    desert = 0xc19a6b,
    desertSand = 0xedc9af,
    dimGray = 0x696969,
    dodgerBlue = 0x1e90ff,
    dogwoodRose = 0xd71868,
    dollarBill = 0x85bb65,
    drab = 0x967117,
    dukeBlue = 0x00009c,
    earthYellow = 0xe1a95f,
    ebony = 0x555d50,
    ecru = 0xc2b280,
    eggplant = 0x614051,
    eggshell = 0xf0ead6,
    egyptianBlue = 0x1034a6,
    electricBlue = 0x7df9ff,
    electricCrimson = 0xff003f,
    electricCyan = 0x0ff000,
    electricGreen = 0x0f0000,
    electricIndigo = 0x6f00ff,
    electricLavender = 0xf4bbff,
    electricLime = 0xcf0000,
    electricPurple = 0xbf00ff,
    electricUltramarine = 0x3f00ff,
    electricViolet = 0x8f00ff,
    electricYellow = 0xff0000,
    emerald = 0x50c878,
    englishLavender = 0xb48395,
    etonBlue = 0x96c8a2,
    fallow = 0xc19a6b,
    faluRed = 0x801818,
    fandango = 0xb53389,
    fashionFuchsia = 0xf400a1,
    fawn = 0xe5aa70,
    feldgrau = 0x4d5d53,
    fernGreen = 0x4f7942,
    ferrariRed = 0xff2800,
    fieldDrab = 0x6c541e,
    fireEngineRed = 0xce2029,
    firebrick = 0xb22222,
    flame = 0xe25822,
    flamingoPink = 0xfc8eac,
    flavescent = 0xf7e98e,
    flax = 0xeedc82,
    floralWhite = 0xfffaf0,
    fluorescentOrange = 0xffbf00,
    fluorescentPink = 0xff1493,
    fluorescentYellow = 0xcf0000,
    folly = 0xff004f,
    forestGreenTraditional = 0x014421,
    forestGreenWeb = 0x228b22,
    frenchBeige = 0xa67b5b,
    frenchBlue = 0x0072bb,
    frenchLilac = 0x86608e,
    frenchLime = 0xcf0000,
    frenchRaspberry = 0xc72c48,
    frenchRose = 0xf64a8a,
    fuchsia = 0xf0f000,
    fuchsiaCrayola = 0xc154c1,
    fuchsiaPink = 0xf7f000,
    fuchsiaRose = 0xc74375,
    fulvous = 0xe48400,
    fuzzyWuzzy = 0xc66000,
    gainsboro = 0xdcdcdc,
    gamboge = 0xe49b0f,
    ghostWhite = 0xf8f8ff,
    ginger = 0xb06500,
    glaucous = 0x6082b6,
    glitter = 0xe6e8fa,
    globalKleinBlue = 0x002fa7,
    globalOrangeAerospace = 0xff4f00,
    globalOrangeEngineering = 0xba160c,
    globalOrangeGoldenGate = 0xc0362c,
    goldMetallic = 0xd4af37,
    goldWebGolden = 0xffd700,
    goldenBrown = 0x996515,
    goldenPoppy = 0xfcc200,
    goldenYellow = 0xffdf00,
    goldenrod = 0xdaa520,
    grannySmithApple = 0xa8e4a0,
    gray = 0x808080,
    grayAsparagus = 0x465945,
    grayHtmlCss = 0x808080,
    grayX11 = 0xbebebe,
    greenColorWheelX11 = 0x0f0000,
    greenCrayola = 0x1cac78,
    greenHtmlCss = 0x008000,
    greenMunsell = 0x00a877,
    greenNcs = 0x009f6b,
    greenPigment = 0x00a550,
    greenRyb = 0x66b032,
    greenYellow = 0xadff2f,
    grullo = 0xa99a86,
    guppieGreen = 0x00ff7f,
    halayBe = 0x663854,
    hanBlue = 0x446ccf,
    hanPurple = 0x5218fa,
    hansaYellow = 0xe9d66b,
    harlequin = 0x3fff00,
    harvardCrimson = 0xc90016,
    harvestGold = 0xda9100,
    heartGold = 0x808000,
    heliotrope = 0xdf73ff,
    hollywoodCerise = 0xf400a1,
    honeydew = 0xf0fff0,
    honoluluBlue = 0x007fbf,
    hookerSGreen = 0x49796b,
    hotMagenta = 0xff1dce,
    hotPink = 0xff69b4,
    hunterGreen = 0x355e3b,
    iceberg = 0x71a6d2,
    icterine = 0xfcf75e,
    imperialBlue = 0x002395,
    inchworm = 0xb2ec5d,
    indiaGreen = 0x138808,
    indianRed = 0xcd5c5c,
    indianYellow = 0xe3a857,
    indigo = 0x6f00ff,
    indigoDye = 0x00416a,
    indigoWeb = 0x4b0082,
    iris = 0x5a4fcf,
    isabelline = 0xf4f0ec,
    islamicGreen = 0x009000,
    ivory = 0xfffff0,
    jade = 0x00a86b,
    jasmine = 0xf8de7e,
    jasper = 0xd73b3e,
    jazzberryJam = 0xa50b5e,
    jet = 0x343434,
    jonquil = 0xfada5e,
    juneBud = 0xbdda57,
    jungleGreen = 0x29ab87,
    kellyGreen = 0x4cbb17,
    kenyanCopper = 0x7c1c05,
    khakiHtmlCssKhaki = 0xc3b091,
    khakiX11LightKhaki = 0xf0e68c,
    kuCrimson = 0xe8000d,
    laSalleGreen = 0x087830,
    languidLavender = 0xd6cadd,
    lapisLazuli = 0x26619c,
    laserLemon = 0xfefe22,
    laurelGreen = 0xa9ba9d,
    lava = 0xcf1020,
    lavenderBlue = 0xccf000,
    lavenderBlush = 0xfff0f5,
    lavenderFloral = 0xb57edc,
    lavenderGray = 0xc4c3d0,
    lavenderIndigo = 0x9457eb,
    lavenderMagenta = 0xee82ee,
    lavenderMist = 0xe6e6fa,
    lavenderPink = 0xfbaed2,
    lavenderPurple = 0x967bb6,
    lavenderRose = 0xfba0e3,
    lavenderWeb = 0xe6e6fa,
    lawnGreen = 0x7cfc00,
    lemon = 0xfff700,
    lemonChiffon = 0xfffacd,
    lemonLime = 0xe3ff00,
    licorice = 0x1a1110,
    lightApricot = 0xfdd5b1,
    lightBlue = 0xadd8e6,
    lightBrown = 0xb5651d,
    lightCarminePink = 0xe66771,
    lightCoral = 0xf08080,
    lightCornflowerBlue = 0x93ccea,
    lightCrimson = 0xf56991,
    lightCyan = 0xe0ffff,
    lightFuchsiaPink = 0xf984ef,
    lightGoldenRodYellow = 0xfafad2,
    lightGray = 0xd3d3d3,
    lightGreen = 0x90ee90,
    lightKhaki = 0xf0e68c,
    lightPastelPurple = 0xb19cd9,
    lightPink = 0xffb6c1,
    lightRedOchre = 0xe97451,
    lightSalmon = 0xffa07a,
    lightSalmonPink = 0xf99000,
    lightSeaGreen = 0x20b2aa,
    lightSkyBlue = 0x87cefa,
    lightSlateGray = 0x789000,
    lightTaupe = 0xb38b6d,
    lightThulianPink = 0xe68fac,
    lightYellow = 0xffffe0,
    lilac = 0xc8a2c8,
    limeColorWheel = 0xbfff00,
    limeGreen = 0x32cd32,
    limeWebX11Green = 0x0f0000,
    limerick = 0x9dc209,
    lincolnGreen = 0x195905,
    linen = 0xfaf0e6,
    lion = 0xc19a6b,
    littleBoyBlue = 0x6ca0dc,
    liver = 0x534b4f,
    lust = 0xe62020,
    magenta = 0xf0f000,
    magentaDye = 0xca1f7b,
    magentaProcess = 0xff0090,
    magicMint = 0xaaf0d1,
    magnolia = 0xf8f4ff,
    mahogany = 0xc04000,
    maize = 0xfbec5d,
    majorelleBlue = 0x6050dc,
    malachite = 0x0bda51,
    manatee = 0x979aaa,
    mangoTango = 0xff8243,
    mantis = 0x74c365,
    mardiGras = 0x880085,
    maroonCrayola = 0xc32148,
    maroonHtmlCss = 0x800000,
    maroonX11 = 0xb03060,
    mauve = 0xe0b0ff,
    mauveTaupe = 0x915f6d,
    mauvelous = 0xef98aa,
    mayaBlue = 0x73c2fb,
    meatBrown = 0xe5b73b,
    mediumAquamarine = 0x6da000,
    mediumBlue = 0x0000cd,
    mediumCandyAppleRed = 0xe2062c,
    mediumCarmine = 0xaf4035,
    mediumChampagne = 0xf3e5ab,
    mediumElectricBlue = 0x035096,
    mediumJungleGreen = 0x1c352d,
    mediumLavenderMagenta = 0xdda0dd,
    mediumOrchid = 0xba55d3,
    mediumPersianBlue = 0x0067a5,
    mediumPurple = 0x9370db,
    mediumRedViolet = 0xbb3385,
    mediumRuby = 0xaa4069,
    mediumSeaGreen = 0x3cb371,
    mediumSlateBlue = 0x7b68ee,
    mediumSpringBud = 0xc9dc87,
    mediumSpringGreen = 0x00fa9a,
    mediumTaupe = 0x674c47,
    mediumTurquoise = 0x48d1cc,
    mediumTuscanRed = 0x79443b,
    mediumVermilion = 0xd9603b,
    mediumVioletRed = 0xc71585,
    mellowApricot = 0xf8b878,
    mellowYellow = 0xf8de7e,
    melon = 0xfdbcb4,
    midnightBlue = 0x191970,
    midnightGreenEagleGreen = 0x004953,
    mikadoYellow = 0xffc40c,
    mint = 0x3eb489,
    mintCream = 0xf5fffa,
    mintGreen = 0x98ff98,
    mistyRose = 0xffe4e1,
    moccasin = 0xfaebd7,
    modeBeige = 0x967117,
    moonstoneBlue = 0x73a9c2,
    mordantRed_19 = 0xae0c00,
    mossGreen = 0xaddfad,
    mountainMeadow = 0x30ba8f,
    mountbattenPink = 0x997a8d,
    msuGreen = 0x18453b,
    mulberry = 0xc54b8c,
    mustard = 0xffdb58,
    myrtle = 0x21421e,
    nadeshikoPink = 0xf6adc6,
    napierGreen = 0x2a8000,
    naplesYellow = 0xfada5e,
    navajoWhite = 0xffdead,
    navyBlue = 0x000080,
    neonCarrot = 0xffa343,
    neonFuchsia = 0xfe4164,
    neonGreen = 0x39ff14,
    newYorkPink = 0xd7837f,
    nonPhotoBlue = 0xa4dded,
    northTexasGreen = 0x059033,
    oceanBoatBlue = 0x0077be,
    ochre = 0xc72000,
    officeGreen = 0x008000,
    oldGold = 0xcfb53b,
    oldLace = 0xfdf5e6,
    oldLavender = 0x796878,
    oldMauve = 0x673147,
    oldRose = 0xc08081,
    olive = 0x808000,
    oliveDrab7 = 0x3c341f,
    oliveDrabWeb1 = 0x6b8e23,
    olivine = 0x9ab973,
    onyx = 0x353839,
    operaMauve = 0xb784a7,
    orangeColorWheel = 0xff7f00,
    orangePeel = 0xff9f00,
    orangeRed = 0xff4500,
    orangeRyb = 0xfb9902,
    orangeWebColor = 0xffa500,
    orchid = 0xda70d6,
    otterBrown = 0x654321,
    outerSpace = 0x414a4c,
    outrageousOrange = 0xff6e4a,
    oxfordBlue = 0x002147,
    pakistanGreen = 0x060000,
    palatinateBlue = 0x273be2,
    palatinatePurple = 0x682860,
    paleAqua = 0xbcd4e6,
    paleBlue = 0xafeeee,
    paleBrown = 0x987654,
    paleCarmine = 0xaf4035,
    paleCerulean = 0x9bc4e2,
    paleChestnut = 0xddadaf,
    paleCopper = 0xda8a67,
    paleCornflowerBlue = 0xabcdef,
    paleGold = 0xe6be8a,
    paleGoldenrod = 0xeee8aa,
    paleGreen = 0x98fb98,
    paleLavender = 0xdcd0ff,
    paleMagenta = 0xf984e5,
    palePink = 0xfadadd,
    palePlum = 0xdda0dd,
    paleRedViolet = 0xdb7093,
    paleRobinEggBlue = 0x96ded1,
    paleSilver = 0xc9c0bb,
    paleSpringBud = 0xecebbd,
    paleTaupe = 0xbc987e,
    paleVioletRed = 0xdb7093,
    pansyPurple = 0x78184a,
    papayaWhip = 0xffefd5,
    parisGreen = 0x50c878,
    pastelBlue = 0xaec6cf,
    pastelBrown = 0x836953,
    pastelGray = 0xcfcfc4,
    pastelGreen = 0x7d7000,
    pastelMagenta = 0xf49ac2,
    pastelOrange = 0xffb347,
    pastelPink = 0xdea5a4,
    pastelPurple = 0xb39eb5,
    pastelRed = 0xff6961,
    pastelViolet = 0xcb99c9,
    pastelYellow = 0xfdfd96,
    patriarch = 0x800080,
    payneSGrey = 0x536878,
    peach = 0xffe5b4,
    peachCrayola = 0xffcba4,
    peachOrange = 0xfc9000,
    peachPuff = 0xffdab9,
    peachYellow = 0xfadfad,
    pear = 0xd1e231,
    pearl = 0xeae0c8,
    pearlAqua = 0x88d8c0,
    pearlyPurple = 0xb768a2,
    peridot = 0xe6e200,
    periwinkle = 0xccf000,
    persianBlue = 0x1c39bb,
    persianGreen = 0x00a693,
    persianIndigo = 0x32127a,
    persianOrange = 0xd99058,
    persianPink = 0xf77fbe,
    persianPlum = 0x701c1c,
    persianRed = 0xc33000,
    persianRose = 0xfe28a2,
    persimmon = 0xec5800,
    peru = 0xcd853f,
    phlox = 0xdf00ff,
    phthaloBlue = 0x000f89,
    phthaloGreen = 0x123524,
    piggyPink = 0xfddde6,
    pineGreen = 0x01796f,
    pink = 0xffc0cb,
    pinkLace = 0xffddf4,
    pinkOrange = 0xf96000,
    pinkPearl = 0xe7accf,
    pinkSherbet = 0xf78fa7,
    pistachio = 0x93c572,
    platinum = 0xe5e4e2,
    plumTraditional = 0x8e4585,
    plumWeb = 0xdda0dd,
    portlandOrange = 0xff5a36,
    powderBlueWeb = 0xb0e0e6,
    princetonOrange = 0xff8f00,
    prune = 0x701c1c,
    prussianBlue = 0x003153,
    psychedelicPurple = 0xdf00ff,
    puce = 0xc89000,
    pumpkin = 0xff7518,
    purpleHeart = 0x69359c,
    purpleHtmlCss = 0x800080,
    purpleMountainMajesty = 0x9678b6,
    purpleMunsell = 0x9f00c5,
    purplePizzazz = 0xfe4eda,
    purpleTaupe = 0x50404d,
    purpleX11 = 0xa020f0,
    quartz = 0x51484f,
    rackley = 0x5d8aa8,
    radicalRed = 0xff355e,
    rajah = 0xfbab60,
    raspberry = 0xe30b5d,
    raspberryGlace = 0x915f6d,
    raspberryPink = 0xe25098,
    raspberryRose = 0xb3446c,
    rawUmber = 0x826644,
    razzleDazzleRose = 0xf3c000,
    razzmatazz = 0xe3256b,
    red = 0xf00000,
    redBrown = 0xa52a2a,
    redDevil = 0x860111,
    redMunsell = 0xf2003c,
    redNcs = 0xc40233,
    redOrange = 0xff5349,
    redPigment = 0xed1c24,
    redRyb = 0xfe2712,
    redViolet = 0xc71585,
    redwood = 0xab4e52,
    regalia = 0x522d80,
    resolutionBlue = 0x002387,
    richBlack = 0x004040,
    richBrilliantLavender = 0xf1a7fe,
    richCarmine = 0xd70040,
    richElectricBlue = 0x0892d0,
    richLavender = 0xa76bcf,
    richLilac = 0xb666d2,
    richMaroon = 0xb03060,
    rifleGreen = 0x414833,
    robinEggBlue = 0x0cc000,
    rose = 0xff007f,
    roseBonbon = 0xf9429e,
    roseEbony = 0x674846,
    roseGold = 0xb76e79,
    roseMadder = 0xe32636,
    rosePink = 0xf6c000,
    roseQuartz = 0xaa98a9,
    roseTaupe = 0x905d5d,
    roseVale = 0xab4e52,
    rosewood = 0x65000b,
    rossoCorsa = 0xd40000,
    rosyBrown = 0xbc8f8f,
    royalAzure = 0x0038a8,
    royalBlueTraditional = 0x002366,
    royalBlueWeb = 0x4169e1,
    royalFuchsia = 0xca2c92,
    royalPurple = 0x7851a9,
    royalYellow = 0xfada5e,
    rubineRed = 0xd10056,
    ruby = 0xe0115f,
    rubyRed = 0x9b111e,
    ruddy = 0xff0028,
    ruddyBrown = 0xbb6528,
    ruddyPink = 0xe18e96,
    rufous = 0xa81c07,
    russet = 0x80461b,
    rust = 0xb7410e,
    rustyRed = 0xda2c43,
    sacramentoStateGreen = 0x00563f,
    saddleBrown = 0x8b4513,
    safetyOrangeBlazeOrange = 0xff6700,
    saffron = 0xf4c430,
    salmon = 0xff8c69,
    salmonPink = 0xff91a4,
    sand = 0xc2b280,
    sandDune = 0x967117,
    sandstorm = 0xecd540,
    sandyBrown = 0xf4a460,
    sandyTaupe = 0x967117,
    sangria = 0x92000a,
    sapGreen = 0x507d2a,
    sapphire = 0x0f52ba,
    sapphireBlue = 0x0067a5,
    satinSheenGold = 0xcba135,
    scarlet = 0xff2400,
    scarletCrayola = 0xfd0e35,
    schoolBusYellow = 0xffd800,
    screaminGreen = 0x76ff7a,
    seaBlue = 0x006994,
    seaGreen = 0x2e8b57,
    sealBrown = 0x321414,
    seashell = 0xfff5ee,
    selectiveYellow = 0xffba00,
    sepia = 0x704214,
    shadow = 0x8a795d,
    shamrockGreen = 0x009e60,
    shockingPink = 0xfc0fc0,
    shockingPinkCrayola = 0xff6fff,
    sienna = 0x882d17,
    silver = 0xc0c0c0,
    sinopia = 0xcb410b,
    skobeloff = 0x007474,
    skyBlue = 0x87ceeb,
    skyMagenta = 0xcf71af,
    slateBlue = 0x6a5acd,
    slateGray = 0x708090,
    smaltDarkPowderBlue = 0x039000,
    smokeyTopaz = 0x933d41,
    smokyBlack = 0x100c08,
    snow = 0xfffafa,
    spiroDiscoBall = 0x0fc0fc,
    springBud = 0xa7fc00,
    springGreen = 0x00ff7f,
    stPatrickSBlue = 0x23297a,
    steelBlue = 0x4682b4,
    stilDeGrainYellow = 0xfada5e,
    stizza = 0x900000,
    stormcloud = 0x4f666a,
    straw = 0xe4d96f,
    sunglow = 0xfc3000,
    sunset = 0xfad6a5,
    tan = 0xd2b48c,
    tangelo = 0xf94d00,
    tangerine = 0xf28500,
    tangerineYellow = 0xfc0000,
    tangoPink = 0xe4717a,
    taupe = 0x483c32,
    taupeGray = 0x8b8589,
    teaGreen = 0xd0f0c0,
    teaRoseOrange = 0xf88379,
    teaRoseRose = 0xf4c2c2,
    teal = 0x008080,
    tealBlue = 0x367588,
    tealGreen = 0x00827f,
    telemagenta = 0xcf3476,
    tennTawny = 0xcd5700,
    terraCotta = 0xe2725b,
    thistle = 0xd8bfd8,
    thulianPink = 0xde6fa1,
    tickleMePink = 0xfc89ac,
    tiffanyBlue = 0x0abab5,
    tigerSEye = 0xe08d3c,
    timberwolf = 0xdbd7d2,
    titaniumYellow = 0xeee600,
    tomato = 0xff6347,
    toolbox = 0x746cc0,
    topaz = 0xffc87c,
    tractorRed = 0xfd0e35,
    trolleyGrey = 0x808080,
    tropicalRainForest = 0x00755e,
    trueBlue = 0x0073cf,
    tuftsBlue = 0x417dc1,
    tumbleweed = 0xdeaa88,
    turkishRose = 0xb57281,
    turquoise = 0x30d5c8,
    turquoiseBlue = 0x00ffef,
    turquoiseGreen = 0xa0d6b4,
    tuscanRed = 0x7c4848,
    twilightLavender = 0x8a496b,
    tyrianPurple = 0x66023c,
    uaBlue = 0x03a000,
    uaRed = 0xd9004c,
    ube = 0x8878c3,
    uclaBlue = 0x536895,
    uclaGold = 0xffb300,
    ufoGreen = 0x3cd070,
    ultraPink = 0xff6fff,
    ultramarine = 0x120a8f,
    ultramarineBlue = 0x4166f5,
    umber = 0x635147,
    unbleachedSilk = 0xffddca,
    unitedNationsBlue = 0x5b92e5,
    unmellowYellow = 0xff6000,
    upForestGreen = 0x014421,
    upMaroon = 0x7b1113,
    upsdellRed = 0xae2029,
    urobilin = 0xe1ad21,
    usafaBlue = 0x004f98,
    uscGold = 0xfc0000,
    utahCrimson = 0xd3003f,
    vanilla = 0xf3e5ab,
    vegasGold = 0xc5b358,
    venetianRed = 0xc80815,
    verdigris = 0x43b3ae,
    vermilionCinnabar = 0xe34234,
    vermilionPlochere = 0xd9603b,
    veronica = 0xa020f0,
    violet = 0x8f00ff,
    violetBlue = 0x324ab2,
    violetColorWheel = 0x7f00ff,
    violetRyb = 0x8601af,
    violetWeb = 0xee82ee,
    viridian = 0x40826d,
    vividAuburn = 0x922724,
    vividBurgundy = 0x9f1d35,
    vividCerise = 0xda1d81,
    vividTangerine = 0xffa089,
    vividViolet = 0x9f00ff,
    warmBlack = 0x004242,
    waterspout = 0xa4f4f9,
    wenge = 0x645452,
    wheat = 0xf5deb3,
    white = 0xffffff,
    whiteSmoke = 0xf5f5f5,
    wildBlueYonder = 0xa2add0,
    wildStrawberry = 0xff43a4,
    wildWatermelon = 0xfc6c85,
    wine = 0x722f37,
    wineDregs = 0x673147,
    wisteria = 0xc9a0dc,
    woodBrown = 0xc19a6b,
    xanadu = 0x738678,
    yaleBlue = 0x0f4d92,
    yellow = 0xff0000,
    yellowGreen = 0x9acd32,
    yellowMunsell = 0xefcc00,
    yellowNcs = 0xffd300,
    yellowOrange = 0xffae42,
    yellowProcess = 0xffef00,
    yellowRyb = 0xfefe33,
    zaffre = 0x0014a8,
    zinnwalditeBrown = 0x2c1608
}