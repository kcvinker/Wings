module wings.trackbar;
/*==============================================TrackBar Docs=====================================
    Constructor:
        this (Form parent, int x, int y)
        this (Form parent, int x, int y, int w, int h, bool cdraw = false, 
                EventHandler evtFn = null, bool vertical = false )

	Properties:
		TrackBar inheriting all Control class properties	
        vertical            : bool
        showSelection       : bool
        noTics              : bool
        customDraw          : bool
        toolTip             : bool
        reverse             : bool
        freeMove            : bool
        value               : int
        ticLength           : int
        largeChange         : int
        smallChange         : int
        frequency           : int
        minimum             : int
        maximum             : int        
        selectionColor      : Color
        ticColor            : Color
        channelColor        : Color        
        ticWidth            : int
        ticPosition         : TicPosition enum [See enums.d]        
        channelStyle        : ChannelStyle enum [See enums.d]
			
    Methods:
        createHandle    
        setTicPos    
        
    Events:
        All public events inherited from Control class. (See controls.d)
        EventHandler - void delegate(Control, EventArgs)
            onValueChanged
            onDragging
            onDragged       
=============================================================================================*/

import std.stdio;
import wings.d_essentials;
import wings.wings_essentials;

enum wchar[] mClassName = ['m','s','c','t','l','s','_','t','r','a','c','k','b','a','r','3','2', 0];
enum DWORD tkbStyle = WS_CHILD | WS_VISIBLE | TBS_AUTOTICKS;
enum DWORD tkbExStyle = WS_EX_RIGHTSCROLLBAR | WS_EX_LTRREADING |WS_EX_LEFT;
enum U16_MAX = 1 << 16;
enum THUMB_PAGE_HIGH = 3;
enum THUMB_PAGE_LOW = 2;
enum THUMB_LINE_HIGH = 1;
enum THUMB_LINE_LOW = 0;

class TicData
{
    private static num = 0;
    int index,phyPoint, logPoint;
    this(int pp, int lp)
    {
        this.index = num;
        this.phyPoint = pp;
        this.logPoint = lp;
        num += 1;
    }
    void print()
    {
        writefln("Index %d, Physical Point %d, Logical Point %d", this.index, this.phyPoint, this.logPoint);
    }
}

class TrackBar: Control
{
    this (Form parent, int x, int y, int w, int h, bool cdraw = false, 
                EventHandler evtFn = null, bool vertical = false )
    {
        mixin(repeatingCode); // Setting size, position, parent & font
        ++tkbNumber;
        mName = format("TrackBar_%d", tkbNumber);
        mControlType = ControlType.trackBar;
        mStyle = tkbStyle;
        mExStyle = tkbExStyle;
        mBackColor = parent.mBackColor;
        mVertical = vertical;
        mTicWidth = 1;
        mTicLen = 4;
        mTicPos = TicPosition.downSide;
        mLineSize = 1;
        mChannelSTyle = ChannelStyle.classic;
        mTrackChange = TrackChange.none;
        mMinRange = 0;
        mMaxRange = 100;
        mFrequency = 10;
        mPageSize = 10;
        this.mCustDraw = cdraw;
        mChannelColor(0xc2c2a3);
        mSelColor(0x99ff33);
        mTicColor(0x3385ff);
        this.mParent.mControls ~= this;
        this.mCtlId = Control.stCtlId;
        ++Control.stCtlId;
        if (vertical) this.mTicPos = TicPosition.leftSide;
        if (evtFn != null) this.onValueChanged = evtFn;
        if (parent.mAutoCreate) this.createHandle();
    }

    this (Form parent, int x, int y) {this(parent, x, y, 150, 24);}

    // Events
    EventHandler onValueChanged,onDragging,onDragged;

