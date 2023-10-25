module wings.numberpicker; // Created on : 10-Jun-22 05:24:04 PM

import wings.d_essentials;
import wings.wings_essentials;
import std.conv;
import wings.clipboard;
import std.algorithm : clamp;
import std.stdio;
import std.datetime.stopwatch;


int npNumber = 1;
bool isNpCreated;
DWORD npStyle = WS_VISIBLE | WS_CHILD | UDS_ALIGNRIGHT | UDS_ARROWKEYS | UDS_AUTOBUDDY | UDS_HOTTRACK;
DWORD mTxtFlag = DT_SINGLELINE | DT_VCENTER | DT_CENTER | DT_NOPREFIX;
DWORD swp_flag = SWP_SHOWWINDOW | SWP_NOACTIVATE | SWP_NOZORDER;

class NumberPicker : Control
{
    this(Window parent, int x, int y, int w, int h, bool autoc = false, EventHandler evtFn = null)
    {
        if (!isNpCreated) {
            isNpCreated = true;
            appData.iccEx.dwICC = ICC_UPDOWN_CLASS;
            InitCommonControlsEx(&appData.iccEx);
        }

        mixin(repeatingCode);
        mControlType = ControlType.numberPicker;
        mMaxRange = 100;
        mMinRange = 0;
        mDeciPrec = 2;
        mStep = 1;
        mStyle = npStyle;
        mExStyle = 0x00000000;//WS_EX_LTRREADING | WS_EX_RTLREADING | WS_EX_CLIENTEDGE;   ES_LEFT := 0x0
        mBuddyStyle = WS_CHILD | WS_VISIBLE | ES_NUMBER | WS_TABSTOP| WS_BORDER;// | WS_CLIPCHILDREN;// WS_BORDER;
        mBuddyExStyle = WS_EX_LEFT | WS_EX_LTRREADING;//| WS_EX_STATICEDGE;//| WS_EX_LEFT;//WS_EX_LTRREADING | WS_EX_RTLREADING | WS_EX_LEFT;//| WS_EX_CLIENTEDGE;
        mBackColor(defBackColor);
        mForeColor(defForeColor);
        mFmtStr = "%.02f";
        mValue = mMinRange;
        this.mName = format("%s_%d", "NumberPicker_", npNumber);
        this.mParent.mControls ~= this;
        this.mCtlId = Control.stCtlId;
        ++Control.stCtlId;
        ++npNumber;
        if (evtFn != null) this.onValueChanged = evtFn;
        if (autoc) this.createHandle();
    }

    this(Window parent) {this(parent, 10, 10, 100, 27);}
    this(Window parent, int x, int y, bool autoc = false, EventHandler evntFn = null )
    {
        this(parent, x, y, 70, 27, autoc, evntFn);
    }

    override void createHandle()
    {
    	this.adjustNpStyles();
        this.createUpdown();
        this.createBuddy();
        if (this.mHandle && this.mBuddyHandle)
        {

            auto oldBuddy = cast(HWND)this.sendMsg(UDM_SETBUDDY, this.mBuddyHandle, 0); // set the edit as updown's buddy.
            this.sendMsg(UDM_SETRANGE32, cast(WPARAM) this.mMinRange, cast(LPARAM) this.mMaxRange);

            // Collecting both controls rects
            GetClientRect(this.mBuddyHandle, &this.mTBRect);
            GetClientRect(this.mHandle, &this.mUDRect);
            this.resizeBuddy();
            SendMessageW(oldBuddy, CM_BUDDY_RESIZE, 0, 0);
            this.getRightAndBottom();

            /*  This thing is a hack. The edit control is not turned on the...
                vertical alignment without setting the WS_BORDER style.
                But if we set that style, it will create a border around the edit.
                However, when we draw edges of the edit, 3 of the borders will be deleted.
                But, we need to manually erase the forth one.
                And drawing a line with background color is the hack. */

            //test_tb_rect();
            this.displayValue;
            ++Control.stCtlId;
            ++Control.mSubClassId;
        }
    }

    void test_tb_rect()
    {
        RECT rc;
        SendMessage(this.mBuddyHandle, EM_GETRECT, 0, cast(LPARAM) &rc);
        rc.top = 6;
        SendMessage(this.mBuddyHandle, EM_SETRECT, 0, cast(LPARAM) &rc);
    }

    //region properties

