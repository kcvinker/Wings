module wings.numberpicker; // Created on : 10-Jun-22 05:24:04 PM

import wings.d_essentials;
import wings.wings_essentials;
import std.conv;
import wings.clipboard;
import std.algorithm : clamp;
import std.stdio;
import std.datetime.stopwatch;


int npNumber = 1;
wstring wcNpClass;
bool isNpCreated;
DWORD npStyle = WS_VISIBLE | WS_CHILD | UDS_ALIGNRIGHT | UDS_ARROWKEYS | UDS_AUTOBUDDY | UDS_HOTTRACK;
DWORD mTxtFlag = DT_SINGLELINE | DT_VCENTER | DT_CENTER | DT_NOPREFIX ;

class NumberPicker : Control {
    this(Window parent, int x, int y, int w, int h) {
        if (!isNpCreated) {
            isNpCreated = true;
            wcNpClass = "msctls_updown32";
            appData.iccEx.dwICC = ICC_UPDOWN_CLASS ;
            InitCommonControlsEx(&appData.iccEx);
        }

        mixin(repeatingCode);
        mControlType = ControlType.numberPicker ;
        mMaxRange = 100;
        mMinRange = 0;
        mDeciPrec = 0;
        mStep = 1;
        mStyle = npStyle  ;
        mExStyle = 0x00000000 ;//WS_EX_LTRREADING | WS_EX_RTLREADING | WS_EX_CLIENTEDGE ;   ES_LEFT := 0x0
        mBuddyStyle = WS_CHILD | WS_VISIBLE | ES_NUMBER | WS_TABSTOP| WS_BORDER ;// | WS_CLIPCHILDREN;// WS_BORDER ;
        mBuddyExStyle = WS_EX_LEFT | WS_EX_LTRREADING ;//| WS_EX_STATICEDGE ;//| WS_EX_LEFT ;//WS_EX_LTRREADING | WS_EX_RTLREADING | WS_EX_LEFT ;//| WS_EX_CLIENTEDGE;
        mBackColor(defBackColor) ;
        mForeColor(defForeColor);

        mClsName = wcNpClass ;
        mFmtStr = "%.02f" ;
        mValue = mMinRange;
        this.mName = format("%s_%d", "NumberPicker_", npNumber);
         // This pen is needed to draw a white
        ++npNumber;
    }

    this(Window parent) {this(parent, 10, 10, 100, 27);}
    this(Window parent, int x, int y) {this(parent, x, y, 100, 27);}

