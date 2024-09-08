// Created on: 24-May-2022 05:53:28 PM
/*==============================================Label Docs=====================================
    Constructor:        
        this(Form parent)
        this(Form parent, string txt)
        this(Form parent, int x, int y)
        this(Form parent, string txt, int x, int y)
        this(Form parent, string txt, int x, int y, int w, int h)

	Properties:
		Label inheriting all Control class properties	
        autoSize        : bool
        borderStyle     : LabelBorder enum [See enums.d]
			
    Methods:
        createHandle
        
    Events:
        All public events inherited from Control class. (See controls.d)       
=============================================================================================*/
module wings.label; 
import std.algorithm;
import wings.d_essentials;
import wings.wings_essentials;

private wchar[] mClassName = ['S', 't', 'a', 't', 'i', 'c', 0];
enum DWORD lbStyle = WS_VISIBLE | WS_CHILD | WS_CLIPCHILDREN | WS_CLIPSIBLINGS | SS_NOTIFY;

class Label: Control
{
    this(Form parent, string txt, int x, int y, int w, int h)
    {
        mixin(repeatingCode);
        mText = txt;
        ++lblNumber;
        mControlType = ControlType.label;
        mTxtAlign = TextAlignment.midLeft;
        mStyle = lbStyle;
        mExStyle = 0;
        mAutoSize = true;
        mBackColor = parent.mBackColor;
        mForeColor(defForeColor);
        this.mName = format("%s_%d", "Label+", lblNumber);
        this.mParent.mControls ~= this;
        this.mCtlId = Control.stCtlId;
        ++Control.stCtlId;
        if (parent.mAutoCreate) this.createHandle();
        //mBorder = LabelBorder.singleLine;
    }

    this(Form parent) { this(parent, format("Label_", lblNumber), 20, 20, 0, 0); }
    this(Form parent, int x, int y)
    {
        this(parent, format("Label_", lblNumber), x, y, 0, 0);
    }
    this(Form parent, string txt) { this(parent, txt, 20, 20, 0, 0); }
    this(Form parent, string txt, int x, int y)
    {
        this(parent, txt, x, y, 0, 0);
    }

    override void createHandle()
    {
        if (this.mBorder != LabelBorder.noBorder) adjustBorder();
        this.mBkBrush = CreateSolidBrush(this.mBackColor.cref);
        this.checkForAutoSize();
        this.createHandleInternal(mClassName.ptr);
        if (this.mHandle) {
            if (this.mAutoSize) this.calculateAutoSize();
            this.setSubClass(&lblWndProc);
        }
    }

    mixin finalProperty!("autoSize", this.mAutoSize);
    mixin finalProperty!("borderStyle", this.mBorder);

    final override string text() {return this.mText;}
    final override void text(string value)
    {
        this.mText = value;
        if (this.mIsCreated) {
            SetWindowTextW(this.mHandle, value.toUTF16z);
            if (this.mAutoSize) calculateAutoSize;
        }
    }

    // EventHandler selectionChanged;

    private:
        bool mAutoSize;
        bool mMultiLine;
        bool mRightAlign;
        LabelBorder mBorder;
        TextAlignment mTxtAlign;
        DWORD dwTxtAlign;
        static int lblNumber;

        void adjustAlignment() // Private
        { 
            final switch (this.mTxtAlign) {
                case TextAlignment.topLeft: this.dwTxtAlign = DT_TOP | DT_LEFT; break;
                case TextAlignment.topCenter: this.dwTxtAlign = DT_TOP | DT_CENTER; break;
                case TextAlignment.topRight: this.dwTxtAlign = DT_TOP | DT_RIGHT; break;

                case TextAlignment.midLeft: this.dwTxtAlign = DT_VCENTER | DT_LEFT; break;
                case TextAlignment.center: this.dwTxtAlign = DT_VCENTER | DT_CENTER; break;
                case TextAlignment.midRight: this.dwTxtAlign = DT_VCENTER | DT_RIGHT; break;

                case TextAlignment.bottomLeft: this.dwTxtAlign = DT_BOTTOM | DT_LEFT; break;
                case TextAlignment.bottomCenter: this.dwTxtAlign = DT_BOTTOM | DT_CENTER; break;
                case TextAlignment.bottomRight: this.dwTxtAlign = DT_BOTTOM | DT_RIGHT; break;
            }
            if (this.mMultiLine) {
                this.dwTxtAlign |= DT_WORDBREAK;
            } else {
                this.dwTxtAlign |= DT_SINGLELINE;
            }
        }

        void adjustBorder()
        { // Private
            if (this.mBorder == LabelBorder.sunkenBorder) {
                this.mStyle |= SS_SUNKEN;
            } else {
                this.mStyle |= WS_BORDER;
            }
        }

        void checkForAutoSize()
        { // Private
            if (any([this.mMultiLine, this.width != 0, this.mHeight != 0 ])) this.mAutoSize = false;
            if (!this.mAutoSize) {
                if (this.mWidth == 0) this.mWidth = 100;
                if (this.mHeight == 0) this.mHeight = 30;
            }
            //print("aut size", this.mAutoSize);
        }

        // void calculateAutoSize() { // private
            // //auto wtxt = this.mText.toUTF16z;
            // auto hdc = GetDC(this.mHandle);
            // SIZE ss;
            // SelectObject(hdc, this.font.handle);
            // GetTextExtentPoint32(hdc, this.mText.toUTF16z, cast(int) this.mText.length, &ss );
            // ReleaseDC(this.mHandle, hdc);
            // this.mWidth = ss.cx + 3;
            // this.mHeight = ss.cy;
            // SetWindowPos(this.mHandle, null, this.mXpos, this.mYpos, this.mWidth, this.mHeight, SWP_NOMOVE);
            // InvalidateRect(this.mHandle, null, false);
            // this.getRightAndBottom();
        // }

        void finalize(UINT_PTR scID)
        { 
            // This is our destructor. Clean all the dirty stuff
            DeleteObject(this.mBkBrush);
            RemoveWindowSubclass(this.mHandle, &lblWndProc, scID);
        }

} // End of Label Class

extern(Windows)
private LRESULT lblWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                                UINT_PTR scID, DWORD_PTR refData)
{
    try {
        switch (message) {
            case WM_DESTROY: 
                Label lbl = getControl!Label(refData);
                lbl.finalize(scID); 
            break;
            case WM_PAINT: 
                Label lbl = getControl!Label(refData);
                lbl.paintHandler(); 
            break;
            case WM_SETFOCUS: 
                Label lbl = getControl!Label(refData);
                lbl.setFocusHandler(); 
            break;
            case WM_KILLFOCUS: 
                Label lbl = getControl!Label(refData);
                lbl.killFocusHandler(); 
            break;
            case WM_LBUTTONDOWN: 
                Label lbl = getControl!Label(refData);
                lbl.mouseDownHandler(message, wParam, lParam); 
            break;
            case WM_LBUTTONUP: 
                Label lbl = getControl!Label(refData);
                lbl.mouseUpHandler(message, wParam, lParam); 
            break;
            case WM_RBUTTONDOWN: 
                Label lbl = getControl!Label(refData);
                lbl.mouseRDownHandler(message, wParam, lParam); 
            break;
            case WM_RBUTTONUP: 
                Label lbl = getControl!Label(refData);
                lbl.mouseRUpHandler(message, wParam, lParam); 
            break;
            case WM_MOUSEWHEEL: 
                Label lbl = getControl!Label(refData);
                lbl.mouseWheelHandler(message, wParam, lParam); 
            break;
            case WM_MOUSEMOVE: 
                Label lbl = getControl!Label(refData);
                lbl.mouseMoveHandler(message, wParam, lParam); 
            break;
            case WM_MOUSELEAVE: 
                Label lbl = getControl!Label(refData);
                lbl.mouseLeaveHandler(); 
            break;
            case CM_COLOR_STATIC:
                Label lbl = getControl!Label(refData);
                auto hdc = cast(HDC) wParam;
                if (lbl.mDrawFlag & 1) SetTextColor(hdc, lbl.mForeColor.cref);
                SetBkColor(hdc, lbl.mBackColor.cref);
                return cast(LRESULT)lbl.mBkBrush;
            break;

            default: return DefSubclassProc(hWnd, message, wParam, lParam);
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