        final void minRange(double value)
        {
            this.mMinRange = value;
            if (this.mValue < value) this.mValue = value;
            if (this.mIsCreated)
            {
                this.sendMsg(UDM_SETRANGE32, this.mMinRange, this.mMaxRange);
            }
        }
        final double minRange() {return this.mMinRange;}

        final void maxRange(double value)
        {
            this.mMaxRange = value;
            if (this.mIsCreated)
            {
                this.sendMsg(UDM_SETRANGE32, this.mMinRange, this.mMaxRange);
            }
        }
        final double maxRange() {return this.mMaxRange;}

        final bool hideSelection() {return this.mHideSel;}
        final void hideSelection(bool value)
        {
            this.mHideSel = value;
            if (this.mIsCreated)
            {
                SendMessage(this.mBuddyHandle, EM_SETSEL, cast(WPARAM) -1, 0 );
            }
        }

        final bool buttonOnLeft() {return this.mBtnLeft;}
        final void buttonOnLeft(bool value)
        {
            this.mBtnLeft = value;
            if (this.mIsCreated)
            {
                // TODO - change window style using SetWindowLong function.
            }

        }

        final Alignment textAlign() {return this.mTxtPos;}
        final void textAlign(Alignment value)
        {
            this.mTxtPos = value;
            if (this.mIsCreated)
            {
                // TODO - change window style using SetWindowLong function.
            }

        }

        final bool hasSeperator() {return this.mHasSep;}
        final void hasSeperator(bool value)
        {
            this.mHasSep = value;
            if (this.mIsCreated)
            {
                // TODO - change window style using SetWindowLong function.
            }
        }

        final bool rotateValue() {return this.mAutoRotate;}
        final void rotateValue(bool value)
        {
            this.mAutoRotate = value;
            if (this.mIsCreated)
            {
                // TODO - change window style using SetWindowLong function.
            }
        }

        final double value() {return this.mValue;}
        final void value(double value)
        {
            this.mValue = value;
            if (this.mIsCreated) this.displayValue();
        }

        final double step() {return this.mStep;}
        final void step(double value)
        {
            this.mStep = value;
            if (this.mIsCreated)
            {
                // TODO - change window style using SetWindowLong function.
            }
        }

        final string formatString() {return this.mFmtStr;}
        final void formatString(string value)
        {
            this.mFmtStr = value;
            if (this.mIsCreated)
            {
                // TODO - change window style using SetWindowLong function.
            }
        }

        final int decimalPrecision() {return this.mDeciPrec;}
        final void decimalPrecision(int value)
        {
            this.mDeciPrec = value;
            if (value == 0)
            {
                this.mFmtStr = "%f";
            } else {
                this.mFmtStr = format("%%0%df", value);
            }

            if (this.mIsCreated)
            {
                // TODO - change window style using SetWindowLong function.
            }
        }

        mixin finalProperty!("hideCaret", this.mHideCaret);

        /+  Since, we are handling the mouse leave event specially,
            We need to use these three event handler props individually.
            We can't use parent's methods for these. +/
        final void onMouseEnter(EventHandler value)
        {
            this.mOnMouseEnter = value;
            this.mTrackMouseLeave = true;
        }

        final void onMouseLeave(EventHandler value)
        {
            this.mOnMouseLeave = value;
            this.mTrackMouseLeave = true;
        }

        final void onMouseMove(MouseEventHandler value)
        {
            this.mOnMouseMove = value;
            this.mTrackMouseLeave = true;
        }

    //endregion Properties

    EventHandler onValueChanged;
    PaintEventHandler onTextPaint;
    //alias uintptr = UINT_PTR;
    package :

    private :
    // region private members
        bool mEditStarted;
        bool mEditFinished;
        bool mHideSel;
        bool mHideCaret;
        bool mTrackMouseLeave;
        bool mBtnLeft;
        bool mHasSep;
        bool mAutoRotate;
        bool mKeyPressed;
        double mMinRange;
        double mMaxRange;
        double mValue;
        double mStep;
        double mEditedValue;
        string mFmtStr;
        string mEditedText;
        int mDeciPrec;
        int mLineX; // The x coordinate for drawing line over the border.
        DWORD mBuddyStyle;
        DWORD mBuddyExStyle;
        DWORD mTopEdgeFlag = BF_TOPLEFT;
        DWORD mBotEdgeFlag = BF_BOTTOM;
        HWND mBuddyHandle;
        uint mBuddySubClsID;
        uint mBuddyCid;
        SUBCLASSPROC mBuddySubClsProc;
        Alignment mTxtPos;
        HBRUSH mBkBrush;
        RECT mUDRect;
        RECT mTBRect;
        RECT mMyRect;
        EventHandler mOnMouseLeave;
        EventHandler mOnMouseEnter;
        MouseEventHandler mOnMouseMove;
        static wchar[] mUpdClassName = ['m', 's', 'c', 't', 'l', 's', '_', 'u', 'p', 'd', 'o', 'w', 'n', '3', '2', 0];
        static wchar[] mBuddyClassName = ['E','d','i','t', 0];
    // endregion private members

