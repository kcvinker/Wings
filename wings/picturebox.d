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
            // setThisPtrOnWindows(this, this.mHandle,);
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
        auto self = fromHwndTo!PictureBox(hWnd);
        if (self is null) {
            if (message == WM_NCCREATE) {
                CREATESTRUCT* cs = cast(CREATESTRUCT*)lParam;
                self = cast(PictureBox) cs.lpCreateParams;
                self.mHandle = hWnd;			
                SetWindowLongPtr(hWnd, GWLP_USERDATA,  cast(LONG_PTR) cast(void*)self);                
                return 1; // Continue window creation
            }
            return DefWindowProc(hWnd, message, wParam, lParam);
        }

        auto res = self.commonMsgHandler(hWnd, message, wParam, lParam);
        if (res == MsgHandlerResult.callDefProc) {
            return DefWindowProcW(hWnd, message, wParam, lParam);
        } else if (res == MsgHandlerResult.returnZero || res == MsgHandlerResult.returnOne) {
            return cast(LRESULT) res;
        }
        switch (message) { 
            case WM_CREATE: 
            break;                   
            case WM_DESTROY:                               
            break;
            case WM_PAINT: 
                PAINTSTRUCT ps;                
                HDC hdc = BeginPaint(hWnd, &ps); 
                scope(exit) EndPaint(hWnd, &ps);               
                if (self.mImage) { 
                    self.mImage.draw(hdc, self.mRect.left, self.mRect.top, 
                                    self.mRect.right - self.mRect.left, 
                                    self.mRect.bottom - self.mRect.top);
                } else {
                    // If no image, fill with background color
                    // print("No image to draw, filling with background color");
                    HBRUSH hbr = CreateSolidBrush(self.mBackColor.cref);
                    FillRect(hdc, &ps.rcPaint, hbr);
                    DeleteObject(hbr);
                }
                return 0;
            break;

            case WM_ERASEBKGND:
                // We handle everything in WM_PAINT, so suppress background erase
                return 1;

            case WM_SIZE:
                if (self) {
                    if (self.mSizeMode != PictureSizeMode.autoSize) self.invalidate();
                }
            break;
            default: break;
        }
    } 
    catch (Exception e){}    
    return DefWindowProcW(hWnd, message, wParam, lParam);
}