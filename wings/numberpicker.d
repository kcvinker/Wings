// Created on: 10-Jun-22 05:24:04 PM
/*==============================================NumberPicker Docs=====================================
    Constructor:        
        this(Form parent)
        this(Form parent, int x, int y, bool btnLeft)
        this(Form parent, int x, int y, EventHandler evntFn = null )
        this(Form parent, int x, int y, int w, int h, bool btnLeft = false, EventHandler evtFn = null)

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


enum DWORD buddyStyle = WS_CHILD | WS_VISIBLE | ES_NUMBER | WS_TABSTOP| WS_BORDER;
enum DWORD buddyExStyle = WS_EX_LEFT | WS_EX_LTRREADING;
bool isNpCreated;
DWORD npStyle = WS_VISIBLE | WS_CHILD | UDS_ALIGNRIGHT | UDS_ARROWKEYS | UDS_AUTOBUDDY | UDS_HOTTRACK;
DWORD mTxtFlag = DT_SINGLELINE | DT_VCENTER | DT_CENTER | DT_NOPREFIX;
DWORD swp_flag = SWP_SHOWWINDOW | SWP_NOACTIVATE | SWP_NOZORDER;

class NumberPicker: Control
{
    this(Form parent, int x, int y, int w, int h, bool btnLeft = false, EventHandler evtFn = null)
    {
        if (!isNpCreated) {
            isNpCreated = true;
            appData.iccEx.dwICC = ICC_UPDOWN_CLASS;
            InitCommonControlsEx(&appData.iccEx);
        }

        mixin(repeatingCode);
        ++npNumber;
        mControlType = ControlType.numberPicker;
        this.mFont = new Font(parent.font);
        mBtnLeft = btnLeft;
        mMaxRange = 100;
        mMinRange = 0;
        mDeciPrec = 2;
        mStep = 1;
        mStyle = npStyle;
        mExStyle = 0x00000000;//WS_EX_LTRREADING | WS_EX_RTLREADING | WS_EX_CLIENTEDGE;   ES_LEFT:= 0x0
        mBuddyStyle = buddyStyle; 
        mBuddyExStyle = buddyExStyle;
        mBackColor(defBackColor);
        mForeColor(defForeColor);
        this.mHasFont = true;
        mFmtStr = "%.02f";
        mValue = mMinRange;
        this.mName = format("%s_%d", "NumberPicker_", npNumber);
        this.mParent.mControls ~= this;
        this.mCtlId = Control.stCtlId;
        ++Control.stCtlId;
        if (evtFn != null) this.onValueChanged = evtFn;
        if (parent.mAutoCreate) this.createHandle();
    }

    this(Form parent) {this(parent, 10, 10, 100, 27);}
    this(Form parent, int x, int y, EventHandler evntFn = null )
    {
        this(parent, x, y, 70, 27, false, evntFn);
    }
    this(Form parent, int x, int y, bool btnLeft)
    {
         this(parent, x, y, 70, 27, btnLeft);
    }

    override void createHandle()
    {        
    	this.adjustNpStyles();
        this.createUpdown();
        this.createBuddy();
        if (this.mHandle && this.mBuddyHandle) {

            auto oldBuddy = cast(HWND)this.sendMsg(UDM_SETBUDDY, this.mBuddyHandle, 0); // set the edit as updown's buddy.
            this.sendMsg(UDM_SETRANGE32, cast(WPARAM) this.mMinRange, cast(LPARAM) this.mMaxRange);

            // Collecting both controls rects
            GetClientRect(this.mBuddyHandle, &this.mTBRect);
            GetClientRect(this.mHandle, &this.mUDRect);
            this.resizeBuddy();
            SendMessageW(oldBuddy, CM_BUDDY_RESIZE, 0, 0);
            this.mSpRect = RECT(this.mXpos, this.mYpos, (this.mXpos + this.mWidth), (this.mYpos + this.mHeight));
            this.getRightAndBottom();

            /*==================================================================
            This thing is a hack. The edit control is not turned on the...
            vertical alignment without setting the WS_BORDER style.
            But if we set that style, it will create a border around the edit.
            However, when we draw edges of the edit, 3 of the borders will be deleted.
            But, we need to manually erase the forth one.
            And drawing a line with background color is the hack. 
            =========================================================================*/
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

        /+++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
        Since, we are handling the mouse leave event specially,
        We need to use these three event handler props individually.
        We can't use parent's methods for these. 
        ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++/
        // final void onMouseEnter(EventHandler value)
        // {
        //     this.mOnMouseEnter = value;
        //     this.mTrackMouseLeave = true;
        // }

        // final void onMouseLeave(EventHandler value)
        // {
        //     this.mOnMouseLeave = value;
        //     this.mTrackMouseLeave = true;
        // }

        // final void onMouseMove(MouseEventHandler value)
        // {
        //     this.mOnMouseMove = value;
        //     this.mTrackMouseLeave = true;
        // }

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
        static wchar[] mUpdClassName = ['m', 's', 'c', 't', 'l', 's', '_', 'u', 'p', 'd', 'o', 'w', 'n', '3', '2', 0];
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
            //if (!this.mHasSep) this.mStyle |= UDS_NOTHOUSANDS;

            switch (this.mTxtPos) {
                case Alignment.left: this.mBuddyStyle |= ES_LEFT; break;
                case Alignment.center: this.mBuddyStyle |= ES_CENTER; break;
                case Alignment.right: this.mBuddyStyle |= ES_RIGHT; break;
                default: break;
            }
        }

        void createUpdown()  // Private
        {
            // Creating the updown control only.
            this.mCtlId = Control.stCtlId;
            this.mHandle = CreateWindowEx( this.mExStyle,
                                            this.mUpdClassName.ptr,
                                            null,
                                            this.mStyle,
                                            0, 0, 0, 0,
                                            this.mParent.handle,
                                            cast(HMENU) this.mCtlId,
                                            appData.hInstance,
                                            null);
            if (this.mHandle) {
                ++Control.stCtlId; // Increasing protected static member for next control iD
                this.mIsCreated = true;
                this.setSubClass(&npWndProc);
                this.createLogFontInternal();
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

        void resizeBuddy()  // Private
        {
            // Place the edit control at proper coordinates
            if (this.mBtnLeft) {
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
            case WM_DESTROY: 
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
            case WM_DESTROY: 
                RemoveWindowSubclass(hWnd, &buddyWndProc, scID ); 
            break;
            case WM_PAINT:

                // Let the control paint it's basic stuff.
                DefSubclassProc(hWnd, message, wParam, lParam);

                /*---------------------------------------------------------------------------- 
                We need WM_BORDER style to preserve the alignment of text in edit control.
                But that will cause a border around the edit control and it will separate...
                the updown and edit visualy. So we need to erase one border. It will be...
                either right side of the edit or left side of the edit, depends upon where...
                the bupown button locates. To erase the border, we just draw a line with...
                edit's back color. 
                ------------------------------------------------------------------------------*/
                HDC hdc = GetDC(hWnd);
                DrawEdge(hdc, &self.mTBRect, BDR_SUNKENOUTER, self.mTopEdgeFlag);
                DrawEdge(hdc, &self.mTBRect, BDR_RAISEDINNER, self.mBotEdgeFlag);
                auto fpen = CreatePen(PS_SOLID, 1, self.mBackColor.cref);
                scope(exit) DeleteObject(fpen);
                MoveToEx(hdc, self.mLineX, self.mTBRect.top + 1, null);
                SelectObject(hdc, fpen);
                LineTo(hdc, self.mLineX, self.mTBRect.bottom - 1);
                ReleaseDC(hWnd, hdc);
                return 1;
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
            case CM_BUDDY_RESIZE: 
                /*---------------------------------------------------------------------------
                We don't get this msg for the first NumberPicker. We will get this for...
                each one after the first NumberPicker. This is a fix for a strange problem.
                After sending the UDM_SETBUDDY message, the previous NumberPicker's buddy...
                will be sperated from it's updown. So we need to combine them once again. 
                ----------------------------------------------------------------------------*/
                self.resizeBuddy(); 
            break;
            default: return DefSubclassProc(hWnd, message, wParam, lParam);
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}
