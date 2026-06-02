module wings.msgform;
// wings.msgform - Created on 16-Aug-2025 09:22

import core.sys.windows.windows;
import wings.events : MessageHandler;
import wings.trayicon : TrayIcon;
import wings.timer : Timer, regNewHotKey;
import wings.events : EventHandler;
import wings.enums: Key, TrayMenuTrigger;
import wings.commons: fromHwndTo, CM_TIMER_DESTROY, print;
import wings.application : appData, mowClass, GEA;


/* Signature for MessageHandler pFun in MessageForm constructor:
bool delegate(MessageForm sender, UINT message, WPARAM wParam, LPARAM lParam)
-----------------------------------------------------------------------------*/


class MessageForm 
{    
    
    /// Creates a message-only window. You can use this to add tray icons, 
    /// hotkeys, timers, and handle messages without showing any window.
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
                tmr.destroy();
            }
            this.mTimerMap.clear;
        }
        print("MessageForm destructor worked");
    }

    ///  Creates the message-only window handle. You can call this in the constructor or later when you need it.
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

    /// Adds a tray icon with the specified tooltip and optional icon path. 
    /// You must have a valid handle before calling this.
    void addTrayIcon(string traytip, string iconpath = "")
    {
        if (this.handle) this.mTray = new TrayIcon(traytip, iconpath);
    }

    /// Adds a context menu to the tray icon. You must call addTrayIcon first.
    void addTrayContextMenu(bool cdraw = false, 
                            TrayMenuTrigger trigger = TrayMenuTrigger.anyClick,
                            string[] menuNames...)
    {
        if (this.mTray) {
            this.mTray.addContextMenu(cdraw, trigger, menuNames);
        }
    }

    /// Starts the message loop. This will block until the window is destroyed. 
    /// You can call this after setting up your timers, hotkeys, and tray icon. 
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

    /// Closes the message-only window. This will cause the message loop to exit.
    void close() 
    {
        if (this.handle) DestroyWindow(this.handle);
    }

    /// Adds a click handler for a specific menu item in the tray icon's context menu. 
    /// You must call addTrayContextMenu first.
    void addTrayMenuClickHandler(string menuName, EventHandler callback)
    {
        if (this.mTray && this.mTray.mCmenu) {
            this.mTray.mCmenu.addClickHandler(menuName, callback);
        }
    }

    /// Adds a hotkey to the message-only window. 
    /// You must have a valid handle before calling this.
    int addHotKey(Key[] keyList, EventHandler pFunc, bool noRepeat = false )
    {
        int hkid = regNewHotKey(this.mHandle, keyList, noRepeat);
        if (hkid > -1) {
            this.mHkeyMap[hkid] = pFunc;
        }
        return hkid;
    }

    /// Removes a hotkey by its ID. You can get the ID from addHotKey method.
    void removeHotKey(int hkeyID)
    {
        if (hkeyID in this.mHkeyMap) {
            auto res = UnregisterHotKey(this.mHandle, hkeyID);
        }
    }

    /// Removes all hotkeys registered by this MessageForm.
    void removeAllHotKeys()
    {
        foreach (hkid; this.mHkeyMap.keys) {
            UnregisterHotKey(this.mHandle, hkid);
        }
        this.mHkeyMap.clear;
    }

    /// Adds a timer to the message-only window. 
    Timer addTimer(EventHandler pFunc, uint interval_ms = 100)
    {
        auto tmr = new Timer(this.mHandle, interval_ms, pFunc, true);
        this.mTimerMap[tmr.id] = tmr;
        return tmr;
    }

    /// Returns the tray tip text if a tray icon is set, otherwise returns an empty string.
    string trayTip() {return this.mTraytip;}
    
    /// Returns the tray icon path if a tray icon is set, otherwise returns an empty string.
    string trayIconPath() {return this.mTrayIconPath;}
    
    /// Returns the tray icon if set, otherwise returns null.
    TrayIcon trayIcon() {return this.mTray;}
    
    /// Sets whether the tray icon is disabled.
    bool noTray() {return this.mNotray;}

    /// Returns the handle of the message-only window. You must have a valid handle before calling this.
    HWND handle() {return this.mHandle;}

    /// Returns instance handle of the Message-Only window. 
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
        auto self = fromHwndTo!MessageForm(hWnd);
        switch (message) {            
            case WM_DESTROY: 
                // auto mf = fromHwndTo!MessageForm(hWnd);                
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
                int hkid = cast(int)wParam;
                EventHandler pFunc = self.mHkeyMap.get(hkid, null);
                if (pFunc) {
                    pFunc(self, GEA);
                }
                return 0;
            break;
            case WM_TIMER: 
                auto tid = cast(UINT_PTR)wParam;
                if (tid in self.mTimerMap){
                    auto timer = self.mTimerMap[tid];
                    if (timer && timer.onTick) timer.onTick(self, GEA); 
                    return 0;
                }                
            break;
            case CM_TIMER_DESTROY:
                auto tid = cast(UINT_PTR)wParam;
                if (tid in self.mTimerMap) {
                    self.mTimerMap.remove(tid);
                }
                return 0;
            break;
            default: 
                bool res = self.mMsgHandler(self, message, wParam, lParam);
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