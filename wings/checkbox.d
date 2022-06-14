
module wings.checkbox ;

import wings.d_essentials;
import wings.wings_essentials;



private int cbNumber = 1 ;
/**
 * CheckBox : Control 
 */
class CheckBox : Control {   

    /// Get the checked state of CheckBox.
    final bool checked() {return this.mChecked ;}

    /// Set the checked state of CheckBox.
    final void checked(bool value) {
        this.mChecked = value;
        if (this.mIsCreated) {
            int bState = value ? BST_CHECKED : BST_UNCHECKED ;            
            this,sendMsg(BM_SETCHECK, bState, 0 );
        }
    }   

    EventHandler onCheckedChanged ;

	this(Window parent, string txt, int x, int y, int w, int h) {              
        mWidth = w ;
        mHeight = h ;
        mXpos = x ;
        mYpos = y ;
        mParent = parent ;
        mFont = parent.font ;
        mAutoSize = true ;
        mControlType = ControlType.checkBox ;   
        mText = txt ; 
        mStyle = WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX ;
        mExStyle = WS_EX_LTRREADING | WS_EX_LEFT ;
        mTxtStyle = DT_SINGLELINE | DT_VCENTER  ; 
        mBackColor = parent.backColor ;
        mBClrRef = getClrRef(parent.backColor) ;
        mFClrRef = getClrRef(this.mForeColor) ;
        mClsName = WC_BUTTON.toUTF16z() ;    
        ++cbNumber;        
    }

    this(Window parent) {
    	string txt = format("CheckBox_%s", cbNumber) ;
    	this(parent, txt, 20, 20, 50, 20) ;
    }

    this(Window parent, string txt) { this(parent, txt, 20, 20, 50, 20);}

    this (Window parent, string txt, int x, int y) { this(parent, txt, x, y, 50, 20); }

    // Create the handle of CheckBox
    final void create() {
    	this.setCbStyles() ;        
        this.createHandle();    
        if (this.mHandle) {            
            this.setSubClass(&cbWndProc) ;            
            this.setCbSize() ;           
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
		bool mChecked ;		
		bool mAutoSize ;		
		uint mTxtStyle ;      


		void setCbStyles() { // Private
            // We need to set some checkbox styles
			if (this.mRightAlign) {
				this.mStyle |= BS_RIGHTBUTTON ;
				this.mTxtStyle |= DT_RIGHT ;
			}
		}

        void setCbSize() { // Private
            // We need to find the width & hight to provide the auto size feature.
            SIZE ss ;
            this.sendMsg(BCM_GETIDEALSIZE, 0, &ss);
            this.mWidth = ss.cx;
            this.mHeight = ss.cy;
            MoveWindow(this.mHandle, this.mXpos, this.mYpos, ss.cx, ss.cy, true) ;
        }
}

extern(Windows)
private LRESULT cbWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData)  {
    try {   
        CheckBox cb = getControl!CheckBox(refData)  ;
        switch (message) {
            case WM_DESTROY :
                cb.finalize ;
                cb.remSubClass(scID);
                break ;
            case WM_PAINT :
                if (cb.onPaint) {
                    PAINTSTRUCT  ps ;
                    BeginPaint(hWnd, &ps) ;
                    auto pea = new PaintEventArgs(&ps) ;
                    cb.onPaint(cb, pea) ;
                    EndPaint(hWnd, &ps) ;
                    return 0 ;
                }  break ;
            case CM_CTLCOMMAND :
                cb.mChecked = cast(bool) SendMessage(hWnd, BM_GETCHECK, 0, 0) ;
                if (cb.onCheckedChanged) {
                    auto ea = new EventArgs();
                    cb.onCheckedChanged(cb, ea);
                } break ;
            
            case CM_COLORSTATIC :         
                // We need to use this message to change the back color.
                // There is no other ways to change the back color.       
                auto hdc = cast(HDC) wParam ;              
                SetBkMode(hdc, TRANSPARENT);
                cb.mBkBrush = CreateSolidBrush(cb.mBClrRef);                    
                return cast(LRESULT) cb.mBkBrush ; 
                break ;
                

            case CM_NOTIFY :
                // We need to use this message to draw the fore color.
                // There is no other ways to change the text color. 
                auto nmc = cast(NMCUSTOMDRAW *) lParam;
                switch (nmc.dwDrawStage) {
                    case CDDS_PREERASE :
                        return CDRF_NOTIFYPOSTERASE ;
                        break ;
                    case CDDS_PREPAINT :
                        auto rct = nmc.rc ;
                        if (!cb.mRightAlign) {
                            rct.left += 18 ;
                        } else {rct.right -= 18 ;}
                        SetTextColor(nmc.hdc, cb.mFClrRef) ;
                        DrawText(nmc.hdc, cb.text.toUTF16z, -1, &rct, cb.mTxtStyle) ;
                        return CDRF_SKIPDEFAULT ;
                        break ;
                    default : break ;
                } break ;

            case WM_LBUTTONDOWN : { 
                cb.lDownHappened = true ;  
                if (cb.onMouseDown) {
                   auto mea = new MouseEventArgs(message, wParam, lParam);
                   cb.onMouseDown(cb, mea) ;
                   return 0 ;
                }
                break ;
            }

            case WM_LBUTTONUP :
                if (cb.onMouseUp) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    cb.onMouseUp(cb, mea) ;                    
                }
                if (cb.lDownHappened) {
                    cb.lDownHappened = false ;
                    sendMsg(cb.handle, CM_LEFTCLICK, 0, 0) ;                    
                } break ;

            case CM_LEFTCLICK :
                if (cb.onMouseClick) {
                    auto ea = new EventArgs() ;
                    cb.onMouseClick(cb, ea) ;
                } break ;


            case WM_RBUTTONDOWN :
                cb.rDownHappened = true ;
                if (cb.onRightMouseDown) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    cb.onRightMouseDown(cb, mea) ; 
                    return 0 ;
                } break ;

            case WM_RBUTTONUP :
                if (cb.onRightMouseUp) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    cb.onRightMouseUp(cb, mea) ;                     
                } 
                if (cb.rDownHappened) {
                    cb.rDownHappened = false ;
                    sendMsg(cb.handle, CM_RIGHTCLICK, 0, 0) ;                    
                } break ;

            case CM_RIGHTCLICK :
                if (cb.onRightClick) {
                    auto ea = new EventArgs() ;
                    cb.onRightClick(cb, ea) ;
                } break ;

            case WM_MOUSEWHEEL :
                if (cb.onMouseWheel) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    cb.onMouseWheel(cb, mea) ; 
                } break ;

            case WM_MOUSEMOVE :
                if (cb.isMouseEntered) {
                    if (cb.onMouseMove) {
                        auto mea = new MouseEventArgs(message, wParam, lParam) ;
                        cb.onMouseMove(cb, mea) ;
                    }
                } else {
                    cb.isMouseEntered = true ;
                    if (cb.onMouseEnter) {
                        auto ea = new EventArgs() ;
                        cb.onMouseEnter(cb, ea) ;
                    }
                } break ;

            case WM_MOUSELEAVE :
                cb.isMouseEntered = false ;
                if (cb.onMouseLeave) {
                    auto ea = new EventArgs() ;
                    cb.onMouseLeave(cb, ea) ;
                } break ;




            default : return DefSubclassProc(hWnd, message, wParam, lParam) ;
        }
        
    }
    catch (Exception e) {}     
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

