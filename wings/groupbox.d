module wings.groupbox;
// GroupBox class -  Created on : 24-May-22 10:59:01 AM

import wings.d_essentials;
import wings.wings_essentials;


int gbNumber = 1 ;
DWORD gb_style = WS_CHILD | WS_VISIBLE | BS_GROUPBOX | BS_NOTIFY | BS_TOP |
                WS_OVERLAPPED| WS_CLIPCHILDREN| WS_CLIPSIBLINGS;
DWORD gb_exstyle = WS_EX_RIGHTSCROLLBAR| WS_EX_TRANSPARENT| WS_EX_CONTROLPARENT;

class GroupBox : Control {

    this(Window parent, string txt, int x, int y, int w, int h) {
        //mWidth = w ;
        //mHeight = h ;
        //mXpos = x ;
        //mYpos = y ;
        //mParent = parent ;
        //mFont = parent.font ;
        mixin(repeatingCode);
        mControlType = ControlType.groupBox ;
        mText = txt ;
        mStyle = gb_style; // WS_CHILD | WS_VISIBLE | BS_GROUPBOX | BS_NOTIFY | BS_TOP ;
        mExStyle = gb_exstyle; // WS_EX_TRANSPARENT | WS_EX_CONTROLPARENT ;
        mBackColor = parent.mBackColor ;

        mClsName = "Button" ;
        this.mName = format("%s_%d", "GroupBox_", gbNumber);
        ++gbNumber;
    }

    this(Window parent, string txt, int x, int y) {
        this(parent, txt, x, y, 150, 150);
    }

    this(Window parent, string txt) {
        this(parent, txt, 20, 20, 150, 150);
    }

    final void create() {
        //if (this.mBackColor.value == this.parent.mBackColor.value) this.isPaintBkg = true;
        this.mBkBrush = CreateSolidBrush(this.mBackColor.cref);
        this.mPen = CreatePen(PS_SOLID, 2, this.mBackColor.cref ); //0x000015ff
        this.mTmpText = this.mText;
        this.mText = "";
        this.createHandle();
        if (this.mHandle) {
            this.setSubClass(&gbWndProc);
            // RedrawWindow(this.mHandle, null, null, RDW_INTERNALPAINT | RDW_NOCHILDREN);

        }
    }

    // override final void backColor(uint value) {
    //     this.mBackColor = Color(value);
    //     // this.isPaintBkg = true;
    //     if ((this.mDrawFlag & 2) != 2 ) this.mDrawFlag += 2;
    //     if (this.mIsCreated) this.mBkBrush = CreateSolidBrush(this.mBackColor.cref);
    //     this.checkRedrawNeeded();
    // }
    // override final backColor() {

    private :
        HBRUSH mBkBrush;
        HPEN mPen;
        bool isPaintBkg;
        string mTmpText;



        void drawText() {
            HDC hdc = GetDC(this.mHandle);
            scope(exit) ReleaseDC(this.mHandle, hdc);
            // RECT rc;
            SIZE ss;
            int yp = 11;
            SetBkMode(hdc, TRANSPARENT);
            SelectObject(hdc, this.mFont.handle);
            GetTextExtentPoint32(hdc, this.mTmpText.toUTF16z, this.mTmpText.length, &ss );
            SelectObject(hdc, this.mPen);
            MoveToEx(hdc, 10, yp, null);
            LineTo(hdc, ss.cx + 10, yp);
            // SetRect(&rc, 10, 0, ss.cx + 10, ss.cy + 10);

            SetTextColor(hdc, this.mForeColor.cref);

            TextOutW(hdc, 10, 0, this.mTmpText.toUTF16z, this.mTmpText.length);

            // DrawText(hdc, this.mTmpText.toUTF16z, -1, &rc, DT_CENTER|DT_SINGLELINE );

        }

        void drawTextDblBuff() {
            RECT rc;
            SIZE ss;
            int yp = 11;
            HDC hdc = GetDC(this.mHandle);
            SelectObject(hdc, this.mFont.handle);
            GetTextExtentPoint32(hdc, this.mTmpText.toUTF16z, this.mTmpText.length, &ss );
            ss.cx += 10;
            // ss.cy += 10;
            HDC dcMem = CreateCompatibleDC(hdc);
            int ndcMem = SaveDC(dcMem);
            HBITMAP hbm = CreateCompatibleBitmap(hdc, ss.cx, ss.cy);
            scope(exit) {
                RestoreDC(dcMem, ndcMem);
                DeleteObject(hbm);
                DeleteDC(dcMem);
                ReleaseDC(this.mHandle, hdc);
            }
            SelectObject(dcMem, hbm);
            BitBlt(dcMem, 0, 0, ss.cx, ss.cy, hdc, 10, 0, SRCCOPY);

            SelectObject(dcMem, this.mPen);
            MoveToEx(dcMem, 10, yp, null);
            LineTo(dcMem, ss.cx, yp);
            SetRect(&rc, 10, 0, ss.cx, ss.cy);
            SetBkMode(dcMem, TRANSPARENT);
            SelectObject(dcMem, this.mFont.handle);
            SetTextColor(dcMem, this.mForeColor.cref);
            DrawTextW(dcMem, this.mTmpText.toUTF16z, -1, &rc, DT_CENTER|DT_SINGLELINE );
            // TextOutW(dcMem, 10, 0, this.mTmpText.toUTF16z, this.mTmpText.length);
            BitBlt(hdc, 10, 0, ss.cx, ss.cy, dcMem, 0, 0, SRCCOPY);
        }

        void finalize(UINT_PTR scID) { // private
            // This is our destructor. Clean all the dirty stuff
            DeleteObject(this.mBkBrush) ;
            DeleteObject(this.mPen);
            RemoveWindowSubclass(this.mHandle, &gbWndProc, scID);
            // this.remSubClass(scID);
        }


} // End of GroupBox class

extern(Windows)
private LRESULT gbWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData)  {
    try {
        GroupBox gb = getControl!GroupBox(refData) ;
        //  gb.log(message);
        switch (message) {
            case WM_DESTROY : gb.finalize(scID); break;
            // case WM_PAINT : gb.paintHandler(); break;
            case WM_SETFOCUS : gb.setFocusHandler(); break;
            case WM_KILLFOCUS : gb.killFocusHandler(); break;
            case WM_LBUTTONDOWN : gb.mouseDownHandler(message, wParam, lParam); break ;
            case WM_LBUTTONUP : gb.mouseUpHandler(message, wParam, lParam); break ;
            case CM_LEFTCLICK : gb.mouseClickHandler(); break;
            case WM_RBUTTONDOWN : gb.mouseRDownHandler(message, wParam, lParam); break;
            case WM_RBUTTONUP : gb.mouseRUpHandler(message, wParam, lParam); break;
            case CM_RIGHTCLICK : gb.mouseRClickHandler(); break;
            case WM_MOUSEWHEEL : gb.mouseWheelHandler(message, wParam, lParam); break;
            case WM_MOUSEMOVE : gb.mouseMoveHandler(message, wParam, lParam); break;
            case WM_MOUSELEAVE : gb.mouseLeaveHandler(); break;

            // case CM_COLOR_EDIT :
            // //     gb.log("cm ctl rcvd");
            // //     auto hdc = cast(HDC) wParam;
            // //     SetBkMode(hdc, TRANSPARENT) ;
            // //     gb.mBkBrush = CreateSolidBrush(gb.mBackColor.cref);
            // //     if (gb.mForeColor.value != 0x000000) SetTextColor(hdc, gb.mForeColor.cref) ;
            //     return cast(LRESULT) gb.mBkBrush;
            // // break ;

            // case CM_COLOR_STATIC: return cast(LRESULT) gb.mBkBrush; break;
            //     // // gb.log("CM_COLOR_STATIC rcvd");
            //     // auto hdc = cast(HDC) wParam;
            //     // // gb.mBkBrush = CreateSolidBrush(gb.mBackColor.cref);
            //     // if ((gb.mDrawFlag & 1) == 1) {
            //     //     // gb.log("text colored");
            //     //     SetTextColor(hdc, gb.mForeColor.cref);
            //     // }
            //     // SetBkMode(hdc, TRANSPARENT) ;
            //     // if (gb.mBackColor.value != gb.parent.mBackColor.value) SetBkColor(hdc, gb.mBackColor.cref);
            //     // return cast(LRESULT) gb.mBkBrush;
            //     // return cast(LRESULT) CreateSolidBrush(gb.parent.mBackColor.cref);
            //     return cast(LRESULT) gb.mBkBrush;


            // break;

            case WM_ERASEBKGND :  // TODO : We don't need to do this. Use WM_CTLCOLORSTATIC, and return an HBRUSH
                if (gb.mDrawFlag ) {
                    auto hdc = cast(HDC) wParam;
                    RECT rc = gb.clientRect();
                    rc.bottom -= 2;
                    rc.top += 10;
                    FillRect(hdc, &rc, gb.mBkBrush);

                    return 1 ;
                }
            break ;

            case WM_PAINT:
                auto ret = DefSubclassProc(hWnd, message, wParam, lParam);
                gb.drawText();
                // gb.drawTextDblBuff();
                return ret;
            break;



            default : return DefSubclassProc(hWnd, message, wParam, lParam) ; break;
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

