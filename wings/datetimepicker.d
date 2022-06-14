
// Created on 08-May-2022 10:48:00
module wings.datetimepicker ; 

import wings.d_essentials;
import std.conv : to ;
import wings.wings_essentials;
import wings.date_and_time ;



int dtpNumber = 1 ;
bool isDtpInit = false;


enum DWORD DTN_FIRST  = (0U-740U) ;
enum DWORD MCS_NOTRAILINGDATES = 0x40 ;
enum DWORD MCS_SHORTDAYSOFWEEK = 0x80 ;
enum DWORD DTM_SETMCSTYLE = DTM_FIRST + 11 ;
enum DWORD DTN_USERSTRING = DTN_FIRST - 5 ;

struct NMDATETIMESTRINGW {
    NMHDR nmhdr ;
    LPCWSTR pszUserString;
    SYSTEMTIME st ;
    DWORD dwFlags ;
}



/**
 * DateTimePicker 
 */
class DateTimePicker : Control {

    /// Returns the format string of DateTimPicker
    final string formatString() {return this.mFormatString ;}
    /// Set the format string of DateTimPicker
    final void formatString(string value) {this.setFormatString(value);  }
    /// Returns the format of DateTimPicker
    final DtpFormat format() {return this.mFormat;}
    /// Set the format of DateTimPicker
    final void format(DtpFormat value) {this.mFormat = value;}
    final bool rightAligned() {return this.mRightAlign;}
    final void rightAligned(bool value) {this.mRightAlign = value;}
    final bool fourDigitYear() {return this.mFourDigitYear;}
    final void fourDigitYear(bool value) {this.mFourDigitYear = value;}
    final bool showWeekNumber() {return this.mShowWeekNum;}
    final void showWeekNumber(bool value) {this.mShowWeekNum = value;}
    final bool noTodayCircle() {return this.mNotdCircle;}
    final void noTodayCircle(bool value) {this.mNotdCircle = value;}
    final bool noToday() {return this.mNoToday;}
    final void noToday(bool value) {this.mNoToday = value;}
    final bool noTrailingDates() {return this.mNoTrlDates;}
    final void noTrailingDates(bool value) {this.mNoTrlDates = value;}
    final bool shortDateNames() {return this.mShortDnames;}
    final void shortDateNames(bool value) {this.mShortDnames = value;}
    final bool showUpDown() {return this.mShowUpdown;}
    final void showUpDown(bool value) {this.mShowUpdown = value;}
    final DateTime value() {return this.mValue;}
    final void value(bool value) {this.mShowUpdown = value;}
    