    // Properties
        mixin finalProperty!("ticLength", this.mTicLen); //--------------------[1] TicLength
        mixin finalProperty!("largeChange", this.mPageSize); //----------------[2] LargeChange
        mixin finalProperty!("smallChange", this.mLineSize); //----------------[3] SmallChange
        mixin finalProperty!("frequency", this.mFrequency); //-----------------[4] Frequency
        mixin finalProperty!("minimum", this.mMinRange); //--------------------[5] Minimum
        mixin finalProperty!("maximum", this.mMaxRange); //--------------------[6] Maximum
        mixin finalProperty!("ticPosition", this.mTicPos); //------------------[7] TicPosition
        mixin finalProperty!("toolTip", this.mToolTip); //---------------------[8] ToolTip
        mixin finalProperty!("reverse", this.mReversed); //--------------------[9] Reverse
        mixin finalProperty!("selectionColor", this.mSelColor); //-------------[10] SelectionColor
        mixin finalProperty!("ticColor", this.mTicColor); //-------------------[11] ticColor
        mixin finalProperty!("channelColor", this.mChannelColor); //-----------[12] ChannelColor
        mixin finalProperty!("freeMove", this.mFreeMove); //-------------------[13] FreeMove
        mixin finalProperty!("ticWidth", this.mTicWidth); //-------------------[14] ticWidth
        mixin finalProperty!("noTics", this.mNoTics); //-----------------------[15] noTics
        mixin finalProperty!("customDraw", this.mCustDraw); //-----------------[16] CustomDraw
        mixin finalProperty!("channelStyle", this.mChannelSTyle); //-----------[17] ChannelStyle
    //

    final bool vertical() {return this.mVertical;}
    final void vertical(bool value)
    {
        this.mVertical = value;
        if (this.mTicPos == TicPosition.downSide || this.mTicPos == TicPosition.upSide) {
            this.mTicPos = TicPosition.leftSide;
        }
        // Destroy current trackbar & create new one
        this.mRecreateEnabled = true;
        DestroyWindow(this.mHandle);
        this.mStyle = tkbStyle;
        this.mStyle = tkbExStyle;
        this.createHandle();
    }
    //---------------------------------------------------------------------[18] Vertical

    final bool showSelection() {return this.mSelRange;}
    final void showSelection(bool value)
    {
        this.mSelRange = value;
        if (!this.mCustDraw) this.mCustDraw = true;
    }
    //---------------------------------------------------------------------[19] ShowSelection

    final int value() {return this.mValue;}
    final void value(int value)
    {
        this.mValue = value;
        if (!this.mIsCreated) {

        }
    }
    //---------------------------------------------------------------------[20] Value

    void backColor(Color value)
    {
        this.mBackColor = value;
        this.backColorSetupInternal();
    }

    override void backColor(uint value)
    {
        this.mBackColor.updateColor(value);
        this.backColorSetupInternal();
    }

    override void createHandle()
    {
        // import std.stdio;
    	this.setTkbStyle();
    	this.createHandleInternal(mClassName.ptr);
    	if (this.mHandle) {
            this.setSubClass(&tkbWndProc);
            if (this.mCustDraw) this.prepareForCustDraw();
            this.sendInitialMessages();
            if (this.mCustDraw) this.calculateTics();
            if (!this.mRecreateEnabled) 
                if (this.mSelRange) this.mSelBrush = CreateSolidBrush(this.mSelColor.cref);
            this.mRecreateEnabled = false;
        }
    }

    final void setTicPos(string pos)
    {
        import std.string;
        string p = pos.toUpper();
        final switch(p) {
            case "BOTH": this.mTicPos = TicPosition.bothSide; break;
            case "UP": this.mTicPos = TicPosition.upSide; break;
            case "DOWN": this.mTicPos = TicPosition.downSide; break;
            case "LEFT": this.mTicPos = TicPosition.leftSide; break;
            case "RIGHT": this.mTicPos = TicPosition.rightSide; break;
        }
    }

    private:
        // Private members
            bool mVertical;
            bool mReversed;
            bool mNoTics;
            bool mSelRange;
            bool mDefaultTics;
            bool mNoThumb;
            bool mToolTip;
            bool mCustDraw;
            bool mFreeMove;
            bool mRecreateEnabled;
            Color mTicColor, mChannelColor, mSelColor;
            HBRUSH mSelBrush;
            HPEN mChannelPen, mTicPen;
            ChannelStyle mChannelSTyle;
            TrackChange mTrackChange;
            TicPosition mTicPos;
            RECT mChannelRc, mThumbRc, mMyRc;
            TicData[] mTics;
            int mTicWidth;
            int mMinRange;
            int mMaxRange;
            int mFrequency;
            int mPageSize;
            int mValue;
            int mLineSize;
            int mTicLen;
            int mThumbHalf;
            int mPoint1, mPoint2; // To hold x/y point of tics.
            int mTicCount;
            double mRange;
            DWORD mChannelFlag = BF_RECT | BF_ADJUST;
            static int tkbNumber;

