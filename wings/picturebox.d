// Created on: 11-Mar-2026 07:07 PM
// Purpose: 
module wings.picturebox;

import std.stdio;
import wings.d_essentials;
import wings.wings_essentials;
import wings.imagelist: Image;
import wings.enums: PictureSizeMode;
import wings.form: trackMouseMove;



wchar[] pBoxClass = ['W','i','n','g','s','_','P','i','c','t','u','r','e','B','o','x', 0];
private static int pbxNumber = 1;

class PictureBox : Control
{
    this(Form parent, int x, int y, int w, int h, 
            string imagePath = null, PictureSizeMode sizeMode = PictureSizeMode.normal)
    {
        registerPBoxClass();
        this.mName = format("%s_%d", "PictureBox", pbxNumber);
        mixin(repeatingCode);
        this.mSizeMode = sizeMode;
        this.mImgPath = imagePath;        
        mControlType = ControlType.pictureBox;
        mStyle = WS_CHILD | WS_TABSTOP | WS_VISIBLE;
        mExStyle = 0;
        this.mParent.mControls ~= this;
        this.mCtlId = Control.stCtlId;
        ++Control.stCtlId;
        ++pbxNumber;
    }

    override void createHandle()
    {   
        this.mSize = SIZE(this.mWidth, this.mHeight);
        if (this.mImgPath.length > 0) this.setImage(this.mImgPath);
        this.createHandleInternal(pBoxClass.ptr);
        if (this.mHandle) {
            // ptf("PictureBox handle created:", this.mHandle);
            setThisPtrOnWindows(this, this.mHandle,);
            GetClientRect(this.mHandle, &mRect);
        }
    }

    void setImage(string filePath)
    {
        this.mImage = new Image(filePath);
        this.mImgPath = filePath;
        if (this.mSizeMode == PictureSizeMode.autoSize) {
            this.size = this.mImage.size;
        }
        if (this.mHandle) this.updateClientRect();
    }

    /// Clear the current image
    void clearImage()
    {
        this.mImage = null;
        this.mImgPath = null;
        if (this.mHandle) InvalidateRect(this.mHandle, null, TRUE);
    }

    /// Get/set the current image
    @property Image image() { return mImage; }
    @property void image(Image img)
    {
        mImage = img;
        if (mSizeMode == PictureSizeMode.autoSize) {
            adjustSizeToImage();
        } else {    
            this.updateClientRect();
        }
    }

    /// Get/set the size mode
    @property PictureSizeMode sizeMode() const { return mSizeMode; }
    @property void sizeMode(PictureSizeMode mode)
    {
        if (mSizeMode == mode) return;
        this.mSizeMode = mode;
        if (mode == PictureSizeMode.autoSize && this.mImage) {
            adjustSizeToImage();
        } else {
            this.updateClientRect();
        }   
    }