	EventHandler onCalendarOpened ;
	EventHandler onValueChanged ;
	EventHandler onCalendarClosed ;
	DateTimeEventHandler onTextChanged ;

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
        mControlType = ControlType.dateTimePicker ;   
        this.mExStyle = 0 ;
        this.mFormat = DtpFormat.custom ;
        this.mFormatString = " dd-MMM-yyyy";
        this.mClsName = DATETIMEPICK_CLASS.toUTF16z() ;
        ++dtpNumber ;        
    }

    this(Window p ) { this(p, 20, 20, 140, 25) ; }
    this(Window p, int x, int y ) { this(p, x, y, 140, 25) ; }

    final void create() {
    	this.setDtpStyles() ;
        this.createHandle() ; 
        if (this.mHandle) {            
            this.setSubClass(&dtpWndProc) ;            
            this.afterCreationStyling() ;
            
        }        
    }

    package :
        int dropDownCount ; // DTN_DATETIMECHANGE notification occures two times. So we need to limit it to once.



	private :
		DtpFormat mFormat ;
		string mFormatString ;
		bool mRightAlign ;
		bool mFourDigitYear ;
		DateTime mValue ;
		bool mShowWeekNum ;
		bool mNotdCircle ;
    	bool mNoToday ;
    	bool mNoTrlDates ;
    	bool mShortDnames ;
    	bool mShowUpdown ;
        DWORD mCalStyle ;

        void setDtpStyles() { // Private
            switch (this.mFormat) {
                case DtpFormat.custom :
                    this.mStyle = WS_TABSTOP | WS_CHILD| WS_VISIBLE | DTS_LONGDATEFORMAT | DTS_APPCANPARSE ;                                       
                    break ;
                case DtpFormat.longDate :
                    this.mStyle = WS_TABSTOP | WS_CHILD|WS_VISIBLE|DTS_LONGDATEFORMAT ;
                    break ;
                case DtpFormat.shortDate :                    
                    if (this.mFourDigitYear) {
                        this.mStyle = WS_TABSTOP | WS_CHILD|WS_VISIBLE|DTS_SHORTDATECENTURYFORMAT ;
                    } else {
                        this.mStyle = WS_TABSTOP | WS_CHILD|WS_VISIBLE|DTS_SHORTDATEFORMAT ;
                    }
                    break;
                case DtpFormat.timeOnly :
                    this.mStyle = WS_TABSTOP | WS_CHILD|WS_VISIBLE|DTS_TIMEFORMAT ;
                    break;
                default : break ;
            }

            if (this.mShowWeekNum) this.mCalStyle |= MCS_WEEKNUMBERS;
            if (this.mNotdCircle) this.mCalStyle |= MCS_NOTODAYCIRCLE;
            if (this.mNoToday) this.mCalStyle |= MCS_NOTODAY;
            if (this.mNoTrlDates) this.mCalStyle |= MCS_NOTRAILINGDATES;
            if (this.mShortDnames) this.mCalStyle |= MCS_SHORTDAYSOFWEEK;

            if (this.mRightAlign) this.mStyle |= DTS_RIGHTALIGN;
            if (this.mShowUpdown) this.mStyle ^=  DTS_UPDOWN;
        }

        void afterCreationStyling() { // Private
            if (this.mFormat == DtpFormat.custom) {
                /*  Here, we have a strange situation. Since, we are working with unicode string, we need...
                    to use the W version functions & messages. So, here DTM_SETFORMATW is the candidate. 
                    But it won't work. For some unknown reason, only DTM_SETFORMATA is working here. So we need...
                    to pass a null terminated c string ptr to this function. Why MS, why ?
                */
                this.sendMsg(DTM_SETFORMATA, 0, this.mFormatString.ptr) ;                
            }
            if (this.mCalStyle > 0 ) this.sendMsg(DTM_SETMCSTYLE, 0, this.mCalStyle) ;            
        }

        void setFormatString(string fmt) { // Private
            // When user changes format string, this function will be called
            this.mFormatString = fmt ;
            if (this.mFormat != DtpFormat.custom) this.mFormat = DtpFormat.custom;
            if (this.mIsCreated) this.sendMsg(DTM_SETFORMATA, 0, this.mFormatString.ptr);            
        }


} // End of DateTimePicker Class

