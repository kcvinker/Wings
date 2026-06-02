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
    import wings.commons: print;
    
    
    
    UINT interval;
    EventHandler onTick;

    /// Creates new timer. If notifyOnDestroy is true, it will send a message to parentHwnd...
    /// when the timer is destroyed, with wParam = timer's id and lParam = 0. 
    this(HWND parentHwnd, UINT interval, EventHandler handler = null, bool notifyOnDestroy = false)
    {
        this.mParentHwnd = parentHwnd;
        this.interval = interval;
        if (handler) this.onTick = handler;
        this.mIdNum = cast(UINT_PTR)(cast(void*)this);
        this.mNotifyOnDestroy = notifyOnDestroy;
    }

    ~this()
    {        
        if (this.mIsEnabled) {
            KillTimer(this.mParentHwnd, this.mIdNum);
            print("Timer destructor killed the timer");
        }
        if (this.mNotifyOnDestroy) {
            SendMessageW(this.mParentHwnd, CM_TIMER_DESTROY, this.mIdNum, 0);
        }
    }

    /// Starts the timer. If it's already running, it will be restarted.
    void start()
    {
        this.mIsEnabled = true;
        SetTimer(this.mParentHwnd, this.mIdNum, this.interval, null);
    }

    /// Restarts the timer. If it's not running, it will be started.
    void restart()
    {
        if (this.mIsEnabled) KillTimer(this.mParentHwnd, this.mIdNum);
        SetTimer(this.mParentHwnd, this.mIdNum, this.interval, null);
        this.mIsEnabled = true;
    }

    /// Stops the timer. It can be restarted with start or restart method.
    void stop()
    {
        KillTimer(this.mParentHwnd, this.mIdNum);
        this.mIsEnabled = false;
    }

    /// Destroys the timer. It cannot be restarted after this.
    void destroy()
    {
        if (this.mIsEnabled) {
            KillTimer(this.mParentHwnd, this.mIdNum);
        }
        if (this.mNotifyOnDestroy) {
            SendMessageW(this.mParentHwnd, CM_TIMER_DESTROY, this.mIdNum, 0);
        }
    }

    UINT_PTR id() {return this.mIdNum;}

    package:
    UINT_PTR mIdNum;
    bool mIsEnabled;

    private:    
    HWND mParentHwnd;
    bool mNotifyOnDestroy;
    
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