    @property SIZE size()
    {
        if (!mHandle) return SIZE(0, 0);
        return this.mSize;
    }
    @property void size(SIZE sz)
    {
        if (!mHandle) return;
        SetWindowPos(mHandle, null, 0, 0, sz.cx, sz.cy,
                     SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
        mSize = sz;
    }

    override final void width(int value)
    {
        this.mWidth = value;  
        if (this.mIsCreated) this.updateClientRect();
    }

    override final void height(int value)
    {
        this.mHeight = value;  
        if (this.mIsCreated) this.updateClientRect();
    }

    package:
        Image mImage;
        PictureSizeMode mSizeMode = PictureSizeMode.normal;

    private:
        RECT mRect; // Cached client rect for drawing 
        SIZE mSize; // Cached size for drawing
        string mImgPath;
        static bool isPBoxClassRegistered;  
        bool mIsMouseTracking;
        bool mIsMouseEntered;      
        static void registerPBoxClass()
        {
            if (isPBoxClassRegistered) return;
            WNDCLASSEXW wc;
            wc.cbSize = WNDCLASSEXW.sizeof;
            wc.style = 0;
            wc.lpfnWndProc = &pBoxWndProc;
            wc.cbClsExtra = 0;
            wc.cbWndExtra = 0;
            wc.hInstance = appData.hInstance;
            wc.hIcon = null;
            wc.hCursor = LoadCursorW(null, IDC_ARROW);
            wc.hbrBackground = null;
            wc.lpszMenuName = null;
            wc.lpszClassName = pBoxClass.ptr;
            wc.hIconSm = null;
            if (RegisterClassExW(&wc) == 0) {
                if (GetLastError() != ERROR_CLASS_ALREADY_EXISTS)
                    throw new Exception("Failed to register PictureBox class");
            }
            isPBoxClassRegistered = true;
        }

        void updateClientRect()
        {
            this.computeDestRect();
            if (this.mHandle) InvalidateRect(this.mHandle, null, TRUE);
        }

        // Adjust the control size to match the image size (for AutoSize mode)
        void adjustSizeToImage()
        {
            if (!this.mImage || !this.mHandle) return;
            auto sz = this.mImage.size;
            SetWindowPos(this.mHandle, null, 0, 0, sz.cx, sz.cy,
                         SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
            this,mRect = RECT(0, 0, sz.cx, sz.cy);
            if (this.mHandle) InvalidateRect(this.mHandle, null, TRUE);
        }

        /// Compute the destination rectangle according to the current size mode
        void computeDestRect()
        {
            int cw = this.mRect.right - this.mRect.left;
            int ch = this.mRect.bottom - this.mRect.top;
            if (mImage is null) this.mRect = RECT(0, 0, 0, 0);
            auto imgW = mImage.width;
            auto imgH = mImage.height;
            if (imgW == 0 || imgH == 0) this.mRect = RECT(0, 0, 0, 0);
            switch (this.mSizeMode) {
                case PictureSizeMode.normal:
                    this.mRect = RECT(0, 0, imgW, imgH);
                break;
                case PictureSizeMode.center: 
                    int x = (cw - imgW) / 2;
                    int y = (ch - imgH) / 2;
                    this.mRect = RECT(x, y, x + imgW, y + imgH);
                break;
                case PictureSizeMode.stretch:
                    this.mRect = RECT(0, 0, cw, ch);
                break;
                case PictureSizeMode.zoom: 
                    double ratioImg = cast(double)imgW / imgH;
                    double ratioCtl = cast(double)cw / ch;
                    int w, h;
                    if (ratioImg > ratioCtl) {
                        w = cw;
                        h = cast(int)(cw / ratioImg);
                    } else {
                        h = ch;
                        w = cast(int)(ch * ratioImg);
                    }
                    int x = (cw - w) / 2;
                    int y = (ch - h) / 2;
                    this.mRect = RECT(x, y, x + w, y + h);
                break;
                case PictureSizeMode.autoSize:
                    // AutoSize already adjusted the control, so image fits exactly
                    this.mRect = RECT(0, 0, imgW, imgH);
                break;
                default:
                    this.mRect = RECT(0, 0, 0, 0);
                break;
            }
        }

        void invalidate() {if (mHandle) InvalidateRect(mHandle, null, TRUE);}
}



/// WndProc function for Form class
extern(Windows)
LRESULT pBoxWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) nothrow
{
    // ptf("PictureBox WndProc received message: %s", message);
    try {
        // print("Main wndproc message", message);
        switch (message) { 
            case WM_CREATE: 
                // We can do any initialization here if needed
                // ptf("PictureBox created with handle: %s", hWnd);
                break;    
                   
            case WM_DESTROY: 
                // auto pbx = getAs!PictureBox(hWnd);                
                              
            break;
            case WM_PAINT: 
                PAINTSTRUCT ps;
                auto pbx = getAs!PictureBox(hWnd);
                HDC hdc = BeginPaint(hWnd, &ps); 
                scope(exit) EndPaint(hWnd, &ps);               
                if (pbx.mImage) { 
                    pbx.mImage.draw(hdc, pbx.mRect.left, pbx.mRect.top, 
                                    pbx.mRect.right - pbx.mRect.left, 
                                    pbx.mRect.bottom - pbx.mRect.top);
                } else {
                    // If no image, fill with background color
                    // print("No image to draw, filling with background color");
                    HBRUSH hbr = CreateSolidBrush(pbx.mBackColor.cref);
                    FillRect(hdc, &ps.rcPaint, hbr);
                    DeleteObject(hbr);
                }
                return 0;
            break;

            case WM_ERASEBKGND:
                // We handle everything in WM_PAINT, so suppress background erase
                return 1;

            case WM_SIZE:
                // if (hWnd) {
                    // ptf("PictureBox resized, new size: %d x %d", LOWORD(lParam), HIWORD(lParam));
                    auto pbx = getAs!PictureBox(hWnd);
                    if (pbx) {
                        if (pbx.mSizeMode != PictureSizeMode.autoSize) pbx.invalidate();
                    }
                // }   
                break;             
            
            case WM_MOUSEMOVE:
                auto pbx = getAs!PictureBox(hWnd);
                if (!pbx.mIsMouseTracking) {
                    pbx.mIsMouseTracking = true;
                    trackMouseMove(hWnd);
                    if (!pbx.mIsMouseEntered) {
                        pbx.mIsMouseEntered = true;
                        if (pbx.onMouseEnter) {                            
                            pbx.onMouseEnter(pbx, new EventArgs());
                        }
                    }
                }
                if (pbx.onMouseMove) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    pbx.onMouseMove(pbx, ea);
                }
            break;
            case WM_MOUSEHOVER:
                auto pbx = getAs!PictureBox(hWnd);
                if (pbx.mIsMouseTracking) {pbx.mIsMouseTracking = false;}
                if (pbx.onMouseHover) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    pbx.onMouseHover(pbx, ea);
                }
            break;
            case WM_MOUSELEAVE:
                auto pbx = getAs!PictureBox(hWnd);
                if (pbx.mIsMouseTracking) {
                    pbx.mIsMouseTracking = false;
                    pbx.mIsMouseEntered = false;
                }
                if (pbx.onMouseLeave) pbx.onMouseLeave(pbx, new EventArgs());                
            break;
            case WM_LBUTTONDOWN:
                auto pbx = getAs!PictureBox(hWnd);
                pbx.lDownHappened = true;
                if (pbx.onMouseDown) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    pbx.onMouseDown(pbx, ea);
                    return 0;
                }
            break;
            case WM_LBUTTONUP:
                auto pbx = getAs!PictureBox(hWnd);
                if (pbx.onMouseUp) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    pbx.onMouseUp(pbx, ea);
                }
                if (pbx.onClick) pbx.onClick(pbx, new EventArgs());
            break;
            case WM_RBUTTONDOWN:
                auto pbx = getAs!PictureBox(hWnd);
                pbx.rDownHappened = true;
                if (pbx.onRightMouseDown) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    pbx.onRightMouseDown(pbx, ea);
                }
            break;
            case WM_RBUTTONUP:
                auto pbx = getAs!PictureBox(hWnd);
                if (pbx.onRightMouseUp) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    pbx.onRightMouseUp(pbx, ea);
                }
                if (pbx.onRightClick) pbx.onRightClick(pbx, new EventArgs());
            break;
                
            default: break;
                // return DefWindowProcW(hWnd, message, wParam, lParam);
        }
    } 
    catch (Exception e){}    
    return DefWindowProcW(hWnd, message, wParam, lParam);
}