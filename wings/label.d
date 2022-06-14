module wings.label; // Created on : 24-May-2022 05:53:28 PM
import wings.d_essentials;
import wings.wings_essentials;


int lblNumber = 1;

class Label : Control {
    this(Window parent, string txt, int x, int y, int w, int h) {              
        mWidth = w ;
        mHeight = h ;
        mXpos = x ;
        mYpos = y ;
        mParent = parent ;
        mText = txt;
        mFont = parent.font ;        
        mControlType = ControlType.label ; 
        mTxtAlign = TextAlignment.midLeft;        
        mStyle = WS_VISIBLE | WS_CHILD | WS_CLIPCHILDREN | WS_CLIPSIBLINGS | SS_NOTIFY ;
        mExStyle = 0 ; 
        mAutoSize = true;       
        mBackColor = parent.backColor ;
        mForeColor = defForeColor ;        
        mBClrRef = getClrRef(mBackColor) ;
        mFClrRef = getClrRef(defForeColor) ;  
        mClsName = toUTF16z("Static") ;
        ++lblNumber;        
        //mBorder = LabelBorder.singleLine;
    }

    this(Window parent) { this(parent, format("Label_", lblNumber), 20, 20, 0, 0) ; }    
    this(Window parent, int x, int y) { this(parent, format("Label_", lblNumber), x, y, 0, 0) ; }
    this(Window parent, string txt) { this(parent, txt, 20, 20, 0, 0) ; }
    this(Window parent, string txt, int x, int y) { this(parent, txt, x, y, 0, 0) ; }
    

    final void create() {   
        if (this.mBorder != LabelBorder.noBorder) adjustBorder() ;
        this.checkForAutoSize();
       // this.adjustAlignment();
        this.createHandle() ;
        //print("Label Hwnd", this.mHandle);
        if (this.mHandle) {                  
            this.calculateAutoSize(); 
            this.setSubClass(&lblWndProc) ;       
        }        
    }   

    package :
        HBRUSH mBkBrush ;
        bool mRightAlign ;

        final void finalize() { // Package
            // This is our destructor. Clean all the dirty stuff
            DeleteObject(this.mBkBrush) ;
        }
        


    private :
        bool mAutoSize;
        bool mMultiLine;
        LabelBorder mBorder;
        TextAlignment mTxtAlign;
        DWORD dwTxtAlign ;

        void adjustAlignment() { // Private
            final switch (this.mTxtAlign) {
                case TextAlignment.topLeft : this.dwTxtAlign = DT_TOP | DT_LEFT  ; break; 
                case TextAlignment.topCenter : this.dwTxtAlign = DT_TOP | DT_CENTER  ; break;
                case TextAlignment.topRight : this.dwTxtAlign = DT_TOP | DT_RIGHT  ; break;

                case TextAlignment.midLeft : this.dwTxtAlign = DT_VCENTER | DT_LEFT  ; break;
                case TextAlignment.center : this.dwTxtAlign = DT_VCENTER | DT_CENTER  ; break; 
                case TextAlignment.midRight : this.dwTxtAlign = DT_VCENTER | DT_RIGHT  ; break;

                case TextAlignment.bottomLeft : this.dwTxtAlign = DT_BOTTOM | DT_LEFT  ; break;
                case TextAlignment.bottomCenter : this.dwTxtAlign = DT_BOTTOM | DT_CENTER  ; break;
                case TextAlignment.bottomRight : this.dwTxtAlign = DT_BOTTOM | DT_RIGHT    ; break;  

            }
            
            if (this.mMultiLine) {
                this.dwTxtAlign |= DT_WORDBREAK;
            } else {
                this.dwTxtAlign |= DT_SINGLELINE;                
            }
        }

        void adjustBorder() { // Private
            if (this.mBorder == LabelBorder.sunkenBorder) {
                this.mStyle |= SS_SUNKEN;
            } else {
                this.mStyle |= WS_BORDER;
            }
        }

        void checkForAutoSize() { // Private
            if (this.mMultiLine) this.mAutoSize = false ;
            if (this.width != 0) this.mAutoSize = false ;
            if (this.mHeight != 0) this.mAutoSize = false ;
        }