    final void create() {

    	this.adjustNpStyles() ;
        this.mCtlId = Control.stCtlId ;
        this.mMyRect = RECT(this.mXpos, this.mYpos, (this.mXpos + this.mWidth), (this.mYpos + this.mHeight));
        this.mHandle = CreateWindowEx( this.mExStyle,
                                        mClsName.ptr,
                                        null,
                                        this.mStyle,
                                        0, 0, 0, 0,
                                        this.mParent.handle,
                                        cast(HMENU) this.mCtlId,
                                        appData.hInstance,
                                        null);

        if (this.mHandle) {     // Creating buddy edit control.
            ++Control.stCtlId; // Increasing protected static member for next control iD
            this.mIsCreated = true;
            this.setSubClass(&npWndProc) ;
            if (!this.mBaseFontChanged) this.mFont = this.mParent.font;
            this.createLogFontInternal();
            this.mBuddyCid = Control.stCtlId;

            // Let's create the buddy control aka edit control.
            this.mBuddyHandle = CreateWindowEx( this.mBuddyExStyle,
                                                "Edit".toUTF16z,
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
            if (this.mBuddyHandle) {
                this.mBuddySubClsID = Control.mSubClassId;
                this.mBuddySubClsProc = &buddyWndProc;
                ++Control.mSubClassId;
                SendMessageW(this.mBuddyHandle, WM_SETFONT, cast(WPARAM) this.mFont.handle, cast(LPARAM) 1);
                this.sendMsg(UDM_SETBUDDY, this.mBuddyHandle, 0); // This will set the edit as updown's buddy.

                SetWindowSubclass(this.mBuddyHandle, &buddyWndProc, UINT_PTR(Control.mSubClassId), this.toDwPtr());
                this.sendMsg(UDM_SETRANGE32, cast(WPARAM) this.mMinRange, cast(LPARAM) this.mMaxRange);

                // Collecting both controls rects
                GetClientRect(this.mBuddyHandle, &this.mTBRect);
                GetClientRect(this.mHandle, &this.mUDRect);

                /*  This thing is a hack. The edit control is not turned on the...
                    vertical alignment without setting the WS_BORDER style.
                    But if we set that style, it will create a border around the edit.
                    However, when we draw edges of the edit, 3 of the borders will be deleted.
                    But, we need to manually erase the forth one.
                    And drawing a line with background color is the hack. */
                this.mLineX = this.mBtnLeft ? this.mTBRect.left: this.mTBRect.right - 2;

                DWORD swp_flag = SWP_SHOWWINDOW | SWP_NOACTIVATE | SWP_NOZORDER;
                if (this.mBtnLeft) { // If button is on left side, place the edit at right side
                    SetWindowPos(this.mBuddyHandle, HWND_TOP,
                                    (this.mXpos + this.mUDRect.right), this.mYpos,
                                    this.mTBRect.right, this.mTBRect.bottom, swp_flag);
                } else {  // Else, place the edit at left side
                    SetWindowPos(this.mBuddyHandle, HWND_TOP, this.mXpos, this.mYpos,
                                    (this.mTBRect.right - 1), this.mTBRect.bottom, swp_flag);
                }
                //test_tb_rect();
				this.displayValue;
                ++Control.stCtlId;
                ++Control.mSubClassId;
            }
        }
    }

    void test_tb_rect() {
        RECT rc;
        SendMessage(this.mBuddyHandle, EM_GETRECT, 0, cast(LPARAM) &rc);
        rc.top = 6;
        SendMessage(this.mBuddyHandle, EM_SETRECT, 0, cast(LPARAM) &rc);
    }

    //region properties

        final void minRange(double value) {
            this.mMinRange = value;
            if (this.mIsCreated) {
                this.sendMsg(UDM_SETRANGE32, this.mMinRange, this.mMaxRange);
            }
        }
        final double minRange() {return this.mMinRange;}

        final void maxRange(double value) {
            this.mMaxRange = value;
            if (this.mIsCreated) {
                this.sendMsg(UDM_SETRANGE32, this.mMinRange, this.mMaxRange);
            }
        }
        final double maxRange() {return this.mMaxRange;}

        final bool hideSelection() {return this.mHideSel;}
        final void hideSelection(bool value) {
            this.mHideSel = value;
            if (this.mIsCreated) {
                SendMessage(this.mBuddyHandle, EM_SETSEL, cast(WPARAM) -1, 0 );
            }
        }

        final bool buttonOnLeft() {return this.mBtnLeft;}
        final void buttonOnLeft(bool value) {
            this.mBtnLeft = value;
            if (this.mIsCreated) {
                // TODO - change window style using SetWindowLong function.
            }

        }

        final Alignment textAlign() {return this.mTxtPos;}
        final void textAlign(Alignment value) {
            this.mTxtPos = value;
            if (this.mIsCreated) {
                // TODO - change window style using SetWindowLong function.
            }

        }

        final bool hasSeperator() {return this.mHasSep;}
        final void hasSeperator(bool value) {
            this.mHasSep = value;
            if (this.mIsCreated) {
                // TODO - change window style using SetWindowLong function.
            }
        }

        final bool rotateValue() {return this.mAutoRotate;}
        final void rotateValue(bool value) {
            this.mAutoRotate = value;
            if (this.mIsCreated) {
                // TODO - change window style using SetWindowLong function.
            }
        }

        final double value() {return this.mValue;}
        final void value(double value) {
            this.mValue = value;
            if (this.mIsCreated) this.displayValue();
        }

        final double step() {return this.mStep;}
        final void step(double value) {
            this.mStep = value;
            if (this.mIsCreated) {
                // TODO - change window style using SetWindowLong function.
            }
        }

        final string formatString() {return this.mFmtStr;}
        final void formatString(string value) {
            this.mFmtStr = value;
            if (this.mIsCreated) {
                // TODO - change window style using SetWindowLong function.
            }
        }

        final int decimalPrecision() {return this.mDeciPrec;}
        final void decimalPrecision(int value) {
            this.mDeciPrec = value;
            if (this.mIsCreated) {
                // TODO - change window style using SetWindowLong function.
            }
        }

        mixin finalProperty!("hideCaret", this.mHideCaret);

        /+  Since, we are handling the mouse leave event specially,
            We need to use these three event handler props individually.
            We can't use parent's methods for these. +/
        final void onMouseEnter(EventHandler value) {
            this.mOnMouseEnter = value;
            this.mTrackMouseLeave = true;
        }

        final void onMouseLeave(EventHandler value) {
            this.mOnMouseLeave = value;
            this.mTrackMouseLeave = true;
        }

        final void onMouseMove(MouseEventHandler value) {
            this.mOnMouseMove = value;
            this.mTrackMouseLeave = true;
        }

    //endregion Properties

    EventHandler onValueChanged ;
    PaintEventHandler onTextPaint;
    //alias uintptr = UINT_PTR;
    package :

    private :
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
        double mStep ;
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

        void adjustNpStyles() { // Private
            if (this.mBtnLeft) {
                this.mStyle ^= UDS_ALIGNRIGHT;
                this.mStyle |= UDS_ALIGNLEFT;
                this.mTopEdgeFlag = BF_TOP;
                this.mBotEdgeFlag = BF_BOTTOMRIGHT;
                if (this.mTxtPos == Alignment.left) this.mTxtPos = Alignment.right;
            }
            //if (!this.mHasSep) this.mStyle |= UDS_NOTHOUSANDS;

            switch (this.mTxtPos) {
                case Alignment.left : this.mBuddyStyle |= ES_LEFT; break;
                case Alignment.center : this.mBuddyStyle |= ES_CENTER; break;
                case Alignment.right : this.mBuddyStyle |= ES_RIGHT; break;
                default : break;
            }

        }

        void setValueInternal(int delta) { // Private
            double newValue = this.mValue + (delta * this.mStep);
            if (this.mAutoRotate) {
                if (newValue > this.mMaxRange) {
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

        void displayValue() { // Private
            auto newStr = format(this.mFmtStr, this.mValue);
            SetWindowTextW(this.mBuddyHandle, newStr.toUTF16z);
        }

        bool isMouseOnMe() { // Private
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

        void npMouseMoveHandler(UINT msg, WPARAM wp, LPARAM lp) { // Private
            if (this.isMouseEntered) {
                if (this.mOnMouseMove) {
                    auto mea = new MouseEventArgs(msg, wp, lp) ;
                    this.mOnMouseMove(this, mea) ;
                }
            } else {
                this.isMouseEntered = true ;
                if (this.mOnMouseEnter) this.mOnMouseEnter(this, new EventArgs());
            }
        }



        void finalize(UINT_PTR subClsId) { // Private
            if (this.mBkBrush) DeleteObject(this.mBkBrush);
            this.remSubClass(subClsId );
        }

        void finalizeBuddy(UINT_PTR subClsId) { // Private
            RemoveWindowSubclass(this.mBuddyHandle, this.mBuddySubClsProc, subClsId );
        }


} // End of NumberPicker class


extern(Windows)
private LRESULT npWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData)  {
    try {

        NumberPicker np = getControl!NumberPicker(refData)  ;
        //printWinMsg(message);
        switch (message) {
            case WM_DESTROY :
                np.finalize(scID) ;
                // np.remSubClass(scID);
            break ;

            case CM_NOTIFY :
                auto nm = cast(NMUPDOWN*) lParam;
                if (nm.hdr.code == UDN_DELTAPOS) {
                    auto tbstr = np.getControlText(np.mBuddyHandle);
                    np.mValue = parse!double(tbstr);
                    np.setValueInternal(nm.iDelta);
                    if (np.onValueChanged) np.onValueChanged(np, new EventArgs());
                }
            break ;

            case WM_MOUSELEAVE :
                if (np.mTrackMouseLeave) {
                    if (!np.isMouseOnMe()) {
                        np.isMouseEntered = false;
                        if (np.mOnMouseLeave) np.mOnMouseLeave(np, new EventArgs());
                    }
                }
            break;

            case WM_PAINT : np.paintHandler(); break;
            case WM_SETFOCUS : np.setFocusHandler(); break;
            case WM_KILLFOCUS : np.killFocusHandler(); break;
            case WM_LBUTTONDOWN : np.mouseDownHandler(message, wParam, lParam); break ;
            case WM_LBUTTONUP : np.mouseUpHandler(message, wParam, lParam); break ;
            case CM_LEFTCLICK : np.mouseClickHandler(); break;
            case WM_RBUTTONDOWN : np.mouseRDownHandler(message, wParam, lParam); break;
            case WM_RBUTTONUP : np.mouseRUpHandler(message, wParam, lParam); break;
            case CM_RIGHTCLICK : np.mouseRClickHandler(); break;
            case WM_MOUSEWHEEL : np.mouseWheelHandler(message, wParam, lParam); break;
            case WM_MOUSEMOVE : np.npMouseMoveHandler(message, wParam, lParam); break;

            default : return DefSubclassProc(hWnd, message, wParam, lParam) ;
        }
    }
    catch (Exception e) { writeln("error ", message);}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

extern(Windows)
private LRESULT buddyWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData)  {
    try {
        NumberPicker np = getControl!NumberPicker(refData)  ;
        //printWinMsg(message);
        switch (message) {
            case WM_DESTROY : np.finalizeBuddy(scID); break ;
            case WM_SETFOCUS : np.setFocusHandler(); break;
            case WM_KILLFOCUS : np.killFocusHandler(); break;
            case WM_LBUTTONDOWN : np.mouseDownHandler(message, wParam, lParam); break;
            //case WM_LBUTTONDBLCLK:
            //    InvalidateRect(hWnd, &np.mTBRect, true);
            //    break;
            case WM_LBUTTONUP : np.mouseUpHandler(message, wParam, lParam); break ;
            case CM_LEFTCLICK : np.mouseClickHandler(); break;
            case WM_RBUTTONDOWN : np.mouseRDownHandler(message, wParam, lParam); break;
            case WM_RBUTTONUP : np.mouseRUpHandler(message, wParam, lParam); break;
            case CM_RIGHTCLICK : np.mouseRClickHandler(); break;
            case WM_MOUSEWHEEL : np.mouseWheelHandler(message, wParam, lParam); break;
            case WM_MOUSEMOVE : np.npMouseMoveHandler(message, wParam, lParam); break;

            case WM_PAINT :
                // Edit control needs to be painted by DefSubclassProc function.
                // Otherwise, cursor and text will not be visible, So we need to call it.
                DefSubclassProc(hWnd, message, wParam, lParam);
                // Now, painting job is done and there is no area to update in this control.
                // So, we can draw our control edges
                //auto sw = StopWatch(AutoStart.no);
                //sw.start();
                HDC hdc = GetDC(hWnd);
                DrawEdge(hdc, &np.mTBRect, BDR_SUNKENOUTER, np.mTopEdgeFlag);
                DrawEdge(hdc, &np.mTBRect, BDR_RAISEDINNER, np.mBotEdgeFlag);
                auto fpen = CreatePen(PS_SOLID, 1, np.mBackColor.reff);
                scope(exit) DeleteObject(fpen);
                MoveToEx(hdc, np.mLineX, np.mTBRect.top + 1, null);
                SelectObject(hdc, fpen);
                LineTo(hdc, np.mLineX, np.mTBRect.bottom - 1);
                ReleaseDC(hWnd, hdc);
                //sw.stop();
                //print(" micro seconds", sw.peek.total!"usecs");  // lowest 37 micro, largest 370
                return 0;
                //if (np.onPaint) {
                //    PAINTSTRUCT ps ;
                //    BeginPaint(hWnd, &ps) ;
                //    auto pea = new PaintEventArgs(&ps) ;
                //    np.onTextPaint(np, pea) ;
                //    EndPaint(hWnd, &ps) ;
                //}
            break;

            case EM_SETSEL : return 1; break;
            case CM_COLOR_EDIT :
                if (np.mDrawFlag) {
                    auto hdc = cast(HDC) wParam;
                    if (np.mDrawFlag & 1) SetTextColor(hdc, np.mForeColor.reff);
                    np.mBkBrush = CreateSolidBrush(np.mBackColor.reff);
                    SetBkColor(hdc, np.mBackColor.reff);
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
                if (np.mTrackMouseLeave) {
                    if (!np.isMouseOnMe()) {
                        np.isMouseEntered = false;
                        if (np.mOnMouseLeave) np.mOnMouseLeave(np, new EventArgs());
                    }
                }
            break;

            case CM_CTLCOMMAND :
                auto nCode = HIWORD(wParam);
                if (nCode == EN_UPDATE) {
                    if (np.mHideCaret) HideCaret(hWnd);
                    //if (np.mEditStarted) np.mEditedText = np.getControlText(hWnd);
                }
            break;

            // case WM_NOTIFY :
            //     print("em notify", 1) ; break;

            default : return DefSubclassProc(hWnd, message, wParam, lParam) ; break;
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}
