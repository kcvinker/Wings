
module wings.radiobutton; // Created on : 23-July-22 11:43:46 AM


import wings.d_essentials;
import wings.wings_essentials;

private int rbNumber = 1 ;

/**
 * RadioButton : Control
 */
class RadioButton : Control
{
	this (Window parent, string txt, int x, int y, int w, int h)
    {
        mixin(repeatingCode);
        mAutoSize = true ;
        mControlType = ControlType.radioButton ;
        mText = txt ;
        mStyle = WS_CHILD | WS_VISIBLE | BS_AUTORADIOBUTTON ;
        mExStyle = WS_EX_LTRREADING | WS_EX_LEFT ;
        mTxtStyle = DT_SINGLELINE | DT_VCENTER  ;
        mBackColor = parent.mBackColor ;

        mClsName = "Button" ;
        this.mName = format("%s_%d", "RadioButton_", rbNumber);
        ++rbNumber;
    }

    this (Window parent, string txt, int x, int y) {this(parent, txt, x, y, 0, 0);}

    void create() {
    	this.setRbStyle();
    	this.createHandle();
    	if (this.mHandle) {
            this.setSubClass(&rbWndProc) ;
            this.setRbSize() ;
            if (this.mChecked) this.sendMsg(BM_SETCHECK, 0x0001, 0) ;
        }
    }

    EventHandler onStateChanged;


    private :
    bool mChecked ;
	bool mAutoSize ;
	bool mChkOnClk;
	uint mTxtStyle ;
	HBRUSH mBkBrush ;
    bool mRightAlign ;

    void setRbStyle() {
    	if (this.mRightAlign) {
			this.mStyle |= BS_RIGHTBUTTON ;
			this.mTxtStyle |= DT_RIGHT ;
		}
		if (this.mChkOnClk) this. mStyle ^= BS_AUTORADIOBUTTON;


    }

    void setRbSize() { // Private
        // We need to find the width & hight to provide the auto size feature.
        SIZE ss ;
        this.sendMsg(BCM_GETIDEALSIZE, 0, &ss);
        this.mWidth = ss.cx;
        this.mHeight = ss.cy;
        MoveWindow(this.mHandle, this.mXpos, this.mYpos, ss.cx, ss.cy, true) ;
    }

    void finalize(UINT_PTR subid) { // private
        DeleteObject(this.mBkBrush);
        RemoveWindowSubclass(this.mHandle, &rbWndProc, subid);
    }
}



extern(Windows)
private LRESULT rbWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData) {

    try {
        RadioButton rb = getControl!RadioButton(refData)  ;
        switch (message) {
            case WM_DESTROY : rb.finalize(scID); break ;
            case CM_COLOR_STATIC :
            	auto hdc = cast(HDC) wParam;
                SetBkMode(hdc, TRANSPARENT);
                return toLresult(CreateSolidBrush(rb.mBackColor.cref));
            break;

            case CM_CTLCOMMAND :
            	if (HIWORD(wParam) == 0) {
            		rb.mChecked = cast(bool) rb.sendMsg(BM_GETCHECK, 0, 0);
            		if (rb.onStateChanged) rb.onStateChanged(rb, new EventArgs());
            	}
            break;
            //case WM_SETFONT :
            //    print("WM_SETFONT rcvd"); break;

            case CM_NOTIFY:
                auto nmcd = getNmcdPtr(lParam);
                switch (nmcd.dwDrawStage) {
                    case CDDS_PREERASE:
                        return CDRF_NOTIFYPOSTERASE;
                    break;
                    case CDDS_PREPAINT:
                        RECT rct = nmcd.rc;
                        if (rb.mRightAlign) { rct.right -= 18;} else {rct.left += 18;}
                        SetTextColor(nmcd.hdc, rb.mForeColor.cref);
                        DrawTextW(nmcd.hdc, rb.text.toUTF16z, -1, &rct, rb.mTxtStyle);
                        return CDRF_SKIPDEFAULT;
                    break;
                    default: break;
                }
            break;

            case WM_PAINT : rb.paintHandler(); break;
            case WM_SETFOCUS : rb.setFocusHandler(); break;
            case WM_KILLFOCUS : rb.killFocusHandler(); break;
            case WM_LBUTTONDOWN : rb.mouseDownHandler(message, wParam, lParam); break ;
            case WM_LBUTTONUP : rb.mouseUpHandler(message, wParam, lParam); break ;
            case CM_LEFTCLICK : rb.mouseClickHandler(); break;
            case WM_RBUTTONDOWN : rb.mouseRDownHandler(message, wParam, lParam); break;
            case WM_RBUTTONUP : rb.mouseRUpHandler(message, wParam, lParam); break;
            case CM_RIGHTCLICK : rb.mouseRClickHandler(); break;
            case WM_MOUSEWHEEL : rb.mouseWheelHandler(message, wParam, lParam); break;
            case WM_MOUSEMOVE : rb.mouseMoveHandler(message, wParam, lParam); break;
            case WM_MOUSELEAVE : rb.mouseLeaveHandler(); break;

            default : return DefSubclassProc(hWnd, message, wParam, lParam) ;
        }

    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}