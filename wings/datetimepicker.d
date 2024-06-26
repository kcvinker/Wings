
// Created on 08-May-2022 10:48:00
module wings.datetimepicker; // Change the wndproc code - 09-feb-2023

import wings.d_essentials;
import std.conv : to;
import wings.wings_essentials;
import wings.date_and_time;



int dtpNumber = 1;
bool isDtpInit = false;
private wchar[] mClassName = ['S','y','s','D','a','t','e','T','i','m','e','P','i','c','k','3','2', 0];

enum DWORD DTN_FIRST  = (0U-740U);
enum DWORD MCS_NOTRAILINGDATES = 0x40;
enum DWORD MCS_SHORTDAYSOFWEEK = 0x80;
enum DWORD DTM_SETMCSTYLE = DTM_FIRST + 11;
enum DWORD DTN_USERSTRING = DTN_FIRST - 5;
enum DWORD DTM_GETIDEALSIZE = (DTM_FIRST + 15);

struct NMDATETIMESTRINGW
{
    NMHDR nmhdr;
    LPCWSTR pszUserString;
    SYSTEMTIME st;
    DWORD dwFlags;
}



/**
 * DateTimePicker
 */
class DateTimePicker : Control
{

    /// Returns the format string of DateTimPicker
    final string formatString() {return this.mFormatString;}
    /// Set the format string of DateTimPicker
    final void formatString(string value) {this.setFormatString(value); }
    /// Returns the format of DateTimPicker
    mixin finalProperty!("format", this.mFormat);
    mixin finalProperty!("rightAligned", this.mRightAlign);
    mixin finalProperty!("fourDigitYear", this.mFourDigitYear);
    mixin finalProperty!("showWeekNumber", this.mShowWeekNum);
    mixin finalProperty!("noTodayCircle", this.mNotdCircle);
    mixin finalProperty!("noToday", this.mNoToday);
    mixin finalProperty!("noTrailingDates", this.mNoTrlDates);
    mixin finalProperty!("shortDateNames", this.mShortDnames);
    mixin finalProperty!("showUpDown", this.mShowUpdown);
    mixin finalProperty!("value", this.mValue);

	EventHandler onCalendarOpened;
	EventHandler onValueChanged;
	EventHandler onCalendarClosed;
	DateTimeEventHandler onTextChanged;

	this(Window parent, int x, int y, int w, int h, bool autoc = false)
    {
        if (!appData.isDtpInit) {
            appData.isDtpInit = true;
            appData.iccEx.dwICC = ICC_DATE_CLASSES;
            InitCommonControlsEx(&appData.iccEx);
        }

        mixin(repeatingCode);
        mControlType = ControlType.dateTimePicker;
        this.mExStyle = 0;
        this.mFormat = DtpFormat.custom;
        this.mFormatString = " dd-MMM-yyyy";
        this.mParent.mControls ~= this;
        this.mCtlId = Control.stCtlId;
        ++Control.stCtlId;
        ++dtpNumber;
        if (autoc) this.createHandle();
    }

    this(Window p ) { this(p, 20, 20, 140, 25); }
    this(Window p, int x, int y,bool autoc = false ) { this(p, x, y, 140, 25, autoc); }

    override void createHandle()
    {
    	this.setDtpStyles();
        this.createHandleInternal(mClassName.ptr);
        if (this.mHandle) {
            this.setSubClass(&dtpWndProc);
            this.afterCreationStyling();
        }
    }

    package :
        int dropDownCount; // DTN_DATETIMECHANGE notification occures two times. So we need to limit it to once.



	private :
		DtpFormat mFormat;
		string mFormatString;
		bool mRightAlign;
		bool mFourDigitYear;
		DateTime mValue;
		bool mShowWeekNum;
		bool mNotdCircle;
    	bool mNoToday;
    	bool mNoTrlDates;
    	bool mShortDnames;
    	bool mShowUpdown;
        DWORD mCalStyle;

        void setDtpStyles()
        { // Private
            switch (this.mFormat) {
                case DtpFormat.custom :
                    this.mStyle = WS_TABSTOP | WS_CHILD| WS_VISIBLE | DTS_LONGDATEFORMAT | DTS_APPCANPARSE;
                    break;
                case DtpFormat.longDate :
                    this.mStyle = WS_TABSTOP | WS_CHILD|WS_VISIBLE|DTS_LONGDATEFORMAT;
                    break;
                case DtpFormat.shortDate :
                    if (this.mFourDigitYear) {
                        this.mStyle = WS_TABSTOP | WS_CHILD|WS_VISIBLE|DTS_SHORTDATECENTURYFORMAT;
                    } else {
                        this.mStyle = WS_TABSTOP | WS_CHILD|WS_VISIBLE|DTS_SHORTDATEFORMAT;
                    }
                    break;
                case DtpFormat.timeOnly :
                    this.mStyle = WS_TABSTOP | WS_CHILD|WS_VISIBLE|DTS_TIMEFORMAT;
                    break;
                default : break;
            }

            if (this.mShowWeekNum) this.mCalStyle |= MCS_WEEKNUMBERS;
            if (this.mNotdCircle) this.mCalStyle |= MCS_NOTODAYCIRCLE;
            if (this.mNoToday) this.mCalStyle |= MCS_NOTODAY;
            if (this.mNoTrlDates) this.mCalStyle |= MCS_NOTRAILINGDATES;
            if (this.mShortDnames) this.mCalStyle |= MCS_SHORTDAYSOFWEEK;

            if (this.mRightAlign) this.mStyle |= DTS_RIGHTALIGN;
            if (this.mShowUpdown) this.mStyle ^=  DTS_UPDOWN;
        }

