module wings.groupbox;
// GroupBox class -  Created on : 24-May-22 10:59:01 AM

import wings.d_essentials;
import wings.wings_essentials;


int gbNumber = 1 ;

class GroupBox : Control {

    this(Window parent, string txt, int x, int y, int w, int h) {              
        mWidth = w ;
        mHeight = h ;
        mXpos = x ;
        mYpos = y ;
        mParent = parent ;
        mFont = parent.font ;        
        mControlType = ControlType.groupBox ;   
        mText = txt ; 
        mStyle = WS_CHILD | WS_VISIBLE | BS_GROUPBOX | BS_NOTIFY | BS_TEXT | BS_TOP ;
        mExStyle =WS_EX_TRANSPARENT | WS_EX_CONTROLPARENT ;       
        mBackColor = parent.backColor ;
        mBClrRef = getClrRef(parent.backColor) ;
        mFClrRef = getClrRef(this.mForeColor) ;
        mClsName = WC_BUTTON.toUTF16z() ;    
        ++gbNumber;        
    }

    this(Window parent, string txt, int x, int y) {
        this(parent, txt, x, y, 150, 150);
    }

    this(Window parent, string txt) {
        this(parent, txt, 20, 20, 150, 150);
    }
    
    final void create() {
        if (this.mBackColor == this.parent.backColor) this.isPaintBkg = true;
        this.createHandle();
        if (this.mHandle) {            
            this.setSubClass(&gbWndProc) ;            
            //this.setCbSize() ;           
        }    
    }

    package :
        HBRUSH mBkBrush ;
        bool isPaintBkg ;

        final void finalize() { // Package
            // This is our destructor. Clean all the dirty stuff
            DeleteObject(this.mBkBrush) ;
        }

    
} // End of GroupBox class

extern(Windows)
private LRESULT gbWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData)  {
    try {   
        GroupBox gb = getControl!GroupBox(refData) ; 
        switch (message) {
            case WM_DESTROY :
                gb.finalize() ;
                gb.remSubClass(scID);
                break ;
            case WM_PAINT :
                if (gb.onPaint) {
                    PAINTSTRUCT  ps ;
                    BeginPaint(hWnd, &ps) ;
                    auto pea = new PaintEventArgs(&ps) ;
                    gb.onPaint(gb, pea) ;
                    EndPaint(hWnd, &ps) ;
                    return 0 ;
                }  break ;
            case CM_CTLCOLOR :            
                auto hdc = cast(HDC) wParam;
                SetBkMode(hdc, TRANSPARENT) ;           
                gb.mBkBrush = CreateSolidBrush(gb.mBClrRef);
                if (gb.mForeColor != 0x000000) SetTextColor(hdc, gb.mFClrRef) ;      
                return cast(LRESULT) gb.mBkBrush;
                break ;
            case WM_ERASEBKGND :  
                if (gb.isPaintBkg) {
                    auto hdc = cast(HDC) wParam;
                    RECT rc ;
                    GetClientRect(gb.handle, &rc);
                    rc.bottom -= 2  ;       
                    FillRect(hdc, &rc, CreateSolidBrush(gb.mBClrRef))  ;             
                    return 1 ;                    
                }                  
                break ;

            case WM_MOUSEWHEEL :
                if (gb.onMouseWheel) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    gb.onMouseWheel(gb, mea) ; 
                } break ;

            case WM_MOUSEMOVE :
                if (gb.isMouseEntered) {
                    if (gb.onMouseMove) {
                        auto mea = new MouseEventArgs(message, wParam, lParam) ;
                        gb.onMouseMove(gb, mea) ;
                    }
                } else {
                    gb.isMouseEntered = true ;
                    if (gb.onMouseEnter) {
                        auto ea = new EventArgs() ;
                        gb.onMouseEnter(gb, ea) ;
                    }
                } break ;

            case WM_MOUSELEAVE :
                gb.isMouseEntered = false ;
                if (gb.onMouseLeave) {
                    auto ea = new EventArgs() ;
                    gb.onMouseLeave(gb, ea) ;
                } break ;
        
            default : return DefSubclassProc(hWnd, message, wParam, lParam) ;
        }
    }
    catch (Exception e) {}     
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

