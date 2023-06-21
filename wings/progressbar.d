
module wings.progressbar;
// ProbgressBar class -  Created on : 21-Jan-23 02:30:01 AM

import wings.d_essentials;
import wings.wings_essentials;
import std.stdio;



int pgbNumber = 1 ;
DWORD pgbStyle = WS_CHILD | WS_VISIBLE | PBS_SMOOTH | WS_OVERLAPPED;
enum PBM_SETSTATE  = (WM_USER+16);
enum PBM_GETSTATE  = 0x0420;
DWORD pgbExStyle = 0;
private wchar[] mClassName = ['m','s','c','t','l','s','_','p','r','o','g','r','e','s','s','3','2', 0];

enum ProgressBarState {normal = 1, error, paused}
enum ProgressBarStyle {blockStyle, marqueeStyle}

class ProgressBar : Control {

    this(Window parent, int x, int y, int w, int h) {
        mixin(repeatingCode);
        mControlType = ControlType.progressBar ;
        mStyle = pgbStyle; // WS_CHILD | WS_VISIBLE | BS_GROUPBOX | BS_NOTIFY | BS_TOP ;
        mExStyle = pgbExStyle; // WS_EX_TRANSPARENT | WS_EX_CONTROLPARENT ;
		mBarStyle = ProgressBarStyle.blockStyle;
        mState = ProgressBarState.normal;
		mMinValue = 0;
		mMaxValue = 100;
		mStep = 1;
        mSpeed = 30;
        mForeColor(0x000000);
        this.mName = format("%s_%d", "ProgressBar_", pgbNumber);
        this.mParent.mControls ~= this;
        this.mCtlId = Control.stCtlId;
        ++Control.stCtlId;
        ++pgbNumber;
    }

    this(Window parent, int x, int y) { this(parent, x, y, 180, 25);}
    this(Window parent) { this(parent, 20, 20, 180, 25);}

    override void createHandle() {
		if (this.mBarStyle == ProgressBarStyle.marqueeStyle) this.mStyle |= PBS_MARQUEE;
		if (this.mVertical) this.mStyle |= PBS_VERTICAL;
        this.createHandleInternal(mClassName.ptr);
        if (this.mHandle) {
            this.setSubClass(&pgbWndProc);
            if (this.mMinValue != 0 || this.mMaxValue != 100)
                this.sendMsg(PBM_SETRANGE32, this.mMinValue, this.mMaxValue);

			this.sendMsg(PBM_SETSTEP, this.mStep, 0);
        }
    }

	final void increment() {
        if (this.mIsCreated) {
            this.mValue = (this.value == this.mMaxValue) ? this.mStep : this.mValue + this.mStep;
            this.sendMsg(PBM_STEPIT, 0, 0);
        }
    }

    final void minValue(int value) {
        this.mMinValue = value;
        if (this.mIsCreated) {
            this.sendMsg(PBM_SETRANGE32, this.mMinValue, this.mMaxValue);
        }
    }

    final int minValue() {return this.mMinValue;}

    final void maxValue(int value) {
        this.mMaxValue = value;
        if (this.mIsCreated) {
            this.sendMsg(PBM_SETRANGE32, this.mMinValue, this.mMaxValue);
        }
    }

    final int maxValue() {return this.mMaxValue;}

    final void step(int value) {
        if (value >= this.mMinValue && value <= this.mMaxValue) {
            this.mStep = value;
            if (this.mIsCreated) {this.sendMsg(PBM_SETSTEP, this.mStep, 0);}
        } else {
            throw new Exception("Step value is not in reange");
        }
    }

    final int step() {return this.mStep;}


	final void value(int value) {
        if (value >= this.minValue && value <= this.mMaxValue) {
            this.mValue = value;
		    if (this.mIsCreated) { this.sendMsg(PBM_SETPOS, value, 0);}
        }
        else {
            throw new Exception("Value is not in reange");
        }
	}

	final int value() {return this.mValue;}

    final void state(ProgressBarState value) {
        this.mState = value;
        if (this.mIsCreated) {this.sendMsg(PBM_SETSTATE, value, 0);}
    }

    final ProgressBarState state() {
        if (this.mIsCreated) {
            this.mState = cast(ProgressBarState) this.sendMsg(PBM_GETSTATE, 0, 0);
        }
        return this.mState;
    }