        void afterCreationStyling()
        { // Private
            if (this.mFormat == DtpFormat.custom) {
                /*  Here, we have a strange situation. Since, we are working with unicode string, we need...
                    to use the W version functions & messages. So, here DTM_SETFORMATW is the candidate.
                    But it won't work. For some unknown reason, only DTM_SETFORMATA is working here. So we need...
                    to pass a null terminated c string ptr to this function. Why MS, why ?
                */
                this.sendMsg(DTM_SETFORMATA, 0, this.mFormatString.ptr);
            }
            if (this.mCalStyle > 0 ) this.sendMsg(DTM_SETMCSTYLE, 0, this.mCalStyle);
            SIZE ss;
            this.sendMsg(DTM_GETIDEALSIZE, 0, &ss);
            this.mWidth = ss.cx + 2;
            this.mHeight = ss.cy + 5;
            SetWindowPos(this.mHandle, null, this.mXpos, this.mYpos, this.mWidth, this.mHeight, SWP_NOZORDER);
        }

        void setFormatString(string fmt)
        { // Private
            // When user changes format string, this function will be called
            this.mFormatString = fmt;
            if (this.mFormat != DtpFormat.custom) this.mFormat = DtpFormat.custom;
            if (this.mIsCreated) this.sendMsg(DTM_SETFORMATA, 0, this.mFormatString.ptr);
        }


} // End of DateTimePicker Class

extern(Windows)
private LRESULT dtpWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                                UINT_PTR scID, DWORD_PTR refData)
{
    try {
        DateTimePicker dtp = getControl!DateTimePicker(refData);
        switch (message) {
            case WM_DESTROY : RemoveWindowSubclass(hWnd, &dtpWndProc, scID); break;
            case WM_PAINT : dtp.paintHandler(); break;
            case WM_SETFOCUS : dtp.setFocusHandler(); break;
            case WM_KILLFOCUS : dtp.killFocusHandler(); break;
            case WM_LBUTTONDOWN : dtp.mouseDownHandler(message, wParam, lParam); break;
            case WM_LBUTTONUP : dtp.mouseUpHandler(message, wParam, lParam); break;
            case CM_LEFTCLICK : dtp.mouseClickHandler(); break;
            case WM_RBUTTONDOWN : dtp.mouseRDownHandler(message, wParam, lParam); break;
            case WM_RBUTTONUP : dtp.mouseRUpHandler(message, wParam, lParam); break;
            case CM_RIGHTCLICK : dtp.mouseRClickHandler(); break;
            case WM_MOUSEWHEEL : dtp.mouseWheelHandler(message, wParam, lParam); break;
            case WM_MOUSEMOVE : dtp.mouseMoveHandler(message, wParam, lParam); break;
            case WM_MOUSELEAVE : dtp.mouseLeaveHandler(); break;

            case CM_NOTIFY :
                auto nm = cast(NMHDR *) lParam;
                //print("nm.code", nm.code);
                switch (nm.code) {
                    case DTN_USERSTRING :
                        if (dtp.onTextChanged) {
                            auto dts = cast(NMDATETIMESTRINGW *) lParam;
                            auto dea = new DateTimeEventArgs(dts.pszUserString);
                            dtp.onTextChanged(dtp, dea);
                            if (dea.handled) {
                                sendMsg(hWnd, DTM_SETSYSTEMTIME, 0, dea.dateStruct);
                            }
                        }
                    break;

                    case DTN_DROPDOWN :
                        if (dtp.onCalendarOpened) {
                            auto ea = new EventArgs();
                            dtp.onCalendarOpened(dtp, ea);
                            return 0;
                        }
                    break;

                    case DTN_DATETIMECHANGE :
                        //print("time change arrived");
                        if (dtp.dropDownCount == 0) {
                            dtp.dropDownCount = 1;
                            auto nmd = cast(NMDATETIMECHANGE *) lParam;
                            dtp.mValue = DateTime(nmd.st);
                            if (dtp.onValueChanged) {
                                auto ea = new EventArgs();
                                dtp.onValueChanged(dtp, ea);
                                return 0;
                            }
                        } else if (dtp.dropDownCount == 1) {
                            dtp.dropDownCount = 0;
                            return 0;
                        }
                    break;

                    case DTN_FORMATQUERY :

                    case DTN_CLOSEUP :
                        if (dtp.onCalendarClosed) {
                            auto ea = new EventArgs();
                            dtp.onCalendarClosed(dtp, ea);
                        }
                    break;
                    default : break;
                }
                //return 1;
            break;
            default : return DefSubclassProc(hWnd, message, wParam, lParam);
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}
