// ProbgressBar class -  Created on : 21-Jan-23 02:30:01 AM
/*==============================================ProgressBar Docs=====================================
    Constructor:            
        this(Form parent) 
        this(Form parent, int x, int y)   
        this(Form parent, int x, int y, int w, int h)

    Properties:
        ProgressBar inheriting all Control class properties    
        minValue
        maxValue
        step
        value
        state
        style
        decimalPrecision
        showPercentage
            
    Methods:
        createHandle    
        increment
        step
        startMarquee
        stopMarquee    
        
    Events:
        All public events inherited from Control class. (See controls.d)     
=============================================================================================*/

module wings.progressbar;

import wings.d_essentials;
import wings.wings_essentials;
import std.stdio;
import std.conv;

enum DWORD pgbStyle = WS_CHILD | WS_VISIBLE | PBS_SMOOTH | WS_OVERLAPPED;
enum PBM_SETSTATE  = (WM_USER+16);
enum PBM_GETSTATE  = 0x0420;
enum DWORD pgbExStyle = 0;
enum wchar[] mClassName = ['m','s','c','t','l','s','_','p','r','o','g','r','e','s','s','3','2', 0];
enum ProgressBarState {normal = 1, error, paused}
enum ProgressBarStyle {blockStyle, marqueeStyle}

class ProgressBar : Control
{
    this(Form parent, int x, int y, int w, int h)
    {
        mixin(repeatingCode);
        ++pgbNumber;
        mControlType = ControlType.progressBar;
        this.mFont = new Font(parent.font);
        mStyle = pgbStyle; 
        mExStyle = pgbExStyle; 
		mBarStyle = ProgressBarStyle.blockStyle;
        mState = ProgressBarState.normal;
		mMinValue = 0;
		mMaxValue = 100;
		mStep = 1;
        mSpeed = 30;
        this.percFmt = "%d%%";
        this.mDeciPrec = 0;
        mForeColor(0x000000);
        this.mName = format("%s_%d", "ProgressBar_", pgbNumber);
        this.mParent.mControls ~= this;
        this.mCtlId = Control.stCtlId;
        ++Control.stCtlId;
        if (parent.mAutoCreate) this.createHandle();
    }

    this(Form parent, int x, int y) { this(parent, x, y, 180, 25);}
    this(Form parent) { this(parent, 20, 20, 180, 25);}

    override void createHandle()
    {
		if (this.mBarStyle == ProgressBarStyle.marqueeStyle) this.mStyle |= PBS_MARQUEE;
		if (this.mVertical) this.mStyle |= PBS_VERTICAL;
        this.createHandleInternal(mClassName.ptr);
        if (this.mHandle) {
            this.setSubClass(&pgbWndProc);
            if (this.mMinValue != 0 || this.mMaxValue != 100) {
                this.sendMsg(PBM_SETRANGE32, this.mMinValue, this.mMaxValue);
            }
			this.sendMsg(PBM_SETSTEP, this.mStep, 0);
        }
    }

	final void increment()
    {
        if (this.mIsCreated) {
            this.mValue = (this.value == this.mMaxValue) ? this.mStep : this.mValue + this.mStep;
            this.sendMsg(PBM_STEPIT, 0, 0);
        }
    }

    final void minValue(int value)
    {
        this.mMinValue = value;
        if (this.mIsCreated) {
            this.sendMsg(PBM_SETRANGE32, this.mMinValue, this.mMaxValue);
        }
    }

    final int minValue() {return this.mMinValue;}

    final void maxValue(int value)
    {
        this.mMaxValue = value;
        if (this.mIsCreated) {
            this.sendMsg(PBM_SETRANGE32, this.mMinValue, this.mMaxValue);
        }
    }

    final int maxValue() {return this.mMaxValue;}

    final void step(int value)
    {
        if (value >= this.mMinValue && value <= this.mMaxValue) {
            this.mStep = value;
            if (this.mIsCreated) {this.sendMsg(PBM_SETSTEP, this.mStep, 0);}
        } else {
            throw new Exception("Step value is not in reange");
        }
    }

    final int step() {return this.mStep;}


	final void value(int ivalue)
    {
        // writeln("value proc ", value);
        if (this.mIsCreated) {
            this.mValue = ivalue;
            auto oldval = this.sendMsg(PBM_SETPOS, ivalue, 0);
            // if (oldval > 0) this.mValue = ivalue;
            // writefln("value changed, old value %d", oldval);
        }

	}

	final int value() {return this.mValue;}

    final void state(ProgressBarState value)
    {
        this.mState = value;
        if (this.mIsCreated) this.sendMsg(PBM_SETSTATE, value, 0);
    }

    final ProgressBarState state()
    {
        if (this.mIsCreated) {
            this.mState = cast(ProgressBarState) this.sendMsg(PBM_GETSTATE, 0, 0);
        }
        return this.mState;
    }

