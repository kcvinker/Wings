
module wings.checkbox;

import wings.d_essentials;
import wings.wings_essentials;
import std.stdio;



private int cbNumber = 1;
private wchar[] mClassName = ['B','u','t','t','o','n', 0];
/**
 * CheckBox : Control
 */
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

	this(Window parent, string txt, int x, int y, int w, int h, bool autoc = false, EventHandler checkFn = null)
    {
        mixin(repeatingCode);
        mAutoSize = true;
        mControlType = ControlType.checkBox;
        mText = txt;
        mStyle = WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX;
        mExStyle = WS_EX_LTRREADING | WS_EX_LEFT;
        mTxtStyle = DT_SINGLELINE | DT_VCENTER;
        mBackColor = parent.mBackColor;
        this.mName = format("%s_%d", "CheckBox_", cbNumber);
        this.mParent.mControls ~= this;
        this.mCtlId = Control.stCtlId;
        ++Control.stCtlId;
        ++cbNumber;
        if (checkFn) this.onMouseClick = checkFn;
        if (autoc) this.createHandle();
    }

    this(Window parent, bool autoc = false, EventHandler checkFn = null) {
    	string txt = format("CheckBox_%s", cbNumber);
    	this(parent, txt, 20, 20, 50, 20, autoc, checkFn);
    }

    this(Window parent, string txt, bool autoc = false, EventHandler checkFn = null)
    {
        this(parent, txt, 20, 20, 50, 20, autoc, checkFn);
    }

    this (Window parent, string txt, int x, int y, bool autoc = false, EventHandler checkFn = null)
    {
        this(parent, txt, x, y, 50, 20, autoc, checkFn);
    }

    // Create the handle of CheckBox
    override void createHandle()
    {
    	this.setCbStyles();
        this.createHandleInternal(mClassName.ptr);
        if (this.mHandle) {
            this.setSubClass(&cbWndProc);
            this.setCbSize();
        }
    }


	final override string text() {return this.mText;}
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
        HBRUSH mBkBrush;
        bool mRightAlign;


		void setCbStyles()
        { // Private
            // We need to set some checkbox styles
			if (this.mRightAlign) {
				this.mStyle |= BS_RIGHTBUTTON;
				this.mTxtStyle |= DT_RIGHT;
			}
		}

        void setCbSize()
        { // Private
            // We need to find the width & hight to provide the auto size feature.
            SIZE ss;
            this.sendMsg(BCM_GETIDEALSIZE, 0, &ss);
            this.mWidth = ss.cx;
            this.mHeight = ss.cy;
            MoveWindow(this.mHandle, this.mXpos, this.mYpos, ss.cx, ss.cy, true);
        }

        void finalize(UINT_PTR scID)
        { // Package
            // This is our destructor. Clean all the dirty stuff
            DeleteObject(this.mBkBrush);
            RemoveWindowSubclass(this.mHandle, &cbWndProc, scID);
            // this.remSubClass(scID);
        }
}

extern(Windows)
private LRESULT cbWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                            UINT_PTR scID, DWORD_PTR refData)
{
    try {
        CheckBox cb = getControl!CheckBox(refData);
        switch (message) {
            case WM_DESTROY : cb.finalize(scID); break;
            case WM_PAINT : cb.paintHandler(); break;
            case WM_SETFOCUS : cb.setFocusHandler(); break;
            case WM_KILLFOCUS : cb.killFocusHandler(); break;
            case WM_LBUTTONDOWN : cb.mouseDownHandler(message, wParam, lParam); break;
            case WM_LBUTTONUP : cb.mouseUpHandler(message, wParam, lParam); break;
            case CM_LEFTCLICK : cb.mouseClickHandler(); break;
            case WM_RBUTTONDOWN : cb.mouseRDownHandler(message, wParam, lParam); break;
            case WM_RBUTTONUP : cb.mouseRUpHandler(message, wParam, lParam); break;
            case CM_RIGHTCLICK : cb.mouseRClickHandler(); break;
            case WM_MOUSEWHEEL : cb.mouseWheelHandler(message, wParam, lParam); break;
            case WM_MOUSEMOVE : cb.mouseMoveHandler(message, wParam, lParam); break;
            case WM_MOUSELEAVE : cb.mouseLeaveHandler(); break;

            case CM_CTLCOMMAND :
				// writefln("CM_CTLCOMMAND in cb %s", 1);
                cb.mChecked = cast(bool) cb.sendMsg(BM_GETCHECK, 0, 0);
                if (cb.onCheckedChanged) {
                    auto ea = new EventArgs();
                    cb.onCheckedChanged(cb, ea);
                }
            break;

            case CM_COLOR_STATIC :
                // We need to use this message to change the back color.
                // There is no other ways to change the back color.
                auto hdc = cast(HDC) wParam;
                SetBkMode(hdc, TRANSPARENT);
                cb.mBkBrush = CreateSolidBrush(cb.mBackColor.cref);
                return cast(LRESULT) cb.mBkBrush;
            break;

            case CM_NOTIFY :
                // We need to use this message to draw the fore color.
                // There is no other ways to change the text color.

                auto nmc = cast(NMCUSTOMDRAW *) lParam;
                // writefln("dwDrawStage %s", BST_UNCHECKED);
                switch (nmc.dwDrawStage) {
                    case CDDS_PREERASE :
                        return CDRF_NOTIFYPOSTERASE;
                        break;
                    case CDDS_PREPAINT :
                        auto rct = nmc.rc;
                        if (!cb.mRightAlign) { // Adjusing rect. Otherwise, text will be drawn upon the check area
                            rct.left += 18;
                        } else {rct.right -= 18;}
                        SetTextColor(nmc.hdc, cb.mForeColor.cref);
                        DrawText(nmc.hdc, cb.text.toUTF16z, -1, &rct, cb.mTxtStyle);
                        return CDRF_SKIPDEFAULT;
                        break;
                    default:  break;
                } break;

            default : return DefSubclassProc(hWnd, message, wParam, lParam); break;
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

