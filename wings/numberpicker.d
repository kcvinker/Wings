// Created on: 10-Jun-22 05:24:04 PM
/*==============================================NumberPicker Docs=====================================
    Constructor:        
        this(Form parent)
        this (Control parent, int x, int y, bool btnLeft)
        this (Control parent, int x, int y, EventHandler evntFn = null )
        this (Control parent, int x, int y, int w, int h, bool btnLeft = false, EventHandler evtFn = null)

	Properties:
		NumberPicker inheriting all Control class properties	
        minRange            : double
        maxRange            : double
        value               : double
        step                : double
        hideSelection       : bool
        buttonOnLeft        : bool
        textAlign           : bool
        hasSeperator        : bool
        rotateValue         : bool        
        formatString        : string
        decimalPrecision    : int
			
    Methods:
        createHandle        
        
    Events:
        All public events inherited from Control class. (See controls.d)
        EventHandler - void delegate(Control, EventArgs)
            onValueChanged
        PaintEventHandler - void delegate(Control, PaintEventArgs)
            onTextPaint       
=============================================================================================*/

module wings.numberpicker;

import wings.d_essentials;
import wings.wings_essentials;
import std.conv;
import wings.clipboard;
import std.algorithm: clamp;
import wings.controls : specialMouseLeaveMsgHanlder;
import std.stdio;
import std.datetime.stopwatch;


enum DWORD buddyStyle = WS_CHILD | WS_VISIBLE | ES_NUMBER | WS_TABSTOP;
enum DWORD buddyExStyle = WS_EX_LEFT;
bool isNpCreated;
DWORD npStyle = WS_VISIBLE | WS_CHILD | UDS_ALIGNRIGHT | UDS_ARROWKEYS | UDS_AUTOBUDDY | UDS_HOTTRACK;
DWORD mTxtFlag = DT_SINGLELINE | DT_VCENTER | DT_CENTER | DT_NOPREFIX;
DWORD swp_flag = SWP_SHOWWINDOW | SWP_NOACTIVATE | SWP_NOZORDER;

class NumberPicker: Control
{
    this (Control parent, int x, int y, int w, int h, bool btnLeft = false, EventHandler evtFn = null)
    {
        if (!isNpCreated) {
            isNpCreated = true;
            appData.iccEx.dwICC = ICC_UPDOWN_CLASS;
            InitCommonControlsEx(&appData.iccEx);
        }

        this.mControlType = ControlType.numberPicker;
        this.initControl(parent, x, y, w, h, &npNumber);
        this.mBtnLeft = btnLeft;
        this.mMaxRange = 100;
        this.mMinRange = 0;
        this.mDeciPrec = 2;
        this.mStep = 1;
        this.mBuddyStyle = buddyStyle; 
        this.mBuddyExStyle = buddyExStyle;
        this.mFmtStr = "%.02f";
        this.mValue = this.mMinRange;
        if (evtFn != null) this.onValueChanged = evtFn;
    }

    this(Form parent) {this(parent, 10, 10, 100, 23);}
    this (Control parent, int x, int y, EventHandler evntFn = null )
    {
        this(parent, x, y, 70, 23, false, evntFn);
    }
    this (Control parent, int x, int y, bool btnLeft)
    {
         this(parent, x, y, 70, 23, btnLeft);
    }

    override void createHandle()
    {        
    	this.adjustNpStyles();
        this.createHandleInternal();
        this.createBuddy();
        if (this.mHandle && this.mBuddyHandle) {
            this.setSubClass(&npWndProc);
            this.sendMsg(UDM_SETBUDDY, this.mBuddyHandle, 0); // set the edit as updown's buddy.
            this.sendMsg(UDM_SETRANGE32, cast(WPARAM) this.mMinRange, cast(LPARAM) this.mMaxRange);

            // Collecting both controls rects
            GetClientRect(this.mBuddyHandle, &this.mTBRect);
            GetClientRect(this.mHandle, &this.mUDRect);
            this.mSpRect = RECT(this.mXpos, this.mYpos, (this.mXpos + this.mWidth), (this.mYpos + this.mHeight));
            this.getRightAndBottom();
            this.setBorderPoints();
            this.displayValue;
            ptf("number picker created with handle %s", this.mHandle);
        }
    }

    // void test_tb_rect()
    // {
    //     RECT rc;
    //     SendMessage(this.mBuddyHandle, EM_GETRECT, 0, cast(LPARAM) &rc);
    //     rc.top = 6;
    //     SendMessage(this.mBuddyHandle, EM_SETRECT, 0, cast(LPARAM) &rc);
    // }

