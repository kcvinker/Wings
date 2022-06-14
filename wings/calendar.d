
module wings.calendar ;

import core.sys.windows.windows ;
import core.sys.windows.commctrl ;
import std.utf;
//----------------------------------------------------
import wings.wings_essentials;
import wings.date_and_time ;

int calNumber = 1 ;
DWORD calExStyle = 0 ;

enum MCS_NOTRAILINGDATES = 0x40 ;
enum MCS_SHORTDAYSOFWEEK = 0x80 ;
enum MCM_SETCURRENTVIEW = MCM_FIRST + 32 ;
enum MCN_VIEWCHANGE = MCN_FIRST - 4 ;

struct NMVIEWCHANGE {
    NMHDR nmhdr;
    DWORD dwOldView;
    DWORD dwNewView;
}

private bool isCalanderInit = false;

class Calendar : Control {

	final DateTime value() {return this.mValue ;}
	final void value(DateTime value) {this.mValue = value ;}

    final ViewMode viewMode() {return this.mViewMode ; }
    final void viewMode(ViewMode value) {
        this. mViewMode = value ;
        if (this.mIsCreated) this.sendMsg!(int, int)(MCM_SETCURRENTVIEW, 0, this.mViewMode) ;
    }

    final ViewMode oldViewMode() {return this.mOldView ;}
    final void oldViewMode(ViewMode value) {this. mOldView = value ;}

    final bool showWeekNumber() {return this.mShowWeekNum ;}
    final void showWeekNumber(bool value) {this.mShowWeekNum = value;}

    final bool noTodayCircle() {return this.mNotdCircle ; }
    final void noTodayCircle(bool value) {this.mNotdCircle = value;}

    final bool noToday() {return this.mNoToday ; }
    final void noToday(bool value) {this.mNoToday = value;}

    final bool noTrailingDates() {return this.mNoTrDates ;}
    final void noTrailingDates(bool value) {this.mNoTrDates = value;}

    final bool shortDateNames() {return this.mShortDnames ; }
    final void shortDateNames(bool value) {this.mShortDnames = value;}

    EventHandler valueChanged, selectionChanged, viewChanged ;

	 this(Window p, int x, int y, int w, int h) {   
        if (!appData.isDtpInit) {
            appData.isDtpInit = true;
            appData.iccEx.dwICC = ICC_DATE_CLASSES;
            InitCommonControlsEx(&appData.iccEx);
        }
        mWidth = w ;
        mHeight = h ;
        mXpos = x ;
        mYpos = y ;
        mParent = p ;
        mFont = p.font ;
        mControlType = ControlType.calendar ;   
        this.mStyle = WS_CHILD | WS_VISIBLE ;
        this.mExStyle = 0 ;
        this.mClsName = MONTHCAL_CLASS.toUTF16z;
        ++calNumber ;        
    }

    this(Window p, int x, int y) { this(p, x, y, 0, 0) ; }

    final void create() { 
    	this.setCalenderStyles() ;
        this.createHandle() ;        // Calling base function
        if (this.mHandle) {            
            this.setSubClass(&calWndProc) ;
            RECT rct ;
            this.sendMsg(MCM_GETMINREQRECT, 0, &rct) ;
            SetWindowPos(this.mHandle, null, this.mXpos, this.mYpos, rct.right, rct.bottom, SWP_NOZORDER) ;              
            if (this.mViewMode != ViewMode.month) this.sendMsg(MCM_SETCURRENTVIEW, 0, this.mViewMode) ;         
            
        }        
    }

    private :
    	DateTime mValue ;
    	ViewMode mViewMode ;
    	ViewMode mOldView ;
    	bool mShowWeekNum ;
    	bool mNotdCircle ;
    	bool mNoToday ;
    	bool mNoTrDates ;
    	bool mShortDnames ;
    	DWORD styles, exStyles ;

    	void setCalenderStyles() {
    		if (this.mShowWeekNum) this.styles |= MCS_WEEKNUMBERS ;
    		if (this.mNotdCircle) this.styles |= MCS_NOTODAYCIRCLE ;
    		if (this.mNoToday) this.styles  |= MCS_NOTODAY ;
    		if (this.mNoTrDates) this.styles |= MCS_NOTRAILINGDATES ;
    		if (this.mShortDnames) this.styles |= MCS_SHORTDAYSOFWEEK ;
    	}
} // End of Calendar class


