module wings.timer; // Created - Unknown date: Modified on 16-Aug-2024 02:24
/*==============================================Timer Docs=====================================
    Constructor:
        this(HWND parentHwnd, UINT interval, EventHandler handler)
        You can use Form's addTimer method.

	Properties:
        interval    : uint
			
    Methods:
        start
        stop    
        destroy    
        
    Events:
        EventHandler - void delegate(Object, EventArgs)
            onTick       
=============================================================================================*/

import core.sys.windows.windows;
import wings.enums: Key;



class Timer {
    import wings.events: EventHandler;
    import wings.commons: CM_TIMER_DESTROY;
    
    
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
        if (this.mIsEnabled) {
            KillTimer(this.mParentHwnd, this.mIdNum);
        }
        SendMessageW(this.mParentHwnd, CM_TIMER_DESTROY, this.mIdNum, 0);
        
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

    void destroy()
    {
        if (this.mIsEnabled) {
            KillTimer(this.mParentHwnd, this.mIdNum);
        }
        SendMessageW(this.mParentHwnd, CM_TIMER_DESTROY, this.mIdNum, 0);
    }

    package void dtor()
    {
        if (this.mIsEnabled) {
            KillTimer(this.mParentHwnd, this.mIdNum);
        }
    }

    UINT_PTR id() {return this.mIdNum;}

    package:
    UINT_PTR mIdNum;
    private:    
    HWND mParentHwnd;
    bool mIsEnabled;
}


int regNewHotKey(HWND hwnd, Key[] keyList,  bool repeat = false)
{
    import wings.application: appData;
    int res = -1;
    uint fmod = 0;
    uint vkey = 0;
    foreach (k; keyList) {
        if (k == Key.ctrl) {
            fmod |= 0x0002;
        } else if (k == Key.alt) {
            fmod |= 0x0001;
        } else if (k == Key.shift) {
            fmod |= 0x0004;
        } else if ((k == Key.leftWin) | (k == Key.rightWin)) {
            fmod |= 0x0008;
        } else if (k < 256) { // assuming key codes are < 256
            vkey = cast(uint)k;
        }
    }
    if (!repeat) fmod |= 0x4000;
    if (RegisterHotKey(hwnd, appData.globalHotKeyID, fmod, vkey)) {
        res = appData.globalHotKeyID;
        appData.globalHotKeyID += 1;
    }
    return res;
}