    //region properties

        final void minRange(double value)
        {
            this.mMinRange = value;
            if (this.mValue < value) this.mValue = value;
            if (this.mIsCreated) {
                this.sendMsg(UDM_SETRANGE32, this.mMinRange, this.mMaxRange);
            }
        }
        final double minRange() {return this.mMinRange;}

        final void maxRange(double value)
        {
            this.mMaxRange = value;
            if (this.mIsCreated) {
                this.sendMsg(UDM_SETRANGE32, this.mMinRange, this.mMaxRange);
            }
        }
        final double maxRange() {return this.mMaxRange;}

        final bool hideSelection() {return this.mHideSel;}
        final void hideSelection(bool value)
        {
            this.mHideSel = value;
            if (this.mIsCreated) {
                SendMessage(this.mBuddyHandle, EM_SETSEL, cast(WPARAM) -1, 0 );
            }
        }

        final bool buttonOnLeft() {return this.mBtnLeft;}
        final void buttonOnLeft(bool value)
        {
            this.mBtnLeft = value;
            if (this.mIsCreated) {
                // TODO - change window style using SetWindowLong function.
            }

        }

        final Alignment textAlign() {return this.mTxtPos;}
        final void textAlign(Alignment value)
        {
            this.mTxtPos = value;
            if (this.mIsCreated) {
                // TODO - change window style using SetWindowLong function.
            }

        }

        final bool hasSeperator() {return this.mHasSep;}
        final void hasSeperator(bool value)
        {
            this.mHasSep = value;
            if (this.mIsCreated) {
                // TODO - change window style using SetWindowLong function.
            }
        }

