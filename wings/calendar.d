
/*==============================================Calendar Docs=====================================
Constructor:
    this(Form parent, int x, int y, int w, int h)
    this(Form p, int x, int y) 

	Properties:
		Calendar inheriting all Control class properties		
		value               : DateTime
        viewMode            : ViewMode enum [See enums.d]
        oldViewMode         : ViewMode enum
        showWeekNumber      : bool
        noTodayCircle       : bool
        noToday             : bool
        noTrailingDates     : bool
        shortDateNames      : bool

    Methods:
        createHandle
        
    Events:
        All public events inherited from Control class. (See controls.d)
        EventHandler type events - void delegate(Control, EventArgs)
            valueChanged
            selectionChanged
            viewChanged
=============================================================================================*/
module wings.calendar;

// import core.sys.windows.windows;
// import core.sys.windows.commctrl;
 import std.stdio;
//----------------------------------------------------
import wings.d_essentials;
import wings.wings_essentials;
import wings.date_and_time;

int calNumber = 1;
DWORD calExStyle = 0;
private wchar[] mClassName = ['S', 'y', 's', 'M', 'o', 'n', 't', 'h', 'C', 'a', 'l', '3', '2', 0];
enum MCS_NOTRAILINGDATES = 0x40;
enum MCS_SHORTDAYSOFWEEK = 0x80;
enum MCM_SETCURRENTVIEW = MCM_FIRST + 32;
enum MCN_VIEWCHANGE = MCN_FIRST - 4;

struct NMVIEWCHANGE
{
    NMHDR nmhdr;
    DWORD dwOldView;
    DWORD dwNewView;
}

private bool isCalanderInit = false;

class Calendar : Control
{

	//final DateTime value() {return this.mValue;}
	//final void value(DateTime value) {this.mValue = value;}
    mixin finalProperty!("value", this.mValue);

    final ViewMode viewMode() {return this.mViewMode; }
    final void viewMode(ViewMode value)
    {
        this. mViewMode = value;
        if (this.mIsCreated) this.sendMsg!(int, int)(MCM_SETCURRENTVIEW, 0, this.mViewMode);
    }

    //final ViewMode oldViewMode() {return this.mOldView;}
    //final void oldViewMode(ViewMode value) {this. mOldView = value;}
    mixin finalProperty!("oldViewMode", this.mOldView);

    //final bool showWeekNumber() {return this.mShowWeekNum;}
    //final void showWeekNumber(bool value) {this.mShowWeekNum = value;}
    mixin finalProperty!("showWeekNumber", this.mShowWeekNum);

    //final bool noTodayCircle() {return this.mNotdCircle; }
    //final void noTodayCircle(bool value) {this.mNotdCircle = value;}
    mixin finalProperty!("noTodayCircle", this.mNotdCircle);

    //final bool noToday() {return this.mNoToday; }
    //final void noToday(bool value) {this.mNoToday = value;}
    mixin finalProperty!("noToday", this.mNoToday);

    //final bool noTrailingDates() {return this.mNoTrDates;}
    //final void noTrailingDates(bool value) {this.mNoTrDates = value;}
    mixin finalProperty!("noTrailingDates", this.mNoTrDates);

    //final bool shortDateNames() {return this.mShortDnames; }
    //final void shortDateNames(bool value) {this.mShortDnames = value;}
    mixin finalProperty!("shortDateNames", this.mShortDnames);

    EventHandler valueChanged, selectionChanged, viewChanged;

	 this(Form parent, int x, int y, int w, int h)
     {
        if (!appData.isDtpInit) {
            appData.isDtpInit = true;
            appData.iccEx.dwICC = ICC_DATE_CLASSES;
            InitCommonControlsEx(&appData.iccEx);
        }

        mixin(repeatingCode);
        mControlType = ControlType.calendar;
        this.mStyle = WS_CHILD | WS_VISIBLE;
        this.mExStyle = 0;
        this.mName = format("%s_%d", "Calendar_", calNumber);
        this.mParent.mControls ~= this;
        this.mCtlId = Control.stCtlId;
        ++Control.stCtlId;
        ++calNumber;
        if (parent.mAutoCreate) this.createHandle();
        // writefln("mcn first %d, mcn sel changed %d, mcn vew changed %d", MCN_FIRST, MCN_SELCHANGE, MCN_VIEWCHANGE);
    }

