module wings.imagelist; // Created on : 03-Jun-22 12:39:17 AM



import core.sys.windows.commctrl;
import core.sys.windows.windows;
import std.utf;
import std.file;
import std.path;

import wings.enums;
import wings.gdiplus;
import wings.commons;
import wings.colors;

//import wings.gdiplus : Color;






class ImageList {
    this(ImageType imgTyp) {
        this.mImgType = imgTyp;
    }
    this(   int sX, int sY,
            int initSize = 4, int growSize = 4,
            ImageOptions imgOpt = ImageOptions.none,
            ColorOptions clrOpt = ColorOptions.defaultColor,
            ImageType imgTyp = ImageType.normalImage)
    {
        this.mSizeX = sX;
        this.mSizeY = sY;
        this.mImgType = imgTyp;
        this.mImgOpt = imgOpt;
        this.mClrOpt = clrOpt;
        this.mInitSize = initSize;
        this.mGrowSize = growSize;
        this.createHandle();
    }

    this() {}

    ~this() {if (this.handle) ImageList_Destroy(this.mHandle);}

    final bool isCreated() {return this.mIsCreated;}
    final HIMAGELIST handle() {return this.mHandle;}

    final ImageType imageType() {return this.mImgType;}
    final void imageType(ImageType value) {this.mImgType = value;}

    final ImageOptions imageOption() {return this.mImgOpt;}
    final void imageOption(ImageOptions value) {this.mImgOpt = value;}

    final ColorOptions colorOption() {return this.mClrOpt;}
    final void colorOption(ColorOptions value) {this.mClrOpt = value;}

    final int sizeX() {return this.mSizeX;}
    final void sizeX(int value) {this.mSizeX = value;}

    final int sizeY() {return this.mSizeY;}
    final void sizeY(int value) {this.mSizeY = value;}


    final void createHandle() {
        uint uFlag = cast(uint) this.mImgOpt | cast(uint) this.mClrOpt;
        this.mHandle = ImageList_Create(this.mSizeX, this.mSizeY, uFlag, this.mInitSize, this.mGrowSize);
        this.mIsCreated = true;
    }

    final void addBitmap(HBITMAP hBmp, HBITMAP hMask = null) {
        if (this.mIsCreated) ImageList_Add(this.mHandle, hBmp, hMask);
    }

    // Adds an Icon from given dll.
    final void addIcon(string dllPath, int index, bool smallIcon = true) {
        HICON hIco;
        scope(exit) DestroyIcon(hIco);
        uint uRet;
        if (smallIcon) {
            uRet = ExtractIconExW(dllPath.toUTF16z, index, null, &hIco, 1);
        } else uRet = ExtractIconExW(dllPath.toUTF16z, index, &hIco, null, 1);
        if (uRet !=0 && this.mIsCreated) ImageList_ReplaceIcon(this.mHandle, -1, hIco);
    }

    final void addImage(string imgFile) {
        if (this.mIsCreated) {
            // We need to call some functions from Gdi+ dll.
            // This wrapper class will init the GdiplusStartup function
            auto gp = new GdiPlus;
            auto hBitmap = gp.createHbitmapFromFile(imgFile);
            gp.shutDownGdiPlus();
            if (hBitmap) ImageList_Add(this.mHandle, hBitmap, null);
            //if (hBitmap) print("Gdi plus worked");
        }
    }

    final void addImages(string folderPath, string[] extArray = [".bmp", ".jpeg", ".jpg", ".tiff",".png"]) {

        if (this.mIsCreated) {
            // We loop through files on that folder and check the extension.
            // If it is in our extArray, we will process it.
            auto gp = new GdiPlus; // do the gdi startup process.
            foreach (imgFile; dirEntries(folderPath, SpanMode.breadth) ) {
                if (arraySearch(extArray, imgFile.extension) != -1) {
                    auto hBitmap = gp.createHbitmapFromFile(imgFile);
                    if (hBitmap) ImageList_Add(this.mHandle, hBitmap, null);
                }
            }
            gp.shutDownGdiPlus(); // properly shut down gdi plus.
        }
    }

    final void addSolidColorImage(HWND ctlHwnd, uint clr, int width, int height) {
        if (this.mIsCreated) {
            HDC hdc = GetDC(ctlHwnd);
            HDC compDc = CreateCompatibleDC(hdc);
            HBITMAP hBmp = CreateCompatibleBitmap(hdc, width, height);
            auto oldDC = SelectObject(compDc, hBmp);
            RECT rct = RECT(0, 0, width, height);
            auto hBrush = CreateSolidBrush(getClrRef(clr));
            if (!FillRect(compDc, &rct, hBrush)) DeleteObject(hBmp);
            ImageList_Add(this.mHandle, hBmp, null);
            DeleteObject(hBrush);
            ReleaseDC(ctlHwnd, hdc);
            SelectObject(compDc, oldDC);
            DeleteDC(compDc);
        }
    }

    final void addIcon(string imgFile) {
        if (this.mIsCreated) {
            if (imgFile.extension == ".ico") {
                auto hIco =  LoadImageW(null, imgFile.toUTF16z, 1, 0, 0, LR_LOADFROMFILE);
                ImageList_AddIcon(this.mHandle, hIco);
            }
        }
    }

    final void addIcons(string folderPath) {
        if (this.mIsCreated) {
            foreach (imgFile; dirEntries(folderPath, SpanMode.breadth) ) {
                if (imgFile.extension == ".ico") {
                    auto hIco =  LoadImageW(null, imgFile.toUTF16z, 1, 0, 0, LR_LOADFROMFILE );
                    if (hIco) {
                        auto ret = ImageList_AddIcon(this.mHandle, hIco);
                    }
                }
            }
        }
    }

    final void experiment(string folderPath) {
        if (this.mIsCreated) {
            auto gp = new GdiPlus; // do the gdi startup process.
            foreach (imgFile; dirEntries(folderPath, SpanMode.breadth) ) {
                if (imgFile.extension == ".png") {
                    // auto hBitmap = gp.readPngFile(imgFile);
                    // if (hBitmap) {
                    //     print("Adding image", ImageList_AddMasked(this.mHandle, hBitmap, CLR_DEFAULT));
                    //     print(GetLastError());
                    // }
                    auto rr = ImageList_LoadImageW(null, imgFile.toUTF16z, 16, 16, CLR_NONE, IMAGE_BITMAP, LR_LOADFROMFILE);
                    //print("imlli ", rr);
                }
            }
            gp.shutDownGdiPlus(); // properly shut down gdi plus.
        }
    }

    private :
        ImageType mImgType;
        ImageOptions mImgOpt;
        ColorOptions mClrOpt;
        HIMAGELIST mHandle;
        bool mIsCreated;
        int mSizeX = 16;
        int mSizeY = 16;
        int mInitSize = 4;
        int mGrowSize = 4;

}

// These two constants are missing in `commctrl.d`.
enum ILC_MIRROR = 0x00002000;
enum ILC_PERITEMMIRROR = 0x00008000;