    // region private functions
        void adjustNpStyles() // Private
        {
            if (this.mBtnLeft)
            {
                this.mStyle ^= UDS_ALIGNRIGHT;
                this.mStyle |= UDS_ALIGNLEFT;
                this.mTopEdgeFlag = BF_TOP;
                this.mBotEdgeFlag = BF_BOTTOMRIGHT;
                if (this.mTxtPos == Alignment.left) this.mTxtPos = Alignment.right;
            }
            //if (!this.mHasSep) this.mStyle |= UDS_NOTHOUSANDS;

            switch (this.mTxtPos)
            {
                case Alignment.left : this.mBuddyStyle |= ES_LEFT; break;
                case Alignment.center : this.mBuddyStyle |= ES_CENTER; break;
                case Alignment.right : this.mBuddyStyle |= ES_RIGHT; break;
                default : break;
            }
        }

        void createUpdown()  // Private
        {
            // Creating the updown control only.
            this.mCtlId = Control.stCtlId;
            this.mMyRect = RECT(this.mXpos, this.mYpos, (this.mXpos + this.mWidth), (this.mYpos + this.mHeight));
            this.mHandle = CreateWindowEx( this.mExStyle,
                                            this.mUpdClassName.ptr,
                                            null,
                                            this.mStyle,
                                            0, 0, 0, 0,
                                            this.mParent.handle,
                                            cast(HMENU) this.mCtlId,
                                            appData.hInstance,
                                            null);
            if (this.mHandle)
            {
                ++Control.stCtlId; // Increasing protected static member for next control iD
                this.mIsCreated = true;
                this.setSubClass(&npWndProc);
                this.createLogFontInternal();
            }
        }

        void createBuddy()  // Private
        {
            // Creating buddy edit control

            this.mBuddyCid = Control.stCtlId;
            if (this.mBtnLeft) this.mWidth -= 2; // To match the size of a button right control.
            this.mBuddyHandle = CreateWindowEx( this.mBuddyExStyle,
                                                this.mBuddyClassName.ptr,
                                                null,
                                                this.mBuddyStyle,
                                                this.mXpos,
                                                this.mYpos,
                                                this.mWidth,
                                                this.mHeight,
                                                this.mParent.handle,
                                                cast(HMENU) this.mBuddyCid,
                                                appData.hInstance,
                                                null);
            if (this.mBuddyHandle)
            {
                this.mBuddySubClsID = Control.mSubClassId;
                SetWindowSubclass(this.mBuddyHandle, &buddyWndProc, UINT_PTR(this.mBuddySubClsID), this.toDwPtr());
                SendMessageW(this.mBuddyHandle, WM_SETFONT, cast(WPARAM) this.mFont.handle, cast(LPARAM) 1);
                ++Control.mSubClassId;
            }
        }

        void resizeBuddy()  // Private
        {
            // Place the edit control at proper coordinates
            if (this.mBtnLeft)
            {
                this.mLineX = this.mTBRect.left;
                SetWindowPos(this.mBuddyHandle, HWND_TOP,
                                (this.mXpos + this.mUDRect.right), this.mYpos,
                                this.mTBRect.right, this.mTBRect.bottom, swp_flag);
            } else {
                this.mLineX = this.mTBRect.right - 3;
                SetWindowPos(this.mBuddyHandle, HWND_TOP, this.mXpos, this.mYpos,
                                (this.mTBRect.right - 2), this.mTBRect.bottom, swp_flag);
            }
        }

        void setValueInternal(int delta)  // Private
        {
            double newValue = this.mValue + (delta * this.mStep);
            if (this.mAutoRotate) {
                if (newValue > this.mMaxRange)
                {
                    this.mValue = this.mMinRange;
                } else if (newValue < this.mMinRange) {
                    this.mValue = this.mMaxRange;
                } else {
                    this.mValue = newValue;
                }
            } else {
                this.mValue = clamp(newValue, this.mMinRange, this.mMaxRange);
            }
            this.displayValue;
        }

