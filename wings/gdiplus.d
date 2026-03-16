module wings.gdiplus; // Created on : 04-Jun-22 11:16:02 PM
//pragma(lib, "Gdiplus"); // Required for linker to find the right lib.

/*
 Note : Microsoft developed Gdi+ as a successor of old GDI functions.
        Gdi+ is a set of 40 C++ classes and it's methods.
        But those c++ classes are actually a wrapper for some C functions.
        They called those set of C functions 'gdi plus flat api'.
        So we can call those C functions from D very easily. 
        For more info visit this link.
        https://docs.microsoft.com/en-us/windows/win32/gdiplus/-gdiplus-flatapi-flat
 */


private import core.sys.windows.windows ;
private import core.stdc.stddef;
private import std.utf ;
private import wings.commons;

alias Wstring = const(wchar)* ; 
alias DebugEventProc = void function(DebugEventLevel level, char * message);
alias NotificationHookProc = Status function(ULONG_PTR * token);
alias NotificationUnhookProc = void function(ULONG_PTR * token);
alias GpImage = void;
struct GpGraphics;

    
/// A wrapper class to use Gdi plus functions easily.
class GdiPlus {
    private uint mToken ;
    bool isGdipInit;

    // Start Gdi plus operations.
    this() {
        if (!this.isGdipInit) {
            this.initGdip();
        }
    }

    void initGdip() {
        if (this.isGdipInit) {
            return;
        } else {
            print("Initializing GdiPlus...");
            GdiplusStartupInput stInp = GdiplusStartupInput(1);            
            GdiplusStartup(&this.mToken, &stInp, null); // @suppress(dscanner.unused_result)}
            this.isGdipInit = true;
            print("GdiPlus initialized successfully.");
        }        
    }

    // Shutdown gdi plus operations.
    void shutDownGdiPlus () 
    {
        if (this.isGdipInit) {
            this.isGdipInit = false;
            if (this.mToken != 0) {
                GdiplusShutdown(&this.mToken);
                print("GdiPlus shutdown successfully.");
            }
        } 
    }   

    // Create an HBITMAP from a given file path.
    HBITMAP* createHbitmapFromFile(string imgFile) {
        auto fPath = toUTF16z(imgFile);
        void* pBmp ;
        auto ret = GdipCreateBitmapFromFile(fPath, &pBmp); 
        //auto ret = GdipLoadImageFromFile(fPath, &pBmp) ;
        
        if (ret == Status.ok) {          
            auto hBmp = new HBITMAP;
            // void* resizedImg;
            // auto rsdBmp = this.resizeImage(resizedImg, pBmp, 16, 16) ;
            ret = GdipCreateHBITMAPFromBitmap(pBmp, hBmp, 0);            
            return (ret == Status.ok) ? hBmp : null;                
        }
        return null;
    }

    static Status setResolution(void* pBmp, int x, int y) {
       return GdipBitmapSetResolution(pBmp, x, y) ;
    }

    final HBITMAP* readPngFile(string pngPath) {
        auto fPath = toUTF16z(pngPath);
        void* pBmp ;
        //auto ret = GdipCreateBitmapFromFile(fPath, &pBmp); 
        auto ret = GdipLoadImageFromFile(fPath, &pBmp) ;
        
        if (ret == Status.ok) {                
            auto hBmp = new HBITMAP;
            // void* resizedImg;
            // auto rsdBmp = this.resizeImage(resizedImg, pBmp, 16, 16) ;
            ret = GdipCreateHBITMAPFromBitmap(pBmp, hBmp, 0);                       
            return (ret == Status.ok) ? hBmp : null;                
        }
        return null;
    }

    // final Status resizeImage(void* result, void* pImg, int width, int height, 
    //                         InterPolationMode ipMode = InterPolationMode.highQualityBiCubic)  {
    //     // TODO
    //     auto oldSize = this.getImageSize(pImg);
    //     if (oldSize.valueReady) {
    //         // void* pBmp ;
    //         auto ret = createBitmapFromScanZero(&result, width, height) ;
    //         if (ret == Status.ok) {
    //             void* graphics;
    //             ret = GdipGetImageGraphicsContext(&result, &graphics); // graphics is the result
    //             print("last result ", ret) ;
    //             ret = GdipSetInterpolationMode(&graphics, ipMode);
    //             ret = GdipSetPixelOffsetMode(&graphics, PixelOffsetMode.highQuality);
    //             void* imgAttr;
    //             ret = GdipCreateImageAttributes(&imgAttr); //imgAttr is the return value
    //             if (ret != Status.ok) {
    //                 GdipDisposeImageAttributes(imgAttr);
    //                 GdipDeleteGraphics(graphics);
    //                 GdipDisposeImage(result);
    //             }
    //             auto res = GdipDrawImageRectRect(&graphics, pImg, 0, 0, oldSize.width, oldSize.height, 
    //                                     0, 0, width, height, GpUnit.unitPixel, &imgAttr, null, null) ;
                
    //             return res ;
    //         }
    //     }
    //     return Status.Aborted;

    // }

    final Size getImageSize(void* img) {
        Size ss = Size(-1, -1) ;
        auto wid = getImageWidth(img);
        auto hei = getImageHeight(img);
        if (wid > 0 && hei > 0) {
            ss.width = wid;
            ss.height = hei;
            return ss;
        }
        return Size(-1, -1);
    }

    private :

    uint getImageWidth(void* img) { // Private
        uint result = 0;
        //print("I reached here");
        auto res = GdipGetImageWidth(img, &result);
        if (res == Status.ok) return result ;
        return result;
    }

