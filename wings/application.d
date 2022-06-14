// module winglib.application;

// import core.runtime ;
// import std.string;


// import core.sys.windows.windef;
// import core.sys.windows.winuser;
// import core.sys.windows.winbase;

// import winglib.events;

// HMODULE gModuleInstance;

// class Application {

//     import winglib.window : Window;
    
    
    

//     @property Window mainWindow() { return this.mMainWindow ; } 
//     @property void mainWindow(Window win) {  this.mMainWindow = win; } 

//     /// Name of the window class
//     @property wstring className() { return this.mClsName ; } 

//     /// Module instance handle of current exe
//     @property HMODULE instanceHandle() { return this.mHinstance ; }

//     /// Constructor of application class
//     this() {
//         this.mClsName = "WingLib-Window" ;
//         this.mHinstance = GetModuleHandleW(null) ;
//         gModuleInstance = this.mHinstance;
//         this.regWindowClass();
//         this.clkData = ClickData();
//     }
// //---------------------------------------------------------------------
   

//     /// This function will enter our program into the main loop
//     void mainLoop() {
//         this.mainWindow.showWindow();        
//         while (GetMessage(&uMsg, null, 0, 0)) {
//             switch (uMsg.message){   
//                 case WM_LBUTTONDOWN :
//                     clkData.downTime = uMsg.time;
//                     break;
//                 case WM_LBUTTONUP :
//                     clkData.upTime = uMsg.time;
//                     if ((clkData.upTime - clkData.downTime) < 100) {
//                         PostMessage(uMsg.hwnd, um_single_Click, uMsg.wParam, uMsg.lParam);
//                     }
//                     break;
//                 case WM_RBUTTONDOWN :
//                     clkData.rightDownTime = uMsg.time;
//                     break;
//                 case WM_RBUTTONUP :
//                     clkData.rightUpTime = uMsg.time;
//                     if ((clkData.rightUpTime - clkData.rightDownTime) < 200) {                    
//                         PostMessage(uMsg.hwnd, um_right_click, uMsg.wParam, uMsg.lParam);
//                     }
//                     break;  
//                 default: break  ;        
//             }

//             TranslateMessage(&uMsg);
//             DispatchMessage(&uMsg);
//         }
//     }
// //---------------------------------------------------------------------
 
// private :
//     HMODULE mHinstance ;
//     Window mMainWindow;    
//     wstring mClsName ;
//     WNDCLASSW wndclass;
//     MSG uMsg ;
//     ClickData clkData;



//     int regWindowClass() {  
    
//         import winglib.window : fpWndProc = wndProc;
//         wndclass.style         = CS_HREDRAW | CS_VREDRAW | CS_DBLCLKS ;
//         wndclass.lpfnWndProc   = &fpWndProc;
//         wndclass.cbClsExtra    = 0;
//         wndclass.cbWndExtra    = 0;
//         wndclass.hInstance     = this.mHinstance;
//         wndclass.hIcon         = LoadIconW(null, IDI_APPLICATION);
//         wndclass.hCursor       = LoadCursorW(null, IDC_ARROW);
//         wndclass.hbrBackground = cast(HBRUSH)COLOR_WINDOW;
//         wndclass.lpszMenuName  = null;
//         wndclass.lpszClassName = this.mClsName.ptr;

//         if (!RegisterClassW(&wndclass)) {           
//             return 0;
//         }
//         return 1 ;
//     } 
       
// }