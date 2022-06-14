module winglib.wnd_proc_module;

private import core.runtime;
private import core.sys.windows.windows ;

private import std.stdio : log = writeln;
private import winglib.window;
private import winglib.events;
private import winglib.enums ;

void trackMouseMove(HWND hw) {
    TRACKMOUSEEVENT tme ;    
    tme.cbSize = tme.sizeof ;
    tme.dwFlags = TME_HOVER | TME_LEAVE ;
    tme.dwHoverTime = HOVER_DEFAULT ;
    tme.hwndTrack = hw ; 
    TrackMouseEvent(&tme) ;
}


/// WndProc function for Window class
extern(Windows)
LRESULT mainWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) nothrow { 

    try {
        auto win = cast(Window) (cast(void *) GetWindowLongPtrW(hWnd, GWLP_USERDATA)) ;       
        switch (message) { 

            case WM_SHOWWINDOW : 
                if (!win.mIsLoaded) {
                    win.mIsLoaded = true ;
                    if (win.onLoad) {
                        auto ea = new EventArgs() ;
                        win.onLoad(win, ea) ;
                    }
                }
                break ;             
            
            case WM_ACTIVATEAPP : 
                if (win.onActivate || win.onDeActivate) {
                    auto ea = new EventArgs() ;
                    immutable bool flag = cast(bool) wParam ;
                    if (!flag) {
                        if (win.onDeActivate) {
                            win.onDeActivate(win, ea) ;
                        }
                        return 0 ;                        
                    }
                    else {
                        if (win.onActivate) {
                            win.onActivate(win, ea) ;
                        }
                    }
                }
                break ;
            

            case WM_KEYUP, WM_SYSKEYUP : 
                if (win.onKeyUp) {
                    auto ea = new KeyEventArgs(wParam) ;
                    win.onKeyUp(win, ea) ;                    
                }
                break ;
            
            case WM_KEYDOWN, WM_SYSKEYDOWN :
                if (win.onKeyDown) {
                    auto ea = new KeyEventArgs(wParam) ;
                    win.onKeyDown(win, ea) ;
                } break ;
                
            case WM_CHAR : 
                if (win.onKeyPress) {
                    auto ea = new KeyPressEventArgs(wParam) ;
                    win.onKeyPress(win, ea) ;
                } break ;
                

            case WM_LBUTTONDOWN : 
                if (win.onMouseDown) {
                    auto ea = new MouseEventArgs(message, wParam, lParam);
                    win.onMouseDown(win, ea);                     
                } break ;
                
            case WM_LBUTTONUP :
                if (win.onMouseUp) {
                    auto ea = new MouseEventArgs(message, wParam, lParam) ;
                    win.onMouseUp(win, ea) ;
                } break ;
                
            case WM_RBUTTONDOWN :
                if (win.onRMouseDown) {
                    auto ea = new MouseEventArgs(message, wParam, lParam) ;
                    win.onRMouseDown(win, ea) ;
                } break ;
            
            case WM_RBUTTONUP :
                if (win.onRMouseUp) {
                    auto ea = new MouseEventArgs(message, wParam, lParam) ;
                    win.onRMouseUp(win, ea) ;
                } break ;
                
            case WM_MOUSEWHEEL :
                if (win.onMouseWheel) {
                    auto ea = new MouseEventArgs(message, wParam, lParam) ;
                    win.onMouseWheel(win, ea) ;
                } break ;

            case WM_MOUSEMOVE :
                if (!win.mIsMouseTracking) {
                    win.mIsMouseTracking = true ;
                    trackMouseMove(hWnd);
                    if (!win.mIsMouseEntered) {
                        if (win.onMouseEnter) {
                            win.mIsMouseEntered = true ;
                            auto ea = new EventArgs() ;
                            win.onMouseEnter(win, ea) ;
                        }
                    }
                }
                if (win.onMouseMove) {
                    auto ea = new MouseEventArgs(message, wParam, lParam) ;
                    win.onMouseMove(win, ea) ;
                } break ;
            
            case WM_MOUSEHOVER :
                if (win.mIsMouseTracking) {win.mIsMouseTracking = false ;}
                if (win.onMouseHover) {
                    auto ea = new MouseEventArgs(message, wParam, lParam) ;
                    win.onMouseHover(win, ea) ;
                } break ;
                
            case WM_MOUSELEAVE :
                if (win.mIsMouseTracking) {
                    win.mIsMouseTracking = false ;
                    win.mIsMouseEntered = false ;
                }
                if (win.onMouseLeave) {
                    auto ea = new EventArgs() ;
                    win.onMouseLeave(win, ea) ;
                } break ;
            
            case WM_SYSCOMMAND :
                auto uMsg = cast(UINT) (wParam & 0xFFF0) ;
                switch (uMsg) {
                    case SC_MINIMIZE :
                        if (win.onMinimized) {
                            auto ea = new EventArgs() ;
                            win.onMinimized(win, ea) ;
                        } break ;
                    case SC_MAXIMIZE :
                        if (win.onMaximized) {
                            auto ea = new EventArgs() ;
                            win.onMaximized(win, ea) ;
                        } break ;
                    case SC_RESTORE :
                        if (win.onRestored) {
                            auto ea = new EventArgs() ;
                            win.onRestored(win, ea) ;
                        } break ;
                    default : break ;
                } break ;


                
            
            
            case WM_ERASEBKGND : 
                if (win.mBkDrawMode != WindowBkMode.normal) {   
                    auto dch = cast(HDC) wParam ;
                    win.setBkClrInternal(dch) ;
                    return 1 ;                  
                } 
                break ;
                
            case WM_CLOSE :
                if (win.onClosing) {
                    auto ea = new EventArgs() ;
                    win.onClosing(win, ea) ;
                } break ;

            case WM_DESTROY :
                if (win.onClosed) {
                    auto ea = new EventArgs() ;
                    win.onClosed(win, ea) ;
                }

                if (hWnd == mainHwnd) PostQuitMessage(0);
                break;
            

            default: break ;
        }
    }
    catch (Exception e){}
    return DefWindowProcW(hWnd, message, wParam, lParam);
}
