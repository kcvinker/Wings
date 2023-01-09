module wings.groupbox;
// GroupBox class -  Created on : 24-May-22 10:59:01 AM

import wings.d_essentials;
import wings.wings_essentials;


int gbNumber = 1 ;

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
        mStyle = WS_CHILD | WS_VISIBLE | BS_GROUPBOX | BS_NOTIFY | BS_TEXT | BS_TOP ;
        mExStyle =WS_EX_TRANSPARENT | WS_EX_CONTROLPARENT ;
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
        if (this.mBackColor.value == this.parent.mBackColor.value) this.isPaintBkg = true;
        this.createHandle();
        if (this.mHandle) {
            this.setSubClass(&gbWndProc) ;
            //this.setCbSize() ;
        }
    }

    private :
        HBRUSH mBkBrush ;
        bool isPaintBkg ;

        void finalize(UINT_PTR scID) { // private
            // This is our destructor. Clean all the dirty stuff
            DeleteObject(this.mBkBrush) ;
            this.remSubClass(scID);
        }


} // End of GroupBox class

extern(Windows)
private LRESULT gbWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData)  {
    try {
        GroupBox gb = getControl!GroupBox(refData) ;
        switch (message) {
            case WM_DESTROY : gb.finalize(scID); break;
            case WM_PAINT : gb.paintHandler(); break;
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

            case CM_CTLCOLOR :
                auto hdc = cast(HDC) wParam;
                SetBkMode(hdc, TRANSPARENT) ;
                gb.mBkBrush = CreateSolidBrush(gb.mBackColor.reff);
                if (gb.mForeColor.value != 0x000000) SetTextColor(hdc, gb.mForeColor.reff) ;
                return cast(LRESULT) gb.mBkBrush;
            break ;

            case WM_ERASEBKGND :  // TODO : We don't need to do this. Use WM_CTLCOLORSTATIC, and return an HBRUSH
                if (gb.isPaintBkg) {
                    auto hdc = cast(HDC) wParam;
                    RECT rc ;
                    GetClientRect(gb.mHandle, &rc);
                    rc.bottom -= 2  ;
                    FillRect(hdc, &rc, CreateSolidBrush(gb.mBackColor.reff))  ;
                    return 1 ;
                }
            break ;

            default : return DefSubclassProc(hWnd, message, wParam, lParam) ; break;
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