    final void style(ProgressBarStyle value)
    {
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
			    if (value == ProgressBarStyle.marqueeStyle) {
                    auto x = this.sendMsg(PBM_SETMARQUEE, 1, this.mSpeed);
                    // writefln("pgb sndmsg rslt %d", x);
                } else {
                    this.sendMsg(PBM_SETMARQUEE, 0, 0);
                }
            }
        }
        this.mBarStyle = value;
    }

    final ProgressBarStyle style() {return this.mBarStyle;}

    // final void formatString(string value) {this.percFmt = value;} // %d%% = int, %0.2f%% = double
    // final string formatString() {return this.percFmt;}

    final void decimalPrecision(int value)
    {
        this.mDeciPrec = value;
        if (value == 0) {
            this.percFmt = "%d%%";
        } else if(value > 0) {
            this.percFmt = "%0." ~ value.to!string ~ "g%%";
            // writefln("perc fmt %s", this.percFmt);
        }
    }

    final int decimalPrecision() {return this.mDeciPrec;}

    final void startMarquee()
    {
        if (this.mIsCreated) {
            this.style = ProgressBarStyle.marqueeStyle;
            // auto x = this.sendMsg(PBM_SETMARQUEE, 1, this.mSpeed);
            // writefln("pgb sndmsg rslt %d", x);
        }
    }

    final void stopMarquee()
    {
        if (this.mIsCreated) {
            // this.sendMsg(PBM_SETMARQUEE, 0, 0);
            this.style = ProgressBarStyle.blockStyle;
        }
    }

    final void showPercentage(bool value) {this.mShowPerc = value;}
    final bool showPercentage() {return this.mShowPerc;}


    private :
		ProgressBarStyle mBarStyle;
        ProgressBarState mState;
        bool mVertical, mShowPerc;
        int mMinValue, mMaxValue, mStep, mValue, mSpeed, mDeciPrec;
        string percFmt;
        static int pgbNumber;

        LRESULT drawPercentage(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
        {
            auto ret = DefSubclassProc(hWnd, message, wParam, lParam);
            // writefln("showperc %s, bar style %s", this.mShowPerc, this.mBarStyle);
            if (this.mShowPerc && this.mBarStyle == ProgressBarStyle.blockStyle) {
                SIZE ss;
                double perc = (cast(double)(this.mValue * 100)) / cast(double)this.mMaxValue;
                string vtext = this.mDeciPrec > 0 ? format(this.percFmt, perc) : format(this.percFmt, cast(int)perc);
                // writefln("perc %f, %s, %s", perc, this.mValue, this.mMaxValue);

                auto wtxt = vtext.toUTF16z;
                HDC hdc = GetDC(hWnd);
                scope(exit) ReleaseDC(hWnd, hdc);

                SelectObject(hdc, this.font.handle);
                GetTextExtentPoint32(hdc, wtxt, cast(int)vtext.length, &ss);

                int x = (this.mWidth - ss.cx) / 2;
                int y = (this.mHeight - ss.cy) / 2;
                SetBkMode(hdc, TRANSPARENT);
                SetTextColor(hdc, this.mForeColor.cref);
                TextOut(hdc, x, y, wtxt, cast(int)vtext.length );
                // return ret;
            } else {
                // return DefSubclassProc(hw, msg, wp, lp);
                writeln("243 else part");
            }
            return ret;
        }


} // End of ProgressBar class

extern(Windows)
private LRESULT pgbWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                                UINT_PTR scID, DWORD_PTR refData)
{
    try {
        //  gb.log(message);
        switch (message) {
            case WM_DESTROY : 
                // ProgressBar pgb = getControl!ProgressBar(refData);
                RemoveWindowSubclass(hWnd, &pgbWndProc, scID); 
            break;
            case WM_LBUTTONDOWN : 
                ProgressBar pgb = getControl!ProgressBar(refData);
                pgb.mouseDownHandler(message, wParam, lParam); 
            break;
            case WM_LBUTTONUP : 
                ProgressBar pgb = getControl!ProgressBar(refData);
                pgb.mouseUpHandler(message, wParam, lParam); 
            break;
            case WM_RBUTTONDOWN : 
                ProgressBar pgb = getControl!ProgressBar(refData);
                pgb.mouseRDownHandler(message, wParam, lParam); 
            break;
            case WM_RBUTTONUP : 
                ProgressBar pgb = getControl!ProgressBar(refData);
                pgb.mouseRUpHandler(message, wParam, lParam); 
            break;
            case WM_MOUSEWHEEL : 
                ProgressBar pgb = getControl!ProgressBar(refData);
                pgb.mouseWheelHandler(message, wParam, lParam); 
            break;
            case WM_MOUSEMOVE : 
                ProgressBar pgb = getControl!ProgressBar(refData);
                pgb.mouseMoveHandler(message, wParam, lParam); 
            break;
            case WM_MOUSELEAVE : 
                ProgressBar pgb = getControl!ProgressBar(refData);
                pgb.mouseLeaveHandler(); 
            break;
            case WM_PAINT :
                ProgressBar pgb = getControl!ProgressBar(refData);
                return pgb.drawPercentage(hWnd, message, wParam, lParam);
            break;
            default : return DefSubclassProc(hWnd, message, wParam, lParam); 
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

