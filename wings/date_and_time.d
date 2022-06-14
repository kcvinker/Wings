module wings.date_and_time ;

private import core.sys.windows.windows ;

enum WeekDays {sunday, monday, tuesday, wednesday, thursday, friday, saturday} ;

struct DateTime {
	int year ;
	int month ;
	int day ;
	int hour ;
	int minute ;
	int second ;
	int milliSeond ;
	WeekDays dayOfWeek ;
	

	this(SYSTEMTIME st) {
		this.year = st.wYear ;
		this.month = st.wMonth ;
		this.day = st.wDay ;
		this.hour = st.wHour ;
		this.minute = st.wMinute ;
		this.second = st.wSecond ;
		this.milliSeond = st.wMilliseconds ;
		this.dayOfWeek = cast(WeekDays) st.wDayOfWeek ;
	} 

	this(int Year, int Month, int Day) {
		this.year = Year ;
		this.month = Month ;
		this.day = Day ;
		this.hour = 0 ;
		this.minute = 0 ;
		this.second = 0 ;
		this.milliSeond = 0 ;
		this.dayOfWeek = cast(WeekDays) Day ;
	}

	this(int Year, int Month, WeekDays Day) {
		this(Year, Month, cast(int) Day) ;
	}

	this(int Year, int Month, int Day, int Hour, int Minute, int Second) {
		this.year = Year ;
		this.month = Month ;
		this.day = Day ;
		this.hour = Hour ;
		this.minute = Minute ;
		this.second = Second ;
		this.milliSeond = ((Hour * 3600) + (Minute * 60) + Second) * 1000 ;
		this.dayOfWeek = cast(WeekDays) Day ;
	}


	final static DateTime now() {
		SYSTEMTIME st ;
		GetLocalTime(&st) ;
		DateTime dt ;
		dt.year = st.wYear ;
		dt.month = st.wMonth ;
		dt.day = st.wDay ;
		dt.hour = st.wHour ;
		dt.minute = st.wMinute ;
		dt.second = st.wSecond ;
		dt.milliSeond = st.wMilliseconds ;
		dt.dayOfWeek = cast(WeekDays) st.wDayOfWeek ;
		return dt ;
	}


}

