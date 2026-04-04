
// Created on: 23-July-22 11:43:46 AM
/*==============================================RadioButton Docs=====================================
    Constructor:
        this (Form parent, string txt, int x, int y, EventHandler evtFn = null)
        this (Form parent, string txt, int x, int y, int w, int h, EventHandler evtFn = null)

	Properties:
		RadioButton inheriting all Control class properties	
        checked     : bool
			
    Methods:
        createHandle
        
        
    Events:
        All public events inherited from Control class. (See controls.d)
        EventHandler - void delegate(Control, EventArgs)
            onStateChanged       
=============================================================================================*/


module wings.radiobutton; 

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
        this.mFont = new Font(parent.font);
        mText = txt;
        mStyle = WS_CHILD | WS_VISIBLE | BS_AUTORADIOBUTTON;
        mExStyle = WS_EX_LTRREADING | WS_EX_LEFT;
        mTxtStyle = DT_SINGLELINE | DT_VCENTER;
        mBackColor = parent.mBackColor;
        this.mName = format("%s_%d", "RadioButton_", rbNumber);
        this.mParent.mControls ~= this;
        this.mCtlId = Control.stCtlId;
        this.mHasFont = true;
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

    final bool checked() {return this.mChecked;}
    final void checked(bool value) 
    {
        this.mChecked = value;
        if (this.mIsCreated) {
            this.sendMsg(BM_SETCHECK, cast(int)value, 0);
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
        RadioButton self = getControl!RadioButton(refData);
        auto res = self.commonMsgHandler(hWnd, message, wParam, lParam);
        if (res == MsgHandlerResult.callDefProc) {
            return DefSubclassProc(hWnd, message, wParam, lParam);
        } else if (res == MsgHandlerResult.returnZero || res == MsgHandlerResult.returnOne) {
            return cast(LRESULT) res;
        }
        switch (message) {
            case WM_DESTROY:                 
                self.finalize(scID); 
            break;
            case CM_COLOR_STATIC:
            	auto hdc = cast(HDC) wParam;
                SetBkMode(hdc, TRANSPARENT);
                return toLresult(CreateSolidBrush(self.mBackColor.cref));
            break;
            case CM_CTLCOMMAND:
            	if (HIWORD(wParam) == 0) {
            		self.mChecked = cast(bool) self.sendMsg(BM_GETCHECK, 0, 0);
            		if (self.onStateChanged) self.onStateChanged(self, new EventArgs());
            	}
            break;
            case CM_NOTIFY:
                auto nmcd = getNmcdPtr(lParam);
                switch (nmcd.dwDrawStage) {
                    case CDDS_PREERASE:
                        return CDRF_NOTIFYPOSTERASE;
                    break;
                    case CDDS_PREPAINT:
                        RECT rct = nmcd.rc;
                        if (self.mRightAlign) { rct.right -= 18;} else {rct.left += 18;}
                        SetTextColor(nmcd.hdc, self.mForeColor.cref);
                        DrawTextW(nmcd.hdc, self.text.toUTF16z, -1, &rct, self.mTxtStyle);
                        return CDRF_SKIPDEFAULT;
                    break;
                    default: break;
                }
            break;
            case WM_PAINT: 
                self.paintHandler(); 
            break;            
            default: return DefSubclassProc(hWnd, message, wParam, lParam);
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}