        void setTkbStyle()
        {
            if (this.mVertical) {
                this.mStyle |= TBS_VERT;
                switch (this.mTicPos) {
                    case TicPosition.rightSide: this.mStyle |= TBS_RIGHT; break;
                    case TicPosition.leftSide: this.mStyle |= TBS_LEFT; break;
                    case TicPosition.bothSide: this.mStyle |= TBS_BOTH; break;
                    default: break;
                }
            } else {
                // this.mStyle |= TBS_;
                switch (this.mTicPos) {
                    case TicPosition.downSide: this.mStyle |= TBS_BOTTOM; break;
                    case TicPosition.upSide: this.mStyle |= TBS_TOP; break;
                    case TicPosition.bothSide: this.mStyle |= TBS_BOTH; break;
                    default: break;
                }
            }

            if (this.mSelRange) this.mStyle |= TBS_ENABLESELRANGE;
            if (this.mReversed) this.mStyle |= TBS_REVERSED;
            if (this.mNoTics) this.mStyle |= TBS_NOTICKS;
            if (this.mNoThumb) this.mStyle |= TBS_NOTHUMB;
            if (this.mToolTip) this.mStyle |= TBS_TOOLTIPS;
            if (this.mSelRange) this.mChannelFlag = BF_RECT | BF_ADJUST | BF_FLAT;
            this.mBkBrush = CreateSolidBrush(this.mBackColor.cref);
        }

        void prepareForCustDraw()
        {
            this.mChannelPen = CreatePen(PS_SOLID, 1, this.mChannelColor.cref);
            this.mTicPen = CreatePen(PS_SOLID, this.mTicWidth, this.mTicColor.cref);
        }

        void sendInitialMessages()
        {
            if (this.mReversed) {
                this.sendMsg(TBM_SETRANGEMIN, 1, (this.mMaxRange * -1));
                this.sendMsg(TBM_SETRANGEMAX, 1, this.mMinRange);
            } else {
                this.sendMsg(TBM_SETRANGEMIN, 1, (this.mMinRange));
                this.sendMsg(TBM_SETRANGEMAX, 1, this.mMaxRange);
            }
            this.sendMsg(TBM_SETTICFREQ, this.mFrequency, 0);
            this.sendMsg(TBM_SETPAGESIZE, 0, this.mPageSize);
            this.sendMsg(TBM_SETLINESIZE, 0, this.mLineSize);
        }

        void calculateTics()
        {
            // Calculating logical & physical positions for tics.
            int twidth, numTics, stPos, enPos, channelLen, tic;
            double pFactor, range;

            //1. Collecting required rects
            GetClientRect(this.mHandle, &this.mMyRc); // Get Trackbar rect
            this.sendMsg(TBM_GETTHUMBRECT, 0, &this.mThumbRc); // Get the thumb rect
            this.sendMsg(TBM_GETCHANNELRECT, 0, &this.mChannelRc); // Get the channel rect

            //2. Calculate thumb offset
            if (this.mVertical) {
                twidth = this.mThumbRc.bottom - this.mThumbRc.top;
            } else {
                twidth = this.mThumbRc.right - this.mThumbRc.left;
            }
            this.mThumbHalf = cast(int) twidth / 2;

            // Now calculate required variables
            this.mRange = this.mMaxRange - this.mMinRange;
            numTics = cast(int) this.mRange / this.mFrequency;
            if (this.mRange % this.mFrequency == 0) numTics -= 1;
            stPos = this.mChannelRc.left + this.mThumbHalf;
            enPos = this.mChannelRc.right - this.mThumbHalf - 1;
            channelLen = enPos - stPos;
            pFactor = channelLen / this.mRange;

            tic = this.mMinRange + this.mFrequency;
            this.mTics ~= new TicData(stPos, 0); // Very first tic
            for (int i = 0; i < numTics; i++) {
                this.mTics ~= new TicData(cast(int) (tic * pFactor) + stPos, tic); // Middle tics
                tic += this.mFrequency;
            }
            this.mTics ~= new TicData(enPos, cast(int) this.mRange); // Last tic

            // Now, set up single point (x/y) for tics.
            if (this.mVertical) {
                switch (this.mTicPos) {
                    case TicPosition.leftSide: this.mPoint1 = this.mThumbRc.left - 5; break;
                    case TicPosition.rightSide: this.mPoint1 = this.mThumbRc.right + 2; break;
                    case TicPosition.bothSide:
                        this.mPoint1 = this.mThumbRc.right + 2;
                        this.mPoint2 = this.mThumbRc.left - 5;
                    break;
                    default: break;
                }
            } else {
                switch (this.mTicPos) {
                    case TicPosition.downSide: this.mPoint1 = this.mThumbRc.bottom + 1; break;
                    case TicPosition.upSide: this.mPoint1 = this.mThumbRc.top - 4; break;
                    case TicPosition.bothSide:
                        this.mPoint1 = this.mThumbRc.bottom + 1;
                        this.mPoint2 = this.mThumbRc.top - 3;
                    break;
                    default: break;
                }
            }
        }