extern(Windows)
private LRESULT calWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData) {
    try {   
        Calendar cal = getControl!Calendar(refData) ; 
        switch (message) {
            case WM_DESTROY :
                cal.remSubClass(scID);
                break ;
            case WM_PAINT :
                if (cal.onPaint) {
                    PAINTSTRUCT ps ;
                    auto hdc = BeginPaint(hWnd, &ps) ;
                    auto pea = new PaintEventArgs(&ps) ;
                    cal.onPaint(cal, pea) ;
                    return 0 ;
                } 
                break ;
            case CM_NOTIFY :
                auto nm = cast(NMHDR *) lParam ;
                switch (nm.code) {
                    case MCN_SELECT :
                        auto nms = cast(NMSELCHANGE *) lParam ;
                        cal.value = DateTime(nms.stSelStart) ;
                        if (cal.valueChanged) {
                            auto ea = new EventArgs() ;
                            cal.valueChanged(cal, ea) ;                            
                        } 
                        break ; 
                    case MCN_SELCHANGE :
                        auto nms = cast(NMSELCHANGE *) lParam ;
                        cal.value = DateTime(nms.stSelStart) ;
                        if (cal.selectionChanged) {
                            auto ea = new EventArgs() ;
                            cal.selectionChanged(cal, ea) ;                            
                        }
                        break ;
                    case MCN_VIEWCHANGE :
                        auto nmv = cast(NMVIEWCHANGE *) lParam ;
                        cal.viewMode = cast(ViewMode) nmv.dwNewView ;
                        cal.oldViewMode = cast(ViewMode) nmv.dwOldView ;
                        if (cal.viewChanged) {
                            auto ea = new EventArgs() ;
                            cal.viewChanged(cal, ea) ;
                        }
                        break ;
                    default : break ;
                }
                break ;

            case WM_LBUTTONDOWN : { 
                cal.lDownHappened = true ;  
               if (cal.onMouseDown) {
                   auto mea = new MouseEventArgs(message, wParam, lParam);
                   cal.onMouseDown(cal, mea) ;
                   return 0 ;
               }
                break ;
            }

            case WM_LBUTTONUP :
                if (cal.onMouseUp) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    cal.onMouseUp(cal, mea) ;                    
                }
                if (cal.lDownHappened) {
                    cal.lDownHappened = false ;
                    sendMsg(cal.handle, CM_LEFTCLICK, 0, 0) ;                    
                } break ;

            case CM_LEFTCLICK :
                if (cal.onMouseClick) {
                    auto ea = new EventArgs() ;
                    cal.onMouseClick(cal, ea) ;
                } break ;


            case WM_RBUTTONDOWN :
                cal.rDownHappened = true ;
                if (cal.onRightMouseDown) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    cal.onRightMouseDown(cal, mea) ; 
                    return 0 ;
                } break ;

            case WM_RBUTTONUP :
                if (cal.onRightMouseUp) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    cal.onRightMouseUp(cal, mea) ;                     
                } 
                if (cal.rDownHappened) {
                    cal.rDownHappened = false ;
                    sendMsg(cal.handle, CM_RIGHTCLICK, 0, 0) ;                    
                } break ;

            case CM_RIGHTCLICK :
                if (cal.onRightClick) {
                    auto ea = new EventArgs() ;
                    cal.onRightClick(cal, ea) ;
                } break ;

            case WM_MOUSEWHEEL :
                if (cal.onMouseWheel) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    cal.onMouseWheel(cal, mea) ; 
                } break ;

            case WM_MOUSEMOVE :
                if (cal.isMouseEntered) {
                    if (cal.onMouseMove) {
                        auto mea = new MouseEventArgs(message, wParam, lParam) ;
                        cal.onMouseMove(cal, mea) ;
                    }
                } else {
                    cal.isMouseEntered = true ;
                    if (cal.onMouseEnter) {
                        auto ea = new EventArgs() ;
                        cal.onMouseEnter(cal, ea) ;
                    }
                } break ;

            case WM_MOUSELEAVE :
                cal.isMouseEntered = false ;
                if (cal.onMouseLeave) {
                    auto ea = new EventArgs() ;
                    cal.onMouseLeave(cal, ea) ;
                } break ;



          	default : return DefSubclassProc(hWnd, message, wParam, lParam) ;
        }
        
    }
    catch (Exception e) {} 

    
    return DefSubclassProc(hWnd, message, wParam, lParam);
}