        void displayValue()  // Private
        {
            string newStr;
            if (this.mDeciPrec > 0)
            {
                newStr = format(this.mFmtStr, this.mValue);
            } else {
                newStr = format("%d", to!int(this.mValue));
            }
            SetWindowTextW(this.mBuddyHandle, newStr.toUTF16z);
        }

        bool isMouseOnMe()  // Private
        {
            // If this returns False, mouse_leave event will triggered
            // Since, updown control is a combo of an edit and button controls...
            // we have no better options to control the mouse enter & leave mechanism.
            // Now, we create an imaginary rect over the bondaries of these two controls.
            // If mouse is inside that rect, there is no mouse leave. Perfect hack.
            POINT pt;
            GetCursorPos(&pt);
            ScreenToClient(this.mParent.handle, &pt);
            auto res = PtInRect(&this.mMyRect, pt);
            return cast(bool) res;
        }

        void npMouseMoveHandler(UINT msg, WPARAM wp, LPARAM lp)  // Private
        {
            if (this.isMouseEntered)
            {
                if (this.mOnMouseMove)
                {
                    auto mea = new MouseEventArgs(msg, wp, lp);
                    this.mOnMouseMove(this, mea);
                }
            } else {
                this.isMouseEntered = true;
                if (this.mOnMouseEnter) this.mOnMouseEnter(this, new EventArgs());
            }
        }

        void finalize(UINT_PTR subClsId) // Private
        {
            if (this.mBkBrush) DeleteObject(this.mBkBrush);
            RemoveWindowSubclass(this.mHandle, &npWndProc, subClsId);
            // this.remSubClass(subClsId );
        }



    // endregion private functions


} // End of NumberPicker class


