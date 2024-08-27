
module wings.radiobutton; // Created on: 23-July-22 11:43:46 AM

import wings.d_essentials;
import wings.wings_essentials;
import std.stdio;

class RadioButton: Control
{
	this (Form parent, string txt, int x, int y, int w, int h, EventHandler evtFn = null)
    {
        mixin(repeatingCode);
        ++rbNumber;
        mAutoSize = true;
        mControlType = ControlType.radioButton;
        mText = txt;
        mStyle = WS_CHILD | WS_VISIBLE | BS_AUTORADIOBUTTON;
        mExStyle = WS_EX_LTRREADING | WS_EX_LEFT;
        mTxtStyle = DT_SINGLELINE | DT_VCENTER;
        mBackColor = parent.mBackColor;
        this.mName = format("%s_%d", "RadioButton_", rbNumber);
        this.mParent.mControls ~= this;
        this.mCtlId = Control.stCtlId;
        ++Control.stCtlId;
        if (evtFn) this.onClick = evtFn;
        if (parent.mAutoCreate) this.createHandle();
    }

    this (Form parent, string txt, int x, int y, EventHandler evtFn = null)
    {
        this(parent, txt, x, y, 0, 0, evtFn);
    }

    override void createHandle()
    {
        import wings.buttons: btnClassName;
    	this.setRbStyle();
    	this.createHandleInternal(btnClassName.ptr);
    	if (this.mHandle) {
            this.setSubClass(&rbWndProc);
            this.setRbSize();
            if (this.mChecked) this.sendMsg(BM_SETCHECK, 0x0001, 0);
        }
    }

    EventHandler onStateChanged;

    private:
    bool mChecked;
	bool mAutoSize;
	bool mChkOnClk;
	uint mTxtStyle;
    bool mRightAlign;
    static int rbNumber;

    void setRbStyle()
    {
    	if (this.mRightAlign) {
			this.mStyle |= BS_RIGHTBUTTON;
			this.mTxtStyle |= DT_RIGHT;
		}
		if (this.mChkOnClk) this. mStyle ^= BS_AUTORADIOBUTTON;
    }

    void setRbSize() // Private
    {
        // We need to find the width & hight to provide the auto size feature.
        SIZE ss;
        this.sendMsg(BCM_GETIDEALSIZE, 0, &ss);
        this.mWidth = ss.cx + 20;
        this.mHeight = ss.cy;
        MoveWindow(this.mHandle, this.mXpos, this.mYpos, this.mWidth, this.mHeight, true);
        // auto x = MoveWindow(this.mHandle, this.mXpos, this.mYpos, this.mWidth, this.mHeight, true);
        // writefln("moving res %d", x);
    }

    void finalize(UINT_PTR subid) // private
    {
        DeleteObject(this.mBkBrush);
        RemoveWindowSubclass(this.mHandle, &rbWndProc, subid);
    }
}



extern(Windows)
private LRESULT rbWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                                UINT_PTR scID, DWORD_PTR refData)
{
    try {
        switch (message) {
            case WM_DESTROY: 
                RadioButton rb = getControl!RadioButton(refData);
                rb.finalize(scID); 
            break;
            case CM_COLOR_STATIC:
                RadioButton rb = getControl!RadioButton(refData);
            	auto hdc = cast(HDC) wParam;
                SetBkMode(hdc, TRANSPARENT);
                return toLresult(CreateSolidBrush(rb.mBackColor.cref));
            break;

            case CM_CTLCOMMAND:
                RadioButton rb = getControl!RadioButton(refData);
            	if (HIWORD(wParam) == 0) {
            		rb.mChecked = cast(bool) rb.sendMsg(BM_GETCHECK, 0, 0);
            		if (rb.onStateChanged) rb.onStateChanged(rb, new EventArgs());
            	}
            break;
            case CM_NOTIFY:
                RadioButton rb = getControl!RadioButton(refData);
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
            case WM_PAINT: 
                RadioButton rb = getControl!RadioButton(refData);
                rb.paintHandler(); 
            break;
            case WM_SETFOCUS: 
                RadioButton rb = getControl!RadioButton(refData);
                rb.setFocusHandler(); 
            break;
            case WM_KILLFOCUS: 
                RadioButton rb = getControl!RadioButton(refData);
                rb.killFocusHandler(); 
            break;
            case WM_LBUTTONDOWN: 
                RadioButton rb = getControl!RadioButton(refData);
                rb.mouseDownHandler(message, wParam, lParam); 
            break;
            case WM_LBUTTONUP: 
                RadioButton rb = getControl!RadioButton(refData);
                rb.mouseUpHandler(message, wParam, lParam); 
            break;
            case WM_RBUTTONDOWN: 
                RadioButton rb = getControl!RadioButton(refData);
                rb.mouseRDownHandler(message, wParam, lParam); 
            break;
            case WM_RBUTTONUP: 
                RadioButton rb = getControl!RadioButton(refData);
                rb.mouseRUpHandler(message, wParam, lParam); 
            break;
            case WM_MOUSEWHEEL: 
                RadioButton rb = getControl!RadioButton(refData);
                rb.mouseWheelHandler(message, wParam, lParam); 
            break;
            case WM_MOUSEMOVE: 
                RadioButton rb = getControl!RadioButton(refData);
                rb.mouseMoveHandler(message, wParam, lParam); 
            break;
            case WM_MOUSELEAVE: 
                RadioButton rb = getControl!RadioButton(refData);
                rb.mouseLeaveHandler(); 
            break;
            default: return DefSubclassProc(hWnd, message, wParam, lParam);
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}
