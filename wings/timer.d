module wings.timer; // Created - Unknown date: Modified on 16-Aug-2024 02:24

import core.sys.windows.windows;



class Timer {
    import wings.events: EventHandler;
    
    UINT interval;
    EventHandler onTick;

    this(HWND parentHwnd, UINT interval, EventHandler handler)
    {
        this.mParentHwnd = parentHwnd;
        this.interval = interval;
        this.onTick = handler;
        this.mIdNum = cast(UINT_PTR)(cast(void*)this);
    }

    ~this()
    {
        if (this.mIsEnabled) KillTimer(this.mParentHwnd, this.mIdNum);
    }

    void start()
    {
        this.mIsEnabled = true;
        SetTimer(this.mParentHwnd, this.mIdNum, this.interval, null);
    }

    void stop()
    {
        KillTimer(this.mParentHwnd, this.mIdNum);
        this.mIsEnabled = false;
    }

    package:
    UINT_PTR mIdNum;
    private:    
    HWND mParentHwnd;
    bool mIsEnabled;
}