        final bool rotateValue() {return this.mAutoRotate;}
        final void rotateValue(bool value)
        {
            this.mAutoRotate = value;
            if (this.mIsCreated) {
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
            if (this.mIsCreated) {
                // TODO - change window style using SetWindowLong function.
            }
        }

        final string formatString() {return this.mFmtStr;}
        final void formatString(string value)
        {
            this.mFmtStr = value;
            if (this.mIsCreated) this.displayValue();
        }

        final int decimalPrecision() {return this.mDeciPrec;}
        final void decimalPrecision(int value)
        {
            this.mDeciPrec = value;
            if (value == 0) {
                this.mFmtStr = "%f";
            } else {
                this.mFmtStr = format("%%0%df", value);
            }
            // If this is not done, number picker will display default value.
            if (this.mIsCreated) this.displayValue();
        }

        mixin finalProperty!("hideCaret", this.mHideCaret);

        override bool shouldTrackMouse(HWND hWnd)
        {
            return !this.mIsMouseTracking && hWnd == this.mBuddyHandle;
        }

        

    //endregion Properties

    EventHandler onValueChanged;
    PaintEventHandler onTextPaint;
    
    protected:
        RECT mSpRect;
        mixin SpecialMouseLeaveHandler;

    package:
        RECT mTbWrc; // This is the rect for drawing line over the border of edit control.
        POINT[4] mBorderPts; 
        HPEN mBorderPen;

    private:
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
        RECT mUDRect;
        RECT mTBRect;
        // RECT mMyRect;
        // EventHandler mOnMouseLeave;
        // EventHandler mOnMouseEnter;
        // MouseEventHandler mOnMouseMove;
        // static wchar[] mUpdClassName = ['m', 's', 'c', 't', 'l', 's', '_', 'u', 'p', 'd', 'o', 'w', 'n', '3', '2', 0];
        static int npNumber;
    // endregion private members

    // region private functions
        void adjustNpStyles() // Private
        {
            if (this.mBtnLeft) {
                this.mStyle ^= UDS_ALIGNRIGHT;
                this.mStyle |= UDS_ALIGNLEFT;
                this.mTopEdgeFlag = BF_TOP;
                this.mBotEdgeFlag = BF_BOTTOMRIGHT;
                if (this.mTxtPos == Alignment.left) this.mTxtPos = Alignment.right;
            }

            switch (this.mTxtPos) {
                case Alignment.left: this.mBuddyStyle |= ES_LEFT; break;
                case Alignment.center: this.mBuddyStyle |= ES_CENTER; break;
                case Alignment.right: this.mBuddyStyle |= ES_RIGHT; break;
                default: break;
            }
            this.mBorderPen = CreatePen(PS_SOLID, 2, getClrRef(0xABADB3));
        }

        void setBorderPoints() 
        {
            GetWindowRect(this.mBuddyHandle, &this.mTbWrc);
            OffsetRect(&this.mTbWrc, -this.mTbWrc.left, -this.mTbWrc.top);
            if (this.mBtnLeft) {  // ⊐
                this.mBorderPts[1].x = this.mTbWrc.right;
                this.mBorderPts[2].x = this.mTbWrc.right;
                this.mBorderPts[2].y = this.mTbWrc.bottom;            
                this.mBorderPts[3].y = this.mTbWrc.bottom;
            } else { // ⊏
                this.mBorderPts[0].x = this.mTbWrc.right;
                this.mBorderPts[2].y = this.mTbWrc.bottom; 
                this.mBorderPts[3].x = this.mTbWrc.right;
                this.mBorderPts[3].y = this.mTbWrc.bottom;
            }
        }


        void createBuddy()  // Private
        {
            // Creating buddy edit control
            import wings.textbox: tbClsName;

            this.mBuddyCid = Control.stCtlId;
            if (this.mBtnLeft) this.mWidth -= 2; // To match the size of a button right control.
            this.mBuddyHandle = CreateWindowEx( this.mBuddyExStyle,
                                                tbClsName.ptr,
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
                SetWindowSubclass(this.mBuddyHandle, &buddyWndProc, UINT_PTR(this.mBuddySubClsID), this.toDwPtr());
                SendMessageW(this.mBuddyHandle, WM_SETFONT, cast(WPARAM) this.mFont.handle, cast(LPARAM) 1);
                ++Control.mSubClassId;
            }
        }

        // void resizeBuddy()  // Private
        // {
        //     // Place the edit control at proper coordinates
        //     if (this.mBtnLeft) {
        //         this.mLineX = this.mTBRect.left;
        //         SetWindowPos(this.mBuddyHandle, HWND_TOP,
        //                         (this.mXpos + this.mUDRect.right), this.mYpos,
        //                         this.mTBRect.right, this.mTBRect.bottom, swp_flag);
        //     } else {
        //         this.mLineX = this.mTBRect.right - 3;
        //         SetWindowPos(this.mBuddyHandle, HWND_TOP, this.mXpos, this.mYpos,
        //                         (this.mTBRect.right - 2), this.mTBRect.bottom, swp_flag);
        //     }
        // }

        void setValueInternal(int delta)  // Private
        {
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

        void displayValue()  // Private
        {
            string newStr;
            if (this.mDeciPrec > 0) {
                newStr = format(this.mFmtStr, this.mValue);
            } else {
                newStr = format("%d", to!int(this.mValue));
            }
            SetWindowTextW(this.mBuddyHandle, newStr.toUTF16z);
        }

        // bool isMouseOnMe()  // Private
        // {
        //     /*---------------------------------------------------------------------- 
        //     If this returns False, mouse_leave event will triggered
        //     Since, updown control is a combo of an edit and button controls...
        //     we have no better options to control the mouse enter & leave mechanism.
        //     Now, we create an imaginary rect over the bondaries of these two controls.
        //     If mouse is inside that rect, there is no mouse leave. Perfect hack. 
        //     ---------------------------------------------------------------------------*/
        //     POINT pt;
        //     GetCursorPos(&pt);
        //     ScreenToClient(this.mParent.handle, &pt);
        //     auto res = PtInRect(&this.mMyRect, pt);
        //     return cast(bool) res;
        // }

        // void npMouseMoveHandler(UINT msg, WPARAM wp, LPARAM lp)  // Private
        // {
        //     if (this.isMouseEntered) {
        //         if (this.mOnMouseMove) {
        //             auto mea = new MouseEventArgs(msg, wp, lp);
        //             this.mOnMouseMove(this, mea);
        //         }
        //     } else {
        //         this.isMouseEntered = true;
        //         if (this.mOnMouseEnter) this.mOnMouseEnter(this, new EventArgs());
        //     }
        // }

        void finalize(UINT_PTR subClsId) // Private
        {
            if (this.mBkBrush) DeleteObject(this.mBkBrush);
            DeleteObject(this.mBorderPen);
            RemoveWindowSubclass(this.mHandle, &npWndProc, subClsId);
        }

    // endregion private functions
} // End of NumberPicker class




extern(Windows)
private LRESULT npWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                                UINT_PTR scID, DWORD_PTR refData)
{
    try {
        //printWinMsg(message);
        NumberPicker self = getControl!NumberPicker(refData);
        auto res = self.commonMsgHandler(hWnd, message, wParam, lParam);
        if (res == MsgHandlerResult.callDefProc) {
            return DefSubclassProc(hWnd, message, wParam, lParam);
        } else if (res == MsgHandlerResult.returnZero || res == MsgHandlerResult.returnOne) {
            return cast(LRESULT) res;
        }
        switch (message) {
            case WM_NCDESTROY: 
                self.finalize(scID); 
            break;
            case CM_NOTIFY:
                auto nm = cast(NMUPDOWN*) lParam;
                if (nm.hdr.code == UDN_DELTAPOS) {//writeln("delta pos");
                    auto tbstr = self.getControlText(self.mBuddyHandle);
                    self.mValue = parse!double(tbstr);
                    self.setValueInternal(nm.iDelta);
                    if (self.onValueChanged) self.onValueChanged(self, new EventArgs());
                }
            break;
            case WM_PAINT: 
                self.paintHandler(); 
            break;
            default: return DefSubclassProc(hWnd, message, wParam, lParam);
        }
    }
    catch (Exception e) { writeln("error ", message);}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

extern(Windows)
private LRESULT buddyWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                                    UINT_PTR scID, DWORD_PTR refData)
{
    try {
        //printWinMsg(message);
        NumberPicker self = getControl!NumberPicker(refData);
        auto res = self.commonMsgHandler(hWnd, message, wParam, lParam);
        if (res == MsgHandlerResult.callDefProc) {
            return DefSubclassProc(hWnd, message, wParam, lParam);
        } else if (res == MsgHandlerResult.returnZero || res == MsgHandlerResult.returnOne) {
            return cast(LRESULT) res;
        }
        switch (message) {
            case WM_NCDESTROY: 
                RemoveWindowSubclass(hWnd, &buddyWndProc, scID ); 
            break;
            case WM_NCCALCSIZE:
                /*---------------------------------------------------------------------------------
                # By default, arrow button has a border on 3 sides.
                # If we use WS_BORDER style for buddy edit control, we need to...
                # cover it with unnecessary drawings. So, it's better to make...
                # room to draw a border and draw it on the 3 sides of buddy edit...
                # in WM_NCPAINT. So we need to shrink the client area and make room.
                ----------------------------------------------------------------------------------*/
                auto nccs = cast(NCCALCSIZE_PARAMS*) lParam;
                if (wParam == TRUE) {
                    if (self.mBtnLeft) {
                        nccs.rgrc[0].left += 2;
                        nccs.rgrc[0].top += 1;
                        nccs.rgrc[0].right -= 1;
                        nccs.rgrc[0].bottom -= 1;
                    } else {
                        nccs.rgrc[0].left += 1;
                        nccs.rgrc[0].top += 1;
                        nccs.rgrc[0].right -= 2;
                        nccs.rgrc[0].bottom -= 1;
                    }
                }
                return 0;
            break;
            case WM_NCPAINT:
                /*---------------------------------------------------------------------------------
                Since we are not using WS_BORDER style, we need to draw the border on 3 sides of the edit control manually. 
                ----------------------------------------------------------------------------------*/
                HRGN hrgn = cast(HRGN)wParam;
                DWORD flags = DCX_WINDOW | DCX_CACHE | DCX_INTERSECTRGN;
                if (wParam == 1) {
                    flags = DCX_WINDOW | DCX_CACHE;
                }
                HDC hdc = GetDCEx(hWnd, hrgn, flags);
                scope(exit) ReleaseDC(hWnd, hdc);
                if (hdc) {       
                    HGDIOBJ hOldPen = SelectObject(hdc, cast(HGDIOBJ)self.mBorderPen);       
                    Polyline(hdc, &self.mBorderPts[0], 4);
                    SelectObject(hdc, hOldPen);
                }
                return 0;
            break;
            case EM_SETSEL: return 1; break; // To eliminate the text selection
            case CM_COLOR_EDIT:
                if (self.mDrawFlag) {
                    auto hdc = cast(HDC) wParam;
                    if (self.mDrawFlag & 1) SetTextColor(hdc, self.mForeColor.cref);
                    self.mBkBrush = CreateSolidBrush(self.mBackColor.cref);
                    SetBkColor(hdc, self.mBackColor.cref);
                    return cast(LRESULT) self.mBkBrush;
                }
            break;
            case CM_CTLCOMMAND:
                auto nCode = HIWORD(wParam);
                if (nCode == EN_UPDATE) {
                    if (self.mHideCaret) HideCaret(hWnd);
                }
            break;
            default: 
                return DefSubclassProc(hWnd, message, wParam, lParam);
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}