    final void style(ProgressBarStyle value) {
        if (this.mBarStyle != value) {
            this.mValue = 0;
			if (value == ProgressBarStyle.blockStyle) {
				this.mStyle ^= PBS_MARQUEE;
				this.mStyle |= PBS_SMOOTH;
			} else {
				this.mStyle ^= PBS_SMOOTH;
				this.mStyle |= PBS_MARQUEE;
			}
			if (this.mIsCreated) {
                SetWindowLongPtr(this.mHandle, GWL_STYLE, cast(LONG_PTR)this.mStyle);
			    if (value == ProgressBarStyle.marqueeStyle) this.sendMsg(PBM_SETMARQUEE, 1, this.mSpeed);
            }
        }
        this.mBarStyle = value;
    }

    final ProgressBarStyle style() {return this.mBarStyle;}

    final void startMarquee() {
        if (this.mIsCreated && this.mBarStyle == ProgressBarStyle.marqueeStyle) {
            this.sendMsg(PBM_SETMARQUEE, 1, this.mSpeed);
        }
    }

    final void stopMarquee() {
        if (this.mIsCreated && this.mBarStyle == ProgressBarStyle.marqueeStyle) {
            this.sendMsg(PBM_SETMARQUEE, 0, 0);
        }
    }

    final void showPercentage(bool value) {this.mShowPerc = value;}
    final bool showPercentage() {return this.mShowPerc;}


    private :
		ProgressBarStyle mBarStyle;
        ProgressBarState mState;
        bool mVertical, mShowPerc;
        int mMinValue, mMaxValue, mStep, mValue, mSpeed;

        LRESULT drawPercentage(HWND hw, UINT msg, WPARAM wp, LPARAM lp) {
            if (this.mShowPerc && this.mBarStyle != ProgressBarStyle.marqueeStyle) {
                auto ret = DefSubclassProc(hw, msg, wp, lp);
                SIZE ss;
                string vtext = format("%s%%", this.value);
                auto wtext = vtext.toUTF16z;
                HDC hdc = GetDC(this.mHandle);
                scope(exit) ReleaseDC(this.mHandle, hdc);

                SelectObject(hdc, this.font.handle);
                GetTextExtentPoint32(hdc, wtext, vtext.length, &ss);

                int x = (this.mWidth - ss.cx) / 2;
                int y = (this.mHeight - ss.cy) / 2;
                SetBkMode(hdc, TRANSPARENT);
                SetTextColor(hdc, this.mForeColor.cref);
                TextOut(hdc, x, y, wtext, vtext.length );
                return ret;
            } else {
                return DefSubclassProc(hw, msg, wp, lp);
            }
        }


} // End of ProgressBar class

extern(Windows)
private LRESULT pgbWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData)  {
    try {
        ProgressBar pgb = getControl!ProgressBar(refData) ;
        //  gb.log(message);
        switch (message) {
            case WM_DESTROY : RemoveWindowSubclass(hWnd, &pgbWndProc, scID); break;
            // case WM_PAINT : pgb.paintHandler(); break;
            case WM_SETFOCUS : pgb.setFocusHandler(); break;
            case WM_KILLFOCUS : pgb.killFocusHandler(); break;
            case WM_LBUTTONDOWN : pgb.mouseDownHandler(message, wParam, lParam); break ;
            case WM_LBUTTONUP : pgb.mouseUpHandler(message, wParam, lParam); break ;
            case CM_LEFTCLICK : pgb.mouseClickHandler(); break;
            case WM_RBUTTONDOWN : pgb.mouseRDownHandler(message, wParam, lParam); break;
            case WM_RBUTTONUP : pgb.mouseRUpHandler(message, wParam, lParam); break;
            case CM_RIGHTCLICK : pgb.mouseRClickHandler(); break;
            case WM_MOUSEWHEEL : pgb.mouseWheelHandler(message, wParam, lParam); break;
            case WM_MOUSEMOVE : pgb.mouseMoveHandler(message, wParam, lParam); break;
            case WM_MOUSELEAVE : pgb.mouseLeaveHandler(); break;
            case WM_PAINT: pgb.drawPercentage(hWnd, message, wParam, lParam); break;

            default : return DefSubclassProc(hWnd, message, wParam, lParam) ; break;
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

