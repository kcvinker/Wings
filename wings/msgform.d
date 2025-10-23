module wings.msgform;
// wings.msgform - Created on 16-Aug-2025 09:22

import core.sys.windows.windows;
import wings.events : MessageHandler;
import wings.trayicon : TrayIcon;
import wings.timer : Timer, regNewHotKey;
import wings.events : EventHandler;
import wings.enums: Key, TrayMenuTrigger;
import wings.commons: getAs, CM_TIMER_DESTROY, print;
import wings.application : appData, mowClass, GEA;




class MessageForm 
{    
    // Signature of MessageHandler = bool delegate(MessageForm sender, UINT message, 
    //                                                WPARAM wParam, LPARAM lParam)
    this(MessageHandler pFun, bool autoc = false)
    {
        if (!appData.isMowInint) appData.initMowMode();
        this.mMsgHandler = pFun;
        if (autoc) this.createHandle();
    }

    ~this()
    {
        if (!this.mNotray && this.mTray) {
            destroy(this.mTray);
        }
        if (this.mHkeyMap.length) {
            foreach (hkid; this.mHkeyMap.keys) {
                UnregisterHotKey(this.mHandle, hkid);
            }
            this.mHkeyMap.clear;
        }
        if (this.mTimerMap.length) {
            foreach (tid, tmr; this.mTimerMap) {
                tmr.dtor();
            }
            this.mTimerMap.clear;
        }
        print("MessageForm destructor worked");
    }

    void createHandle()
    {
        import wings.commons : setThisPtrOnWindows;        
        this.mHandle = CreateWindowExW(0, mowClass.ptr, null, 
                                        0, 0, 0, 0, 0, HWND_MESSAGE, 
                                        null, appData.hInstance, null);
        if (this.mHandle) {
            setThisPtrOnWindows(this, this.mHandle);
        }
    }

    void addTrayIcon(string traytip, string iconpath = "")
    {
        if (this.handle) this.mTray = new TrayIcon(traytip, iconpath);
    }

    void addTrayContextMenu(bool cdraw = false, 
                            TrayMenuTrigger trigger = TrayMenuTrigger.anyClick,
                            string[] menuNames...)
    {
        if (this.mTray) {
            this.mTray.addContextMenu(cdraw, trigger, menuNames);
        }
    }

    void startListening()
    {
        MSG uMsg;
        scope(exit) appData.finalize();
        while (GetMessage(&uMsg, null, 0, 0) != 0) {
            TranslateMessage(&uMsg);
            DispatchMessage(&uMsg);
        }
        // writeln("Main loop returned");        
    }

    void close() 
    {
        if (this.handle) DestroyWindow(this.handle);
    }

    int addHotKey(Key[] keyList, EventHandler pFunc, bool noRepeat = false )
    {
        int hkid = regNewHotKey(this.mHandle, keyList, noRepeat);
        if (hkid > -1) {
            this.mHkeyMap[hkid] = pFunc;
        }
        return hkid;
    }

    void removeHotKey(int hkeyID)
    {
        if (hkeyID in this.mHkeyMap) {
            auto res = UnregisterHotKey(this.mHandle, hkeyID);
        }
    }

    Timer addTimer(EventHandler pFunc, uint interval_ms = 100)
    {
        auto tmr = new Timer(this.mHandle, interval_ms, pFunc);
        this.mTimerMap[tmr.id] = tmr;
        return tmr;
    }

    string trayTip() {return this.mTraytip;}
    string trayIconPath() {return this.mTrayIconPath;}
    TrayIcon trayIcon() {return this.mTray;}
    bool noTray() {return this.mNotray;}
    HWND handle() {return this.mHandle;}
    HINSTANCE instanceHandle() {return appData.hInstance;}

    

    private:
    string mTraytip;
    string mTrayIconPath;
    TrayIcon mTray;
    bool mIsActive;
    bool mNotray;
    HWND mHandle;
    Timer[UINT_PTR] mTimerMap;
    EventHandler[int] mHkeyMap;
    MessageHandler mMsgHandler;

}


extern(Windows)
LRESULT msgFormWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) nothrow
{
    try {
        switch (message) {            
            case WM_DESTROY: 
                // auto mf = getAs!MessageForm(hWnd);                
                // if (mf.onClosed) mf.onClosed(mf, new EventArgs()); 
                print("Msg-Only Window destroyed"); 
                PostQuitMessage(0);
                return 0;            
            break;
            case WM_GETMINMAXINFO:
                goto case;
            case WM_NCCREATE:
                goto case;
            case WM_NCCALCSIZE:
                goto case;
            case WM_CREATE: 
                DefWindowProcW(hWnd, message, wParam, lParam);
            break;
            case WM_HOTKEY:
                auto mf = getAs!MessageForm(hWnd); 
                int hkid = cast(int)wParam;
                EventHandler pFunc = mf.mHkeyMap.get(hkid, null);
                if (pFunc) {
                    pFunc(mf, GEA);
                }
                return 0;
            break;
            case WM_TIMER:
                auto mf = getAs!MessageForm(hWnd); 
                auto tid = cast(UINT_PTR)wParam;
                if (tid in mf.mTimerMap){
                    auto timer = mf.mTimerMap[tid];
                    if (timer && timer.onTick) timer.onTick(mf, GEA); 
                    return 0;
                }                
            break;
            case CM_TIMER_DESTROY:
                auto mf = getAs!MessageForm(hWnd);
                auto tid = cast(UINT_PTR)wParam;
                if (tid in mf.mTimerMap) {
                    mf.mTimerMap.remove(tid);
                }
                return 0;
            break;
            default: 
                auto mf = getAs!MessageForm(hWnd);
                bool res = mf.mMsgHandler(mf, message, wParam, lParam);
                if (res) {
                    return 0;
                } else {
                    return DefWindowProcW(hWnd, message, wParam, lParam); 
                }
            break;
        }
    }
    catch (Exception e){}
    return DefWindowProcW(hWnd, message, wParam, lParam);
}