extern(Windows)
private LRESULT dtpWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData) {
    try {   
        DateTimePicker dtp = getControl!DateTimePicker(refData) ;
         
        switch (message) {
            case WM_DESTROY :
                dtp.remSubClass(scID);
                break ;
            case WM_PAINT :
                if (dtp.onPaint) {
                    PAINTSTRUCT ps ;
                    auto hdc = BeginPaint(hWnd, &ps) ;
                    auto pea = new PaintEventArgs(&ps) ;
                    dtp.onPaint(dtp, pea) ;
                    return 0 ;
                } 
                break ;
            case CM_NOTIFY :
                auto nm = cast(NMHDR *) lParam ;  
                print("nm.code", nm.code) ;              
                switch (nm.code) {
                    case DTN_USERSTRING :
                        if (dtp.onTextChanged) {                            
                            auto dts = cast(NMDATETIMESTRINGW *) lParam ;                            
                            auto dea = new DateTimeEventArgs(dts.pszUserString) ;
                            dtp.onTextChanged(dtp, dea) ;                            
                            if (dea.handled) {
                                sendMsg(hWnd, DTM_SETSYSTEMTIME, 0, dea.dateStruct) ;
                            }
                        }
                        break ;
                    case DTN_DROPDOWN :
                        if (dtp.onCalendarOpened) {
                            auto ea = new EventArgs();
                            dtp.onCalendarOpened(dtp, ea) ;
                            return 0 ;
                        }
                        break ;
                    case DTN_DATETIMECHANGE :
                        //print("time change arrived");
                        if (dtp.dropDownCount == 0) {
                            dtp.dropDownCount = 1;
                            auto nmd = cast(NMDATETIMECHANGE *) lParam;
                            dtp.mValue = DateTime(nmd.st);
                            if (dtp.onValueChanged) {
                                auto ea = new EventArgs();
                                dtp.onValueChanged(dtp, ea) ;
                                return 0;
                            }
                        } else if (dtp.dropDownCount == 1) {
                            dtp.dropDownCount = 0 ;
                            return 0;
                        }
                        break ;
                    case DTN_FORMATQUERY :
                        
                    case DTN_CLOSEUP :
                        if (dtp.onCalendarClosed) {
                            auto ea = new EventArgs();
                            dtp.onCalendarClosed(dtp, ea);
                        }
                        break ;
                    //--------------------------------------
                    case WM_LBUTTONDOWN : 
                        //print("in main wnd proc", 1) ;
                        dtp.lDownHappened = true ;  
                        if (dtp.onMouseDown) {
                        auto mea = new MouseEventArgs(message, wParam, lParam);
                        dtp.onMouseDown(dtp, mea) ;
                        return 0 ;
                        }
                        break ;
                    

                    case WM_LBUTTONUP :
                        if (dtp.onMouseUp) {
                            auto mea = new MouseEventArgs(message, wParam, lParam) ;
                            dtp.onMouseUp(dtp, mea) ;                    
                        }
                        if (dtp.lDownHappened) {
                            dtp.lDownHappened = false ;
                            sendMsg(dtp.handle, CM_LEFTCLICK, 0, 0) ;                    
                        } break ;

                    case CM_LEFTCLICK :
                        if (dtp.onMouseClick) {
                            auto ea = new EventArgs() ;
                            dtp.onMouseClick(dtp, ea) ;
                        } break ;


                    case WM_RBUTTONDOWN :
                        dtp.rDownHappened = true ;
                        if (dtp.onRightMouseDown) {
                            auto mea = new MouseEventArgs(message, wParam, lParam) ;
                            dtp.onRightMouseDown(dtp, mea) ; 
                            return 0 ;
                        } break ;

                    case WM_RBUTTONUP :
                        if (dtp.onRightMouseUp) {
                            auto mea = new MouseEventArgs(message, wParam, lParam) ;
                            dtp.onRightMouseUp(dtp, mea) ;                     
                        } 
                        if (dtp.rDownHappened) {
                            dtp.rDownHappened = false ;
                            sendMsg(dtp.handle, CM_RIGHTCLICK, 0, 0) ;                    
                        } break ;

                    case CM_RIGHTCLICK :
                        if (dtp.onRightClick) {
                            auto ea = new EventArgs() ;
                            dtp.onRightClick(dtp, ea) ;
                        } break ;

                    case WM_MOUSEWHEEL :
                        if (dtp.onMouseWheel) {
                            auto mea = new MouseEventArgs(message, wParam, lParam) ;
                            dtp.onMouseWheel(dtp, mea) ; 
                        } break ;

                    case WM_MOUSEMOVE :
                        if (dtp.isMouseEntered) {
                            if (dtp.onMouseMove) {
                                auto mea = new MouseEventArgs(message, wParam, lParam) ;
                                dtp.onMouseMove(dtp, mea) ;
                            }
                        } else {
                            dtp.isMouseEntered = true ;
                            //print("entered in main wnd proc", 2) ; 
                            if (dtp.onMouseEnter) {
                                auto ea = new EventArgs() ;
                                dtp.onMouseEnter(dtp, ea) ;
                            }
                        } break ;

                    case WM_MOUSELEAVE : 
                        dtp.isMouseEntered = false ;
                        if (dtp.onMouseLeave) {
                            auto ea = new EventArgs() ;
                            dtp.onMouseLeave(dtp, ea) ;
                        } break ;


                    default : break ;


                } 
                //return 1 ;
                break ;

            default : return DefSubclassProc(hWnd, message, wParam, lParam) ;
        }        
    }
    catch (Exception e) {}     
    return DefSubclassProc(hWnd, message, wParam, lParam);
}
