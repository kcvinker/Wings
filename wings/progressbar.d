
module wings.progressbar;
// ProbgressBar class -  Created on : 21-Jan-23 02:30:01 AM

import wings.d_essentials;
import wings.wings_essentials;


int pgbNumber = 1 ;
DWORD pgbStyle = WS_CHILD | WS_VISIBLE | PBS_SMOOTH | WS_OVERLAPPED;
DWORD pgbExStyle = 0;

class ProgressBar : Control {

    this(Window parent, int x, int y, int w, int h) {
        mixin(repeatingCode);
        mControlType = ControlType.progressBar ;
        mStyle = pgbStyle; // WS_CHILD | WS_VISIBLE | BS_GROUPBOX | BS_NOTIFY | BS_TOP ;
        mExStyle = pgbExStyle; // WS_EX_TRANSPARENT | WS_EX_CONTROLPARENT ;
		mBarStyle = ProgressBarStyle.blockStyle;
		mMinValue = 0;
		mMaxValue = 100;
		mStep = 1;


        mClsName = "msctls_progress32" ;
        this.mName = format("%s_%d", "ProgressBar_", pgbNumber);
        ++pgbNumber;
    }

    this(Window parent, int x, int y) { this(parent, x, y, 180, 25);}
    this(Window parent) { this(parent, 20, 20, 180, 25);}

    final void create() {
		if (this.mBarStyle == ProgressBarStyle.MarqueeStyle) this.mStyle |= PBS_MARQUEE;
		if (this.mVertical) this.mStyle |= PBS_VERTICAL;
        this.createHandle();
        if (this.mHandle) {
            this.setSubClass(&pgbWndProc);
            if (this.mMinValue != 0 || this.mMaxValue != 100)
                this.sendMsg(PBM_SETRANGE32, this.mMinValue, this.mMaxValue);

			this.sendMsg(PBM_SETSTEP, this.mStep, 0);
        }
    }

	final void increment() {if (this.mIsCreated) this.sendMsg(PBM_STEPIT, 0, 0);}

	mixin finalProperty!("step", this.mStep);
	mixin finalProperty!("minValue", this.mMinValue);
	mixin finalProperty!("maxValue", this.mMaxValue);

	final void value(int value) {
		if (this.mIsCreated) { this.sendMsg(PBM_SETPOS, value, 0);}
	}
	final int value() {return this.mValue;}


    private :
		ProgressBarStyle mBarStyle;
        bool mVertical;
        int mMinValue, mMaxValue, mStep, mValue;

        // void finalize(UINT_PTR scID) { // private
        //     // This is our destructor. Clean all the dirty stuff
        //     DeleteObject(this.mBkBrush) ;
        //     DeleteObject(this.mPen);
        //     this.remSubClass(scID);
        // }






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

            default : return DefSubclassProc(hWnd, message, wParam, lParam) ; break;
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

