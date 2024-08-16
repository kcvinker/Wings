module wings.events;
import wings.controls : Control;
import core.sys.windows.winuser;
import core.sys.windows.windef;
import core.sys.windows.windows;
import std.utf;


import wings.enums;
import wings.date_and_time;
import wings.commons;
import wings.menubar : MenuItem;
import wings.form : Form;

import std.stdio;

immutable uint um_single_Click = WM_USER + 1;

alias EventHandler = void delegate(Control sender, EventArgs e);
alias KeyEventHandler = void delegate(Control sender, KeyEventArgs e);
alias KeyPressEventHandler = void delegate(Control sender, KeyPressEventArgs e);
alias MouseEventHandler = void delegate(Control sender, MouseEventArgs e);
alias SizeEventHandler = void delegate(Control sender, SizeEventArgs e);
alias PaintEventHandler = void delegate(Control sender, PaintEventArgs e);
alias DateTimeEventHandler = void delegate(Control sender, DateTimeEventArgs e);
alias HotKeyEventHandler = void delegate(Control sender, HotKeyEventArgs e);
alias MenuEventHandler = void delegate(MenuItem sender, EventArgs e);
alias ThreadMsgHandler = void delegate(WPARAM wpm, LPARAM lpm);
alias TimerTickHandler = void delegate(Form win, EventArgs e);
alias SampleHandler = void delegate(Control sender, EventArgs e);



WORD getKeyStateWparam(WPARAM wp) {return cast(WORD) LOWORD(wp);}

/// A base class for all events
class EventArgs { bool handled; bool cancel; }

/// Special events for mouse related messages
class MouseEventArgs : EventArgs
{
    final MouseButton mouseButton() {return this.mButton;}
    final MouseButtonState shiftKeyState() {return this.mShiftKey;}
    final MouseButtonState ctrlKeyState() {return this.mCtrlKey;}
    final int xPos() {return this.mX;}
    final int yPos() {return this.mY;}
    final int delta() {return this.mDelta;}

    this(UINT msg, WPARAM wp, LPARAM lp) {
        const auto fwKeys = getKeyStateWparam(wp);
       // writeln("fw_keys ", fwKeys);
        this.mDelta = GET_WHEEL_DELTA_WPARAM(wp);

        switch (fwKeys) {   // IMPORTANT*********** Work here --> change 4 to 5, 8 to 9 etc
            case 4 :
                this.mShiftKey = MouseButtonState.pressed;
                break;
            case 8 :
                this.mCtrlKey = MouseButtonState.pressed;
                break;
            case 16 :
                this.mButton = MouseButton.middle;
                break;
            case 32 :
                this.mButton = MouseButton.xButton1;
                break;
            default : break;
        }

        switch (msg) {
            case WM_MOUSEWHEEL, WM_MOUSEMOVE, WM_MOUSEHOVER, WM_NCHITTEST :
                this.mX = getXFromLp(lp);
                this.mY = getYFromLp(lp);
                break;
            case WM_LBUTTONDOWN, WM_LBUTTONUP :
                this.mButton = MouseButton.left;
                this.mX = getXFromLp(lp);
                this.mY = getYFromLp(lp);
                break;
            case WM_RBUTTONDOWN, WM_RBUTTONUP :
                this.mButton = MouseButton.right;
                this.mX = getXFromLp(lp);
                this.mY = getYFromLp(lp);
                break;
            default : break;
        }
    }

    private :
        int mX;
        int mY;
        int mDelta;
        MouseButton    mButton;
        MouseButtonState mShiftKey;
        MouseButtonState mCtrlKey;
        // POINT location;
        // int clicks;
}


class KeyEventArgs : EventArgs
{
    final bool altPressed() {return this.mAltPressed;}
    final bool ctrlPressed() {return this.mCtrlPressed;}
    final bool shiftPressed() {return this.mShiftPressed;}
    final bool suppressKey() {return this.mSuppressKeyPress;}
    final int keyValue() {return this.mKeyValue;}
    final Key keyCode() {return this.mKeyCode;}
    final Key modifierKey() {return this.mModifier;}

    this(WPARAM wp) {
        this.mKeyCode = cast(Key) wp;
        switch (this.mKeyCode) {
        	case Key.shift :
        		this.mShiftPressed = true;
        		this.mModifier = Key.shiftModifier;
        		break;
        	case Key.ctrl :
        		this.mCtrlPressed = true;
        		this.mModifier = Key.ctrlModifier;
        		break;
        	case Key.alt :
            	this.mAltPressed = true;
            	this.mModifier = Key.altModifier;
            	break;
            default : break;
        }
        this.mKeyValue = this.mKeyCode;
    }

    private :
        bool mAltPressed;
        bool mCtrlPressed;
        bool mShiftPressed;
        bool mSuppressKeyPress;
        int mKeyValue;
        Key mKeyCode;
        Key mModifier;
    }


class KeyPressEventArgs : EventArgs
{
	char keyChar;
	this(WPARAM wp) {this.keyChar = cast(char) wp;}
}


class SizeEventArgs : EventArgs
{
    final RECT windowRect() {return this.mWindowRect;}
    final SizedPosition sizedOn() {return this.mSizedOn;}
    final Area clientArea() {return this.mClientArea;}

    this(uint uMsg, WPARAM wp, LPARAM lp) {
        if (uMsg == WM_SIZING) {
            this.mSizedOn = cast(SizedPosition) wp;
            this.mWindowRect = *(cast(RECT *) lp);
        } else {
            this.mClientArea.width = LOWORD(lp);
            this.mClientArea.height = HIWORD(lp);
        }
    }

    private :
        RECT mWindowRect;
        SizedPosition mSizedOn;
        Area mClientArea;

}

class PaintEventArgs : EventArgs
{
    final PAINTSTRUCT* paintStruct() {return this.mPaintInfo;}
    this(PAINTSTRUCT* ps) {
        this.mPaintInfo = ps;
    }
    private :
        PAINTSTRUCT* mPaintInfo;
}

class DateTimeEventArgs : EventArgs
{
    import std.conv;
    final string dateString() {return this.mDateString;}
    final SYSTEMTIME* dateStruct() {return this.mDateStruct;}

    this(LPCWSTR dtpStr) { this.mDateString = to!string(dtpStr); } //!(const(wchar)*)`
    private :
        string mDateString;
        SYSTEMTIME* mDateStruct;
}


class HotKeyEventArgs : EventArgs
{
    this(WPARAM wp, LPARAM lp) {
        this.mHotKeyID = cast(HotKeyId) wp;
        if ((lp & 1) == 1) this.mIsAlt = true;
        if ((lp & 2) == 2) this.mIsCtrl = true;
        if ((lp & 4) == 4) this.mIsShift = true;
        if ((lp & 8) == 8) this.mIsWin = true;
    }

    final bool isAltPressed() {return this.mIsAlt;}
    final bool isCtrlPressed() {return this.mIsCtrl;}
    final bool isShiftPressed() {return this.mIsShift;}
    final bool isWinPressed() {return this.mIsWin;}
    final HotKeyId hotKeyID() {return this.mHotKeyID;}

    private :
        HotKeyId mHotKeyID;
        bool mIsAlt, mIsCtrl, mIsShift, mIsWin;


}