    uint getImageHeight(void* img) { // Private
        uint result;
        auto res = GdipGetImageHeight(img, &result);
        if (res == Status.ok) return result ;
        return 0;
    }

    Status createBitmapFromScanZero( void* img, int width, int height, 
                                    PixelFormat pf = PixelFormat.pArgb32Bpp8888,
                                    int stride = 0, byte* pxData = null) {
        
        return GdipCreateBitmapFromScan0(width, height, stride, pf, pxData, img);
    }



} // End of class GdiPlus.


extern (Windows) {
    Status GdiplusStartup( uint* token, 
                            const GdiplusStartupInput* input,
                            GdiplusStartupOutput* output) ; 

    void GdiplusShutdown(uint * token); 
    Status GdipCreateBitmapFromFile(Wstring file, void* pBitmap) ;
    Status GdipCreateHBITMAPFromBitmap(void* pBitmap, HBITMAP* pRetHbmp, int argb);
    Status GdipBitmapSetResolution(void* pBitmap, int xdpi, int ydpi);
    Status GdipLoadImageFromFile(Wstring file, void** image);
    Status GdipGetImageWidth(void* img, UINT* width) ;
    Status GdipGetImageHeight(void* img, uint* height) ;
    Status GdipCreateBitmapFromScan0(int width, int height, int stride, PixelFormat pf, byte* scan0, void* pBmp);
    Status GdipGetImageGraphicsContext(void* image, void** graphics) ;
    Status GdipSetInterpolationMode(void* graphics, InterPolationMode ipMode);
    Status GdipSetPixelOffsetMode(void* graphics, PixelOffsetMode pxoMode);
    Status GdipCreateImageAttributes(void** imageattr);
    Status GdipDisposeImageAttributes(void* imageattr);
    Status GdipDeleteGraphics(void* graphics);
    Status GdipDisposeImage(void* image);
    Status GdipDrawImageRect(GpGraphics* graphics, GpImage* image, 
                                float x, float y, float width, float height);
    Status GdipDrawImageRectRect(void* graphics, void* image, int dstx, // NOTE - Fix the parameter types
                                    int dsty, int dstwidth, int dstheight,
                                    int srcx, int srcy, int srcwidth, int srcheight,
                                    GpUnit srcUnit, const void* imageAttributes,
                                    void* callback, void* callbackData);

    Status GdipCreateFromHDC(HDC hdc, GpGraphics** graphics);
    
}




enum Status {
    ok = 0,
    genericError = 1,
    invalidParameter = 2,
    outOfMemory = 3,
    objectBusy = 4,
    insufficientBuffer = 5,
    notImplemented = 6,
    win32Error = 7,
    wrongState = 8,
    aborted = 9,
    fileNotFound = 10,
    valueOverflow = 11,
    accessDenied = 12,
    unknownImageFormat = 13,
    fontFamilyNotFound = 14,
    fontStyleNotFound = 15,
    notTrueTypeFont = 16,
    unsupportedGdiplusVersion = 17,
    gdiplusNotInitialized = 18,
    propertyNotFound = 19,
    propertyNotSupported = 20,
    profileNotFound = 21
}

enum InterPolationMode {
    invalidMode = -1,
    defaultMode,
    lowQuality,
    highQuality,
    biLinear,
    biCubic,
    nearestNeighbour,
    highQualityBiLinear,
    highQualityBiCubic

}

enum PixelFormat {
    indexed01Bpp = 0x00030101, // 1 bpp, indexed
    indexed04Bpp = 0x00030402, // 4 bpp, indexed
    indexed08Bpp = 0x00030803, // 8 bpp, indexed
    grayScale16Bpp = 0x00101004, // 16 bpp, grayscale
    rgb16Bpp555 = 0x00021005, // 16 bpp -- 5 bits for each RGB
    rgb16Bpp565 = 0x00021006, // 16 bpp -- 5 bits red, 6 bits green, and 5 bits blue
    rgb16Bpp1555 = 0x00061007, // 16 bpp -- 1 bit for alpha and 5 bits for each RGB component
    rgb24Bpp888 = 0x00021808, // 24 bpp -- 8 bits for each RGB
    rgb32Bpp888 = 0x00022009, // 32 bpp -- 8 bits for each RGB. No alpha.
    argb32Bpp8888 = 0x0026200A, // 32 bpp -- 8 bits for each RGB and alpha
    pArgb32Bpp8888 = 0x000E200B, // 32 bpp -- 8 bits for each RGB and alpha, pre-mulitiplied
    rgb48BppFFF = 0x0010300C, // 48 bpp -- 16 bits for each RGB
    argb64FFFF = 0x0034400D, // 64 bpp -- 16 bits for each RGB and alpha
    pArgb64FFFF = 0x001A400E // 64 bpp --16 bits for each RGB and alpha, pre-multiplied
}

enum PixelOffsetMode {
    invalidMode = -1,
    defaultMode,
    highSpeed,
    highQuality,
    noMode,
    halfMode,
}

enum GpUnit {
    unitWorld,
    unitDisplay,
    unitPixel, // = unitPixel,
    unitPoint, // = unitPoint,
    unitInch, // = unitInch,
    unitDocument,
    unitMillimeter
}

enum DebugEventLevel {
    DebugEventLevelFatal,
    DebugEventLevelWarning
}


struct GdiplusStartupInput {
    UINT32         GdiplusVersion;
    DebugEventProc DebugEventCallback;
    BOOL           SuppressBackgroundThread;
    BOOL           SuppressExternalCodecs;    
}

struct GdiplusStartupOutput {
  NotificationHookProc   NotificationHook;  
  NotificationUnhookProc NotificationUnhook;
}