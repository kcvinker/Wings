module wings.groupbox;
// GroupBox class -  Created on : 24-May-22 10:59:01 AM

import wings.d_essentials;
import wings.wings_essentials;


int gbNumber = 1;
DWORD gb_style = WS_CHILD | WS_VISIBLE | BS_GROUPBOX | BS_NOTIFY | BS_TOP |
                WS_OVERLAPPED| WS_CLIPCHILDREN| WS_CLIPSIBLINGS;
DWORD gb_exstyle = WS_EX_RIGHTSCROLLBAR| WS_EX_TRANSPARENT| WS_EX_CONTROLPARENT;
private wchar[] mClassName = ['B','u','t','t','o','n', 0];

class GroupBox : Control {

    this(Window parent, string txt, int x, int y, int w, int h) {
        mixin(repeatingCode);
        mControlType = ControlType.groupBox;
        mText = txt;
        mStyle = gb_style; // WS_CHILD | WS_VISIBLE | BS_GROUPBOX | BS_NOTIFY | BS_TOP;
        mExStyle = gb_exstyle; // WS_EX_TRANSPARENT | WS_EX_CONTROLPARENT;
        mBackColor = parent.mBackColor;
        this.mName = format("%s_%d", "GroupBox_", gbNumber);
        this.mParent.mControls ~= this;
        this.mCtlId = Control.stCtlId;
        ++Control.stCtlId;
        ++gbNumber;
    }

    this(Window parent, string txt, int x, int y) {
        this(parent, txt, x, y, 150, 150);
    }

    this(Window parent, string txt) {
        this(parent, txt, 20, 20, 150, 150);
    }

    override void createHandle() {
        //if (this.mBackColor.value == this.parent.mBackColor.value) this.isPaintBkg = true;
        this.mBkBrush = CreateSolidBrush(this.mBackColor.cref);
        this.mPen = CreatePen(PS_SOLID, 2, this.mBackColor.cref );
        this.createHandleInternal(mClassName.ptr);
        if (this.mHandle) {
            this.setSubClass(&gbWndProc);
            this.getTextBounds();

        }
    }

    override final void text(string value) {
        this.mText = value;
        if (this.mIsCreated) this.getTextBounds();
        this.checkRedrawNeeded();
    }


    private :
        HBRUSH mBkBrush;
        HPEN mPen;
        bool isPaintBkg;
        int mTxtWidth;

        void getTextBounds() {
            HDC hdc = GetDC(this.mHandle);
            scope(exit) ReleaseDC(this.mHandle, hdc);
            SIZE ss;
            SelectObject(hdc, this.mFont.handle);
            GetTextExtentPoint32(hdc, this.mText.toUTF16z, cast(int)this.mText.length, &ss );
            this.mTxtWidth = ss.cx + 8;
        }



        void drawText() {
            HDC hdc = GetDC(this.mHandle);
            scope(exit) ReleaseDC(this.mHandle, hdc);
            int yp = 11;
            SetBkMode(hdc, TRANSPARENT);

            SelectObject(hdc, this.mPen);
            MoveToEx(hdc, 10, yp, null);
            LineTo(hdc, this.mTxtWidth, yp);

            SelectObject(hdc, this.font.handle);
            SetTextColor(hdc, this.mForeColor.cref);
            TextOutW(hdc, 10, 0, this.mText.toUTF16z, cast(int)this.mText.length);

        }

        // void drawTextDblBuff() {
        //     RECT rc;
        //     SIZE ss;
        //     int yp = 11;
        //     HDC hdc = GetDC(this.mHandle);
        //     SelectObject(hdc, this.mFont.handle);
        //     GetTextExtentPoint32(hdc, this.mTmpText.toUTF16z, this.mTmpText.length, &ss );
        //     ss.cx += 10;
        //     // ss.cy += 10;
        //     HDC dcMem = CreateCompatibleDC(hdc);
        //     int ndcMem = SaveDC(dcMem);
        //     HBITMAP hbm = CreateCompatibleBitmap(hdc, ss.cx, ss.cy);
        //     scope(exit) {
        //         RestoreDC(dcMem, ndcMem);
        //         DeleteObject(hbm);
        //         DeleteDC(dcMem);
        //         ReleaseDC(this.mHandle, hdc);
        //     }
        //     SelectObject(dcMem, hbm);
        //     BitBlt(dcMem, 0, 0, ss.cx, ss.cy, hdc, 10, 0, SRCCOPY);

        //     SelectObject(dcMem, this.mPen);
        //     MoveToEx(dcMem, 10, yp, null);
        //     LineTo(dcMem, ss.cx, yp);
        //     SetRect(&rc, 10, 0, ss.cx, ss.cy);
        //     SetBkMode(dcMem, TRANSPARENT);
        //     SelectObject(dcMem, this.mFont.handle);
        //     SetTextColor(dcMem, this.mForeColor.cref);
        //     DrawTextW(dcMem, this.mTmpText.toUTF16z, -1, &rc, DT_CENTER|DT_SINGLELINE );
        //     // TextOutW(dcMem, 10, 0, this.mTmpText.toUTF16z, this.mTmpText.length);
        //     BitBlt(hdc, 10, 0, ss.cx, ss.cy, dcMem, 0, 0, SRCCOPY);
        // }

        void finalize(UINT_PTR scID) { // private
            // This is our destructor. Clean all the dirty stuff
            DeleteObject(this.mBkBrush);
            DeleteObject(this.mPen);
            RemoveWindowSubclass(this.mHandle, &gbWndProc, scID);
            // this.remSubClass(scID);
        }


} // End of GroupBox class

extern(Windows)
private LRESULT gbWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData)  {
    try {
        GroupBox gb = getControl!GroupBox(refData);
        //  gb.log(message);
        switch (message) {
            case WM_DESTROY : gb.finalize(scID); break;
            // case WM_PAINT : gb.paintHandler(); break;
            case WM_SETFOCUS : gb.setFocusHandler(); break;
            case WM_KILLFOCUS : gb.killFocusHandler(); break;
            case WM_LBUTTONDOWN : gb.mouseDownHandler(message, wParam, lParam); break;
            case WM_LBUTTONUP : gb.mouseUpHandler(message, wParam, lParam); break;
            case CM_LEFTCLICK : gb.mouseClickHandler(); break;
            case WM_RBUTTONDOWN : gb.mouseRDownHandler(message, wParam, lParam); break;
            case WM_RBUTTONUP : gb.mouseRUpHandler(message, wParam, lParam); break;
            case CM_RIGHTCLICK : gb.mouseRClickHandler(); break;
            case WM_MOUSEWHEEL : gb.mouseWheelHandler(message, wParam, lParam); break;
            case WM_MOUSEMOVE : gb.mouseMoveHandler(message, wParam, lParam); break;
            case WM_MOUSELEAVE : gb.mouseLeaveHandler(); break;
            case WM_GETTEXTLENGTH: return 0;


            case WM_ERASEBKGND :
                if (gb.mDrawFlag ) {
                    auto hdc = cast(HDC) wParam;
                    RECT rc = gb.clientRect();
                    FillRect(hdc, &rc, gb.mBkBrush);
                    return 1;
                }
            break;

            case WM_PAINT:
                auto ret = DefSubclassProc(hWnd, message, wParam, lParam);
                gb.drawText();
                return ret;
            break;



            default : return DefSubclassProc(hWnd, message, wParam, lParam); break;
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