extern(Windows)
private LRESULT npWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                                UINT_PTR scID, DWORD_PTR refData)
{
    try
    {
        NumberPicker np = getControl!NumberPicker(refData);
        //printWinMsg(message);
        switch (message)
        {
            case WM_DESTROY : np.finalize(scID); break;

            case CM_NOTIFY :
                auto nm = cast(NMUPDOWN*) lParam;
                if (nm.hdr.code == UDN_DELTAPOS)
                writeln("delta pos");
                {
                    auto tbstr = np.getControlText(np.mBuddyHandle);
                    np.mValue = parse!double(tbstr);
                    np.setValueInternal(nm.iDelta);
                    if (np.onValueChanged) np.onValueChanged(np, new EventArgs());
                }
            break;

            case WM_MOUSELEAVE :
                if (np.mTrackMouseLeave)
                {
                    if (!np.isMouseOnMe())
                    {
                        np.isMouseEntered = false;
                        if (np.mOnMouseLeave) np.mOnMouseLeave(np, new EventArgs());
                    }
                }
            break;

            case WM_PAINT : np.paintHandler(); break;
            case WM_SETFOCUS : np.setFocusHandler(); break;
            case WM_KILLFOCUS : np.killFocusHandler(); break;
            case WM_LBUTTONDOWN : np.mouseDownHandler(message, wParam, lParam); break;
            case WM_LBUTTONUP : np.mouseUpHandler(message, wParam, lParam); break;
            case CM_LEFTCLICK : np.mouseClickHandler(); break;
            case WM_RBUTTONDOWN : np.mouseRDownHandler(message, wParam, lParam); break;
            case WM_RBUTTONUP : np.mouseRUpHandler(message, wParam, lParam); break;
            case CM_RIGHTCLICK : np.mouseRClickHandler(); break;
            case WM_MOUSEWHEEL : np.mouseWheelHandler(message, wParam, lParam); break;
            case WM_MOUSEMOVE : np.npMouseMoveHandler(message, wParam, lParam); break;

            default : return DefSubclassProc(hWnd, message, wParam, lParam);
        }
    }
    catch (Exception e) { writeln("error ", message);}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

extern(Windows)
private LRESULT buddyWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                                    UINT_PTR scID, DWORD_PTR refData)
{
    try
    {
        NumberPicker np = getControl!NumberPicker(refData);
        //printWinMsg(message);
        switch (message)
        {
            case WM_DESTROY : RemoveWindowSubclass(hWnd, &buddyWndProc, scID ); break;
            case WM_SETFOCUS : np.setFocusHandler(); break;
            case WM_KILLFOCUS : np.killFocusHandler(); break;
            case WM_LBUTTONDOWN : np.mouseDownHandler(message, wParam, lParam); break;
            //case WM_LBUTTONDBLCLK:
            //    InvalidateRect(hWnd, &np.mTBRect, true);
            //    break;
            case WM_LBUTTONUP : np.mouseUpHandler(message, wParam, lParam); break;
            case CM_LEFTCLICK : np.mouseClickHandler(); break;
            case WM_RBUTTONDOWN : np.mouseRDownHandler(message, wParam, lParam); break;
            case WM_RBUTTONUP : np.mouseRUpHandler(message, wParam, lParam); break;
            case CM_RIGHTCLICK : np.mouseRClickHandler(); break;
            case WM_MOUSEWHEEL : np.mouseWheelHandler(message, wParam, lParam); break;
            case WM_MOUSEMOVE : np.npMouseMoveHandler(message, wParam, lParam); break;

            case WM_PAINT :
                // Let the control paint it's basic stuff.
                DefSubclassProc(hWnd, message, wParam, lParam);

                /* We need WM_BORDER style to preserve the alignment of text in edit control.
                 * But that will cause a border around the edit control and it will separate...
                 * the updown and edit visualy. So we need to erase one border. It will be...
                 * either right side of the edit or left side of the edit, depends upon where...
                 * the bupown button locates. To erase the border, we just draw a line with...
                 * edit's back color. */
                HDC hdc = GetDC(hWnd);
                DrawEdge(hdc, &np.mTBRect, BDR_SUNKENOUTER, np.mTopEdgeFlag);
                DrawEdge(hdc, &np.mTBRect, BDR_RAISEDINNER, np.mBotEdgeFlag);
                auto fpen = CreatePen(PS_SOLID, 1, np.mBackColor.cref);
                scope(exit) DeleteObject(fpen);
                MoveToEx(hdc, np.mLineX, np.mTBRect.top + 1, null);
                SelectObject(hdc, fpen);
                LineTo(hdc, np.mLineX, np.mTBRect.bottom - 1);
                ReleaseDC(hWnd, hdc);
                return 1;
                //if (np.onPaint) {
                //    PAINTSTRUCT ps;
                //    BeginPaint(hWnd, &ps);
                //    auto pea = new PaintEventArgs(&ps);
                //    np.onTextPaint(np, pea);
                //    EndPaint(hWnd, &ps);
                //}
            break;

            case EM_SETSEL : return 1; break; // To eliminate the text selection
            case CM_COLOR_EDIT :
                if (np.mDrawFlag)
                {
                    auto hdc = cast(HDC) wParam;
                    if (np.mDrawFlag & 1) SetTextColor(hdc, np.mForeColor.cref);
                    np.mBkBrush = CreateSolidBrush(np.mBackColor.cref);
                    SetBkColor(hdc, np.mBackColor.cref);
                    return cast(LRESULT) np.mBkBrush;
                }
            break;

            case WM_KEYDOWN :
                np.mKeyPressed = true;
                np.keyDownHandler(wParam);
            break;

            case WM_KEYUP : np.keyUpHandler(wParam); break;
            case WM_CHAR : np.keyPressHandler(wParam); break;

            //case CM_TBTXTCHANGED :
            //    if (np.onValueChanged) {
            //        auto ea = new EventArgs();
            //        np.onValueChanged(np, ea);
            //    }
            //break;

            case WM_MOUSELEAVE :
                if (np.mTrackMouseLeave)
                {
                    if (!np.isMouseOnMe())
                    {
                        np.isMouseEntered = false;
                        if (np.mOnMouseLeave) np.mOnMouseLeave(np, new EventArgs());
                    }
                }
            break;

            case CM_CTLCOMMAND :
                auto nCode = HIWORD(wParam);
                if (nCode == EN_UPDATE)
                {
                    if (np.mHideCaret) HideCaret(hWnd);
                    //if (np.mEditStarted) np.mEditedText = np.getControlText(hWnd);
                }
            break;
            /* We don't get this msg for the first NumberPicker. We will get this for...
             * each one after the first NumberPicker. This is a fix for a strange problem.
             * After sending the UDM_SETBUDDY message, the previous NumberPicker's buddy...
             * will be sperated from it's updown. So we need to combine them once again. */
            case CM_BUDDY_RESIZE: np.resizeBuddy(); break;

            default : return DefSubclassProc(hWnd, message, wParam, lParam); break;
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}