        void drawHorizontalTicsDown(HDC hdc, int px, int py)
        {
            MoveToEx(hdc, px, py, NULL);
            LineTo(hdc, px, py + this.mTicLen);
        }

        void drawHorizontalTicsUpper(HDC hdc, int px, int py)
        {
            MoveToEx(hdc, px, py, NULL);
            LineTo(hdc, px, py - this.mTicLen);
        }

        void drawVerticalTics(HDC hdc, int px, int py)
        {
            MoveToEx(hdc, px, py, NULL);
            LineTo(hdc, px + this.mTicLen, py);
        }

        RECT getThumbRect()
        {
            RECT rc;
            this.sendMsg(TBM_GETTHUMBRECT, 0, &rc);
            return rc;
        }

        void drawTics(HDC hdc)
        {
            SelectObject(hdc, this.mTicPen);
            if (this.mVertical) {
                switch (this.mTicPos) {
                    case TicPosition.rightSide, TicPosition.leftSide:
                        foreach (p; this.mTics) this.drawVerticalTics(hdc, this.mPoint1, p.phyPoint); break;
                    case TicPosition.bothSide:
                        foreach (p; this.mTics) {
                            this.drawVerticalTics(hdc, this.mPoint1, p.phyPoint);
                            this.drawVerticalTics(hdc, this.mPoint2, p.phyPoint);
                        }
                    break;
                    default: break;
                }

            } else {
                switch (this.mTicPos) {
                    case TicPosition.upSide, TicPosition.downSide:
                        foreach (p; this.mTics) this.drawHorizontalTicsDown(hdc, p.phyPoint, this.mPoint1);break;
                    case TicPosition.bothSide:
                        foreach (p; this.mTics) {
                            this.drawHorizontalTicsDown(hdc, p.phyPoint, this.mPoint1);
                            this.drawHorizontalTicsUpper(hdc, p.phyPoint, this.mPoint2);
                        }
                    break;
                    default: break;
                }
            }
        }

        bool fillChannelRect(NMCUSTOMDRAW * nm, RECT trc)
        {
            /*----------------------------------------------------------------------------------
            If show_selection property is enabled in this trackbar,
            we need to show the area between thumb and channel starting in diff color.
            But we need to check if the trackbar is reversed or not.
            NOTE: If we change the drawing flags for DrawEdge function in channel drawing area,
            We need to reduce the rect size 1 point. Because, current flags working perfectly...
            Without adsting rect. So change it carefully. 
            ----------------------------------------------------------------------------------------*/
            bool result = false;
            RECT rct;

            if (this.mVertical) {
                rct.left = nm.rc.left;
                rct.right = nm.rc.right;
                if (this.mReversed) {
                    rct.top = trc.bottom;
                    rct.bottom = nm.rc.bottom;
                } else {
                    rct.top = nm.rc.top;
                    rct.bottom = trc.top;
                }
            } else {
                rct.top = nm.rc.top;
                rct.bottom = nm.rc.bottom;
                if (this.mReversed) {
                    rct.left = trc.right;
                    rct.right = nm.rc.right;
                } else {
                    rct.left = nm.rc.left;
                    rct.right = trc.left;
                }
            }

            result = cast(bool) FillRect(nm.hdc, &rct, this.mSelBrush);
            return result;
        }

        void setupValueInternal(int value)
        {
            if (this.mReversed) {
                this.mValue = U16_MAX - value;
            } else {
                this.mValue = value;
            }
        }

        void backColorSetupInternal()
        {
            if (this.mIsCreated) {
                this.mBkBrush = this.mBackColor.getBrush();

                // Here, we need to send this message.
                // otherwise we won't see the color change until next paint
                this.sendMsg(TBM_SETRANGEMAX, 1, this.mMaxRange);
                InvalidateRect(this.mHandle, null, 0);
            }
        }

        void finalize(HWND hw, UINT_PTR subid)
        {
            if (this.mSelBrush) DeleteObject(this.mSelBrush);
            if (this.mChannelPen) DeleteObject(this.mChannelPen);
            if (this.mTicPen) DeleteObject(this.mTicPen);
            DeleteObject(this.mBkBrush);
            RemoveWindowSubclass(hw, &tkbWndProc, subid); 
        }

} // End of TrackBar class



extern(Windows)
private LRESULT tkbWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                                UINT_PTR scID, DWORD_PTR refData)
{
    try {
        switch (message) {
            case WM_DESTROY: 
                TrackBar tkb = getControl!TrackBar(refData);
                if (tkb.mRecreateEnabled) {
                    RemoveWindowSubclass(hWnd, &tkbWndProc, scID); 
                } else {
                    tkb.finalize(hWnd, scID);
                }
                
            break;
            case CM_COLOR_STATIC: 
                TrackBar tkb = getControl!TrackBar(refData);
                return cast(LRESULT) tkb.mBkBrush; 
            break;
            case WM_PAINT: 
                TrackBar tkb = getControl!TrackBar(refData);
                tkb.paintHandler(); 
            break;
            case WM_SETFOCUS: 
                TrackBar tkb = getControl!TrackBar(refData);
                tkb.setFocusHandler(); 
            break;
            case WM_KILLFOCUS: 
                TrackBar tkb = getControl!TrackBar(refData);
                tkb.killFocusHandler(); 
            break;
            case WM_LBUTTONDOWN: 
                TrackBar tkb = getControl!TrackBar(refData);
                tkb.mouseDownHandler(message, wParam, lParam); 
            break;
            case WM_LBUTTONUP: 
                TrackBar tkb = getControl!TrackBar(refData);
                tkb.mouseUpHandler(message, wParam, lParam); 
            break;
            case WM_RBUTTONDOWN: 
                TrackBar tkb = getControl!TrackBar(refData);
                tkb.mouseRDownHandler(message, wParam, lParam); 
            break;
            case WM_RBUTTONUP: 
                TrackBar tkb = getControl!TrackBar(refData);
                tkb.mouseRUpHandler(message, wParam, lParam); 
            break;
            case WM_MOUSEWHEEL: 
                TrackBar tkb = getControl!TrackBar(refData);
                tkb.mouseWheelHandler(message, wParam, lParam); 
            break;
            case WM_MOUSEMOVE: 
                TrackBar tkb = getControl!TrackBar(refData);
                tkb.mouseMoveHandler(message, wParam, lParam); 
            break;
            case WM_MOUSELEAVE: 
                TrackBar tkb = getControl!TrackBar(refData);
                tkb.mouseLeaveHandler(); 
            break;
            case CM_HSCROLL, CM_VSCROLL:
                TrackBar tkb = getControl!TrackBar(refData);
                auto lwp = LOWORD(wParam);
                switch (lwp) {
                    case TB_THUMBPOSITION:
                        tkb.setupValueInternal(HIWORD(wParam));
                        if (!tkb.mFreeMove) {
                            int pos = tkb.mValue;
                            double half = tkb.mFrequency / 2;
                            auto diff = pos % tkb.mFrequency;
                            if (diff >= half) {
                                pos = (tkb.mFrequency - diff) + tkb.mValue;
                            } else if (diff < half) {
                                pos =  tkb.mValue - diff;
                            }

                            if (tkb.mReversed) {
                                tkb.sendMsg(TBM_SETPOS, true, (pos * -1));
                            } else {
                                tkb.sendMsg(TBM_SETPOS, true, pos);
                            }
                            tkb.mValue = pos;
                        }

                        // We need to refresh Trackbar in order to display our new drawings.
                        InvalidateRect(hWnd, &tkb.mChannelRc, false);

                        tkb.mTrackChange = TrackChange.mouseDrag;
                        if (tkb.onDragged) tkb.onDragged(tkb, new EventArgs());
                        if (tkb.onValueChanged) tkb.onValueChanged(tkb, new EventArgs());
                    break;
                    case THUMB_LINE_HIGH:
                        tkb.setupValueInternal(cast(int)tkb.sendMsg(TBM_GETPOS, 0, 0));
                        tkb.mTrackChange = TrackChange.arrowHigh;
                        if (tkb.onValueChanged) tkb.onValueChanged(tkb, new EventArgs());
                    break;
                    case THUMB_LINE_LOW:
                        tkb.setupValueInternal(cast(int)tkb.sendMsg(TBM_GETPOS, 0, 0));
                        tkb.mTrackChange = TrackChange.arrowLow;
                        if (tkb.onValueChanged) tkb.onValueChanged(tkb, new EventArgs());
                    break;
                    case THUMB_PAGE_HIGH:
                        tkb.setupValueInternal(cast(int)tkb.sendMsg(TBM_GETPOS, 0, 0));
                        tkb.mTrackChange = TrackChange.pageHigh;
                        if (tkb.onValueChanged) tkb.onValueChanged(tkb, new EventArgs());
                    break;
                    case THUMB_PAGE_LOW:
                        tkb.setupValueInternal(cast(int)tkb.sendMsg(TBM_GETPOS, 0, 0));
                        tkb.mTrackChange = TrackChange.pageLow;
                        if (tkb.onValueChanged) tkb.onValueChanged(tkb, new EventArgs());
                    break;
                    case TB_THUMBTRACK:
                        tkb.setupValueInternal(cast(int)tkb.sendMsg(TBM_GETPOS, 0, 0));
                        if (tkb.onDragging) tkb.onDragging(tkb, new EventArgs());
                    break;
                    default: break;
                }
            break;
            case CM_NOTIFY:
                TrackBar tkb = getControl!TrackBar(refData);
                auto nmh = cast(LPNMHDR) lParam;
                final switch (nmh.code) {
                    case NM_CUSTOMDRAW:
                        if (tkb.mCustDraw) {
                            auto nmcd = cast(LPNMCUSTOMDRAW) lParam;
                            if (nmcd.dwDrawStage == CDDS_PREPAINT) return CDRF_NOTIFYITEMDRAW;

                            if (nmcd.dwDrawStage ==  CDDS_ITEMPREPAINT) {
                                if (nmcd.dwItemSpec == TBCD_TICS) {
                                    if (!tkb.mNoTics) {
                                        tkb.drawTics(nmcd.hdc);
                                        return CDRF_SKIPDEFAULT;
                                    }
                                }

                                if (nmcd.dwItemSpec == TBCD_CHANNEL) {
                                    /*------------------------------------------------------------------ 
                                    Python proect is using EDGE_SUNKEN style without BF_FLAT.
                                    But D gives a strange outline in those flags. So I decided to use...
                                    these flags. But in this case, we don't need to reduce 1 point from...
                                    the coloring rect. It looks perfect without changing rect. 
                                    ----------------------------------------------------------------------*/
                                    if (tkb.mChannelSTyle == ChannelStyle.classic) {
                                        DrawEdge(nmcd.hdc, &nmcd.rc, BDR_SUNKENOUTER, tkb.mChannelFlag);
                                    } else {
                                        SelectObject(nmcd.hdc, tkb.mChannelPen);
                                        Rectangle(nmcd.hdc, nmcd.rc.left, nmcd.rc.top, nmcd.rc.right, nmcd.rc.bottom );
                                    }

                                    if (tkb.mSelRange) {// Fill the selection range
                                        auto rc = tkb.getThumbRect();
                                        if (tkb.fillChannelRect(nmcd, rc)) InvalidateRect(hWnd, &nmcd.rc, false);
                                    }
                                    return CDRF_SKIPDEFAULT;
                                }
                            }
                        } else {
                            return CDRF_DODEFAULT;
                        }
                    break;
                    case 4_294_967_280: // con.TRBN_THUMBPOSCHANGING:                        
                        tkb.mTrackChange = TrackChange.mouseClick;
                    break;
                }
            break;
            default: return DefSubclassProc(hWnd, message, wParam, lParam); 
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}