    this(Form p, int x, int y) { this(p, x, y, 0, 0); }

    override void createHandle()
    {
    	this.setCalenderStyles();
        this.createHandleInternal(mClassName.ptr);        // Calling base function
        if (this.mHandle) {
            this.setSubClass(&calWndProc);
            RECT rct;
            this.sendMsg(MCM_GETMINREQRECT, 0, &rct);
            SetWindowPos(this.mHandle, null, this.mXpos, this.mYpos, rct.right, rct.bottom, SWP_NOMOVE);
            if (this.mViewMode != ViewMode.month) this.sendMsg(MCM_SETCURRENTVIEW, 0, this.mViewMode);
            SYSTEMTIME st;
            this.sendMsg(MCM_GETCURSEL, 0, &st);
            this.value = DateTime(st);
        }
    }

    private :
    	DateTime mValue;
    	ViewMode mViewMode;
    	ViewMode mOldView;
    	bool mShowWeekNum;
    	bool mNotdCircle;
    	bool mNoToday;
    	bool mNoTrDates;
    	bool mShortDnames;
    	DWORD styles, exStyles;

    	void setCalenderStyles()
        {
    		if (this.mShowWeekNum) this.styles |= MCS_WEEKNUMBERS;
    		if (this.mNotdCircle) this.styles |= MCS_NOTODAYCIRCLE;
    		if (this.mNoToday) this.styles  |= MCS_NOTODAY;
    		if (this.mNoTrDates) this.styles |= MCS_NOTRAILINGDATES;
    		if (this.mShortDnames) this.styles |= MCS_SHORTDAYSOFWEEK;
    	}
} // End of Calendar class


extern(Windows)
private LRESULT calWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                UINT_PTR scID, DWORD_PTR refData)
{
    try {        
        switch (message) {
            case WM_DESTROY : 
                // Calendar cal = getControl!Calendar(refData);
                RemoveWindowSubclass(hWnd, &calWndProc, scID); 
            break;
            case WM_PAINT :
                Calendar cal = getControl!Calendar(refData);
                cal.paintHandler(); 
            break;
            case WM_LBUTTONDOWN :
                Calendar cal = getControl!Calendar(refData);
                cal.mouseDownHandler(message, wParam, lParam); 
            break;
            case WM_LBUTTONUP :
                Calendar cal = getControl!Calendar(refData);
                cal.mouseUpHandler(message, wParam, lParam); 
            break;
            case WM_RBUTTONDOWN :
                Calendar cal = getControl!Calendar(refData);
                cal.mouseRDownHandler(message, wParam, lParam); 
            break;
            case WM_RBUTTONUP :
                Calendar cal = getControl!Calendar(refData);
                cal.mouseRUpHandler(message, wParam, lParam); 
            break;
            case WM_MOUSEWHEEL :
                Calendar cal = getControl!Calendar(refData);
                cal.mouseWheelHandler(message, wParam, lParam); 
            break;
            case WM_MOUSEMOVE :
                Calendar cal = getControl!Calendar(refData);
                cal.mouseMoveHandler(message, wParam, lParam); break;
            case WM_MOUSELEAVE :
                Calendar cal = getControl!Calendar(refData);
                cal.mouseLeaveHandler(); break;
            case CM_NOTIFY :
                Calendar cal = getControl!Calendar(refData);
                auto nm = cast(NMHDR *) lParam;
                switch (nm.code) {
                    case MCN_SELECT :
                        auto nms = cast(NMSELCHANGE *) lParam;
                        cal.value = DateTime(nms.stSelStart);
                        if (cal.valueChanged) cal.valueChanged(cal, new EventArgs());
                        break;
                    case MCN_SELCHANGE :
                        auto nms = cast(NMSELCHANGE *) lParam;
                        cal.value = DateTime(nms.stSelStart);
                        if (cal.selectionChanged) cal.selectionChanged(cal, new EventArgs());
                        break;
                    case MCN_VIEWCHANGE :
                        auto nmv = cast(NMVIEWCHANGE *) lParam;
                        cal.viewMode = cast(ViewMode) nmv.dwNewView;
                        cal.oldViewMode = cast(ViewMode) nmv.dwOldView;
                        if (cal.viewChanged) cal.viewChanged(cal, new EventArgs());
                        break;
                    default : break;
                }
            break;
          	default : return DefSubclassProc(hWnd, message, wParam, lParam); break;
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}