        void calculateAutoSize() {
            auto hdc = GetDC(this.mHandle) ;
            scope(exit) DeleteDC(hdc) ;
            SIZE ss;           
            SelectObject(hdc, this.font.handle);
            GetTextExtentPoint32(hdc, this.mText.toUTF16z(), this.mText.length, &ss );
            this.mWidth = ss.cx + 3 ;
            this.mHeight = ss.cy  ;
            MoveWindow(this.mHandle, this.mXpos, this.mYpos, this.mWidth, this.mHeight, true) ;     
        }

} // End of Label Class

extern(Windows)
private LRESULT lblWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData)  {
    try {   
        Label lbl = getControl!Label(refData)  ;
        //print("message", message) ;
        switch (message) {
            case WM_DESTROY :
                lbl.finalize ;
                lbl.remSubClass(scID);
                break ;

            case WM_PAINT :
                if (lbl.onPaint) {
                    PAINTSTRUCT  ps ;
                    BeginPaint(hWnd, &ps) ;
                    auto pea = new PaintEventArgs(&ps) ;
                    lbl.onPaint(lbl, pea) ;
                    EndPaint(hWnd, &ps) ;
                    return 0 ;
                }  break ;

            case CM_COLORSTATIC :
                print("ctl color happened");
                auto hdc = cast(HDC) wParam;
                SetTextColor(hdc, lbl.mFClrRef);
                SetBkColor(hdc, lbl.mBClrRef);
                lbl.mBkBrush = CreateSolidBrush(lbl.mBClrRef);
                return cast(LRESULT) lbl.mBkBrush; 

            case WM_LBUTTONDOWN : { 
                lbl.lDownHappened = true ;  
                if (lbl.onMouseDown) {
                   auto mea = new MouseEventArgs(message, wParam, lParam);
                   lbl.onMouseDown(lbl, mea) ;
                   return 0 ;
                }
                break ;
            }

            case WM_LBUTTONUP :
                if (lbl.onMouseUp) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    lbl.onMouseUp(lbl, mea) ;                    
                }
                if (lbl.lDownHappened) {
                    lbl.lDownHappened = false ;
                    sendMsg(lbl.handle, CM_LEFTCLICK, 0, 0) ;                    
                } break ;

            case CM_LEFTCLICK :
                if (lbl.onMouseClick) {
                    auto ea = new EventArgs() ;
                    lbl.onMouseClick(lbl, ea) ;
                } break ;


            case WM_RBUTTONDOWN :
                lbl.rDownHappened = true ;
                if (lbl.onRightMouseDown) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    lbl.onRightMouseDown(lbl, mea) ; 
                    return 0 ;
                } break ;

            case WM_RBUTTONUP :
                if (lbl.onRightMouseUp) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    lbl.onRightMouseUp(lbl, mea) ;                     
                } 
                if (lbl.rDownHappened) {
                    lbl.rDownHappened = false ;
                    sendMsg(lbl.handle, CM_RIGHTCLICK, 0, 0) ;                    
                } break ;

            case CM_RIGHTCLICK :
                if (lbl.onRightClick) {
                    auto ea = new EventArgs() ;
                    lbl.onRightClick(lbl, ea) ;
                } break ;

            case WM_MOUSEWHEEL :
                if (lbl.onMouseWheel) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    lbl.onMouseWheel(lbl, mea) ; 
                } break ;

            case WM_MOUSEMOVE :
                if (lbl.isMouseEntered) {
                    if (lbl.onMouseMove) {
                        auto mea = new MouseEventArgs(message, wParam, lParam) ;
                        lbl.onMouseMove(lbl, mea) ;
                    }
                } else {
                    lbl.isMouseEntered = true ;
                    if (lbl.onMouseEnter) {
                        auto ea = new EventArgs() ;
                        lbl.onMouseEnter(lbl, ea) ;
                    }
                } break ;

            case WM_MOUSELEAVE :
                lbl.isMouseEntered = false ;
                if (lbl.onMouseLeave) {
                    auto ea = new EventArgs() ;
                    lbl.onMouseLeave(lbl, ea) ;
                } break ;

            default : return DefSubclassProc(hWnd, message, wParam, lParam) ;
        }
        
    }
    catch (Exception e) {}     
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

