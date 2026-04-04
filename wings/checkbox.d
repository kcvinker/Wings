/*==============================================CheckBox Docs=====================================
Constructor:
    this(Form parent, EventHandler checkFn = null)
    this(Form parent, string txt, EventHandler checkFn = null)
    this (Form parent, string txt, int x, int y, EventHandler checkFn = null)
    this(Form parent, string txt, int x, int y, int w, int h, EventHandler checkFn = null)

	Properties:
		CheckBox inheriting all Control class properties		
		checked     : bool
        
    Methods:
        createHandle
        
    Events:
        All public events inherited from Control class. (See controls.d)
        EventHandler - void delegate(Object, EventArgs)
=============================================================================================*/

module wings.checkbox;

import wings.d_essentials;
import wings.wings_essentials;


class CheckBox : Control
{
    /// Get the checked state of CheckBox.
    final bool checked() {return this.mChecked;}

    /// Set the checked state of CheckBox.
    final void checked(bool value)
    {
        this.mChecked = value;
        if (this.mIsCreated) {
            int bState = value ? BST_CHECKED : BST_UNCHECKED;
            this.sendMsg(BM_SETCHECK, bState, 0 );
        }
    }

    EventHandler onCheckedChanged;

	this(Form parent, string txt, int x, int y, int w, int h, EventHandler checkFn = null)
    {
        mixin(repeatingCode);
        ++cbNumber;
        mAutoSize = true;
        mControlType = ControlType.checkBox;
        mText = txt;
        mStyle = WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX;
        mExStyle = WS_EX_LTRREADING | WS_EX_LEFT;
        mTxtStyle = DT_SINGLELINE | DT_VCENTER;
        mBackColor = parent.mBackColor;
        this.mFont = new Font(parent.font);
        this.mName = format("%s_%d", "CheckBox_", cbNumber);
        this.mParent.mControls ~= this;
        this.mCtlId = Control.stCtlId;
        this.mTextable = true;
        this.mHasFont = true;
        ++Control.stCtlId;        
        if (checkFn) this.onClick = checkFn;
        if (parent.mAutoCreate) this.createHandle();
    }

    this(Form parent, EventHandler checkFn = null) {
    	string txt = format("CheckBox_%s", cbNumber);
    	this(parent, txt, 20, 20, 50, 20, checkFn);
    }

    this(Form parent, string txt, EventHandler checkFn = null)
    {
        this(parent, txt, 20, 20, 50, 20, checkFn);
    }

    this (Form parent, string txt, int x, int y, EventHandler checkFn = null)
    {
        this(parent, txt, x, y, 50, 20, checkFn);
    }

    /// Create the handle of CheckBox
    override void createHandle()
    {
        import wings.buttons: btnClassName;
    	this.setCbStyles();
        this.createHandleInternal(btnClassName.ptr);
        if (this.mHandle) {
            this.setSubClass(&cbWndProc);
            this.setCbSize();
        }
    }

    /// Get the text of this checkbox.
	final override string text() {return this.mText;}

    /// Set the text for this checkbox.
    final override void text(string value)
    {
        this.mText = value;
        if (this.mIsCreated) {
            SetWindowTextW(this.mHandle, value.toUTF16z);
            if (this.mAutoSize) this.setCbSize;
        }
    }

   	private :
		bool mChecked;
		bool mAutoSize;
		uint mTxtStyle;
        bool mRightAlign;
        static int cbNumber;

		void setCbStyles() // Private
        { 
            // We need to set some checkbox styles
			if (this.mRightAlign) {
				this.mStyle |= BS_RIGHTBUTTON;
				this.mTxtStyle |= DT_RIGHT;
			}
		}

        void setCbSize() // Private
        { 
            // We need to find the width & hight to provide the auto size feature.
            SIZE ss;
            this.sendMsg(BCM_GETIDEALSIZE, 0, &ss);
            this.mWidth = ss.cx;
            this.mHeight = ss.cy;
            MoveWindow(this.mHandle, this.mXpos, this.mYpos, ss.cx, ss.cy, true);
        }

        void finalize(UINT_PTR scID) // Private
        { 
            // This is our destructor. Clean all the dirty stuff
            DeleteObject(this.mBkBrush);
            RemoveWindowSubclass(this.mHandle, &cbWndProc, scID);
        }
}

extern(Windows)
private LRESULT cbWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                            UINT_PTR scID, DWORD_PTR refData)
{
    try {
        CheckBox self = getControl!CheckBox(refData);
        auto res = self.commonMsgHandler(hWnd, message, wParam, lParam);
        if (res == MsgHandlerResult.callDefProc) {
            return DefSubclassProc(hWnd, message, wParam, lParam);
        } else if (res == MsgHandlerResult.returnZero || res == MsgHandlerResult.returnOne) {
            return cast(LRESULT) res;
        }
        switch (message) {
            case WM_DESTROY : 
                self.finalize(scID); 
            break;
            case WM_PAINT:
                self.paintHandler(); 
            break;
            case CM_CTLCOMMAND:
				// writefln("CM_CTLCOMMAND in self %s", 1);
                self.mChecked = cast(bool) self.sendMsg(BM_GETCHECK, 0, 0);
                if (self.onCheckedChanged) {
                    auto ea = new EventArgs();
                    self.onCheckedChanged(self, ea);
                }
            break;
            case CM_COLOR_STATIC:
                // We need to use this message to change the back color.
                // There is no other ways to change the back color.
                auto hdc = cast(HDC) wParam;
                SetBkMode(hdc, TRANSPARENT);
                self.mBkBrush = CreateSolidBrush(self.mBackColor.cref);
                return cast(LRESULT) self.mBkBrush;
            break;
            case CM_NOTIFY:
                // We need to use this message to draw the fore color.
                // There is no other ways to change the text color.
                auto nmc = cast(NMCUSTOMDRAW *) lParam;
                switch (nmc.dwDrawStage) {
                    case CDDS_PREERASE :
                        return CDRF_NOTIFYPOSTERASE;
                    break;
                    case CDDS_PREPAINT :
                        auto rct = nmc.rc;
                        if (!self.mRightAlign) { // Adjusing rect. Otherwise, text will be drawn upon the check area
                            rct.left += 18;
                        } else {rct.right -= 18;}
                        SetTextColor(nmc.hdc, self.mForeColor.cref);
                        DrawText(nmc.hdc, self.text.toUTF16z, -1, &rct, self.mTxtStyle);
                        return CDRF_SKIPDEFAULT;
                    break;
                    default: break;
                } 
            break;
            default : 
                return DefSubclassProc(hWnd, message, wParam, lParam); 
            break;
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

