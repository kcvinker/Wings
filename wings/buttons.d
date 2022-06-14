module wings.buttons;
//---------------------------------------------------

import wings.d_essentials;
import wings.wings_essentials;
 

//------------------------------------------------------

//private DWORD btnStyle = WS_CHILD | BS_NOTIFY | WS_TABSTOP | WS_VISIBLE ;
private DWORD btnExStyle = 0;
private Button[] buttonList;
private static int btnNumber = 1;
private int subClsID = 1001;
private const int mMouseClickFlag = 0b1 ;
private const int mMouseOverFlag = 0b1000000 ;

//---------------------------------------------------------


  
class Button : Control { 
    import wings.gradient ;

// Properties
    final override void foreColor(uint value) {
        this.mForeColor = value ; 
        this.rgbFrg = RgbColor(value) ;      
        switch (this.mDrawMode) {
            case BtnDrawMode.normal :
                this.mDrawMode = BtnDrawMode.textOnly ; break ;
            case BtnDrawMode.bkgOnly :
                this.mDrawMode = BtnDrawMode.textBkg ; break ;
            case BtnDrawMode.gradient :
                this.mDrawMode = BtnDrawMode.gradientText ; break ;
            default : break ;
        }
        this.reDraw();
    }

    final override uint foreColor() const {return this.mForeColor ;}

    final override void backColor(uint value) {
        this.mBackColor = value ;
        this.rgbBkg = RgbColor(value) ;
        switch (this.mDrawMode) {
            case BtnDrawMode.normal :
                this.mDrawMode = BtnDrawMode.bkgOnly ; break ;
            case BtnDrawMode.textOnly :
                this.mDrawMode = BtnDrawMode.textBkg ; break ;            
            default : break ;
        }        
        this.reDraw();
    }

    final override uint backColor() const {return this.mBackColor ;}

    final void setGradientColors(uint clr1, uint clr2, GradientStyle gStyle = GradientStyle.topToBottom) {
        this.gradData = Gradient(clr1, clr2, gStyle) ;        
        switch (this.mDrawMode) {            
            case BtnDrawMode.textOnly, BtnDrawMode.textBkg :
                this.mDrawMode = BtnDrawMode.gradientText ; break ;            
            default : 
                this.mDrawMode = BtnDrawMode.gradient ; break ;
        }
        //writeln("btn draw mode - ", this.mDrawMode) ;
        this.reDraw();
    }

// End of Properties



    
// Ctors
    this(Window parent, string txt, int x, int y, int w, int h) {          
       
        mClsName = "Button".toUTF16z ;
        mWidth = w ;
        mHeight = h ;
        mXpos = x ;
        mYpos = y ;
        mParent = parent ;
        mFont = parent.font ;
        mControlType = ControlType.button ;   
        mText = txt ; 
        mStyle = WS_CHILD | BS_NOTIFY | WS_TABSTOP | WS_VISIBLE | BS_PUSHBUTTON;
        mExStyle = 0;    
        ++btnNumber;        
    }

    this(Window parent) {
        string btxt = format("%s_%d", "Button", btnNumber);
        this(parent, btxt, 20, 20, 100, 35) ;
    }

    this(Window parent, string txt) {
        this(parent, txt, 20, 20, 100, 35) ;
    }

    this(Window parent, string txt, int x, int y) {
        this(parent, txt, x, y, 100, 35) ;
    }

    this(Window parent, int x, int y, int w, int h) {
        string btxt = format("%s_%d", "Button", btnNumber);
        this(parent, btxt, x, y, w, h) ;
    }
// End of Ctors  


    //------------------------------------------------------------------------    
    final void create() {        
        this.createHandle() ;
        if (this.mHandle) {            
            this.setSubClass(&btnWndProc) ;            
        }        
    }   
    

    package :
        BtnDrawMode mDrawMode ;
        DWORD mTxtFlag = DT_SINGLELINE | DT_VCENTER | DT_CENTER | DT_NOPREFIX ;

        // Drawing a button's text at pre paint stage.
        final LRESULT setBtnForeColor(NMCUSTOMDRAW * ncd) {           
            SetTextColor(ncd.hdc, this.rgbFrg.clrRef) ;
            SetBkMode(ncd.hdc, 1) ;
            DrawText(ncd.hdc, this.mText.toDWString, -1, &ncd.rc, this.mTxtFlag ) ;
            return CDRF_NOTIFYPOSTPAINT ;
        }

        // Drawing a button with special back color at pre paint stage.
        final LRESULT setBtnBackColor(NMCUSTOMDRAW * ncd) {
            switch (ncd.dwDrawStage) {
                case CDDS_PREERASE :
                    return CDRF_NOTIFYPOSTERASE ;
                    break ;
                case CDDS_PREPAINT :               
                    if ((ncd.uItemState & mMouseClickFlag) == mMouseClickFlag) { 
                        //User clicked on it. We can shrink the size a little bit ;                       
                        drawBackColor(ncd.hdc, &ncd.rc, this.rgbBkg.clrRef, -1) ;                                                                  
                    }
                    
                    if ((ncd.uItemState & mMouseOverFlag) == mMouseOverFlag) { 
                        // Button's mouse over state. Let's change the bk clr a bit.                       
                        auto crc = this.rgbBkg.changeColor(1.2);
                        drawBackColor(ncd.hdc, &ncd.rc, crc.clrRef, -1) ;
                        auto crc1 = this.rgbBkg.changeColor(0.5) ;
                        drawBtnFrame(ncd.hdc, &ncd.rc, crc1.clrRef, 1) ;                                          
                    } else {       
                        // Button's default state.                            
                        drawBackColor(ncd.hdc, &ncd.rc, this.rgbBkg.clrRef, -1) ;
                        auto crc = this.rgbBkg.changeColor(0.5) ;
                        drawBtnFrame(ncd.hdc, &ncd.rc, crc.clrRef, 1) ;
                    }
                    return CDRF_DODEFAULT ;
                    break ;
                default : break ;
            } 
            return CDRF_DODEFAULT ;
        }

         
        // Drawing a button's background with gradient brush at the pre paint stage.
        final LRESULT setBtnGradientInternl(NMCUSTOMDRAW * ncd) {
            switch (ncd.dwDrawStage) {
                case CDDS_PREERASE :
                    return CDRF_NOTIFYPOSTERASE ;
                    break ;
                case CDDS_PREPAINT :                    
                    if ((ncd.uItemState & mMouseClickFlag) == mMouseClickFlag) { 
                        //User clicked on it. We can shrink the size a little bit ;                       
                        auto crc = this.gradData.clr1.changeColor(0.5) ;                        
                        paintWithGradientBrush(ncd.hdc, &ncd.rc, -1, this.gradData) ;
                        drawBtnFrame(ncd.hdc, &ncd.rc, crc.clrRef, 1, 0);                        
                                                                                           
                    } else if ((ncd.uItemState & mMouseOverFlag) == mMouseOverFlag) { 
                        // Button's mouse over state. Let's change the bk clr a bit.                       
                        auto cgd = this.gradData.changeColors(1.25) ;
                        auto frcrc = cgd.clr2.changeColor(0.5) ;                        
                        paintWithGradientBrush(ncd.hdc, &ncd.rc, -1, cgd ) ; 
                        drawBtnFrame(ncd.hdc, &ncd.rc, frcrc.clrRef, 1 );
                                                                
                    } else {       
                        // Button's default state.        
                        auto crc = this.gradData.clr1.changeColor(0.5) ;                        
                        paintWithGradientBrush(ncd.hdc, &ncd.rc, -1, this.gradData) ;   
                        drawBtnFrame(ncd.hdc, &ncd.rc, crc.clrRef, 1 );                          
                    }
                    return CDRF_DODEFAULT ;
                    break ;                   
                    
                default : break ;
            } 
            return CDRF_DODEFAULT ;
        }
   
    
    //---------------------------------------------------------------------------------
    private :          
        RgbColor rgbBkg ;
        RgbColor rgbFrg ;
        Gradient gradData ;
        
        // This function fills the baclground of a button with given color.
        void drawBackColor(HDC dc, RECT* rct, COLORREF clr, int rcSize = -2) {
            auto hbr = CreateSolidBrush(clr) ;
            scope(exit) DeleteObject(hbr) ;            
            if (rcSize != 0) InflateRect(rct, rcSize, rcSize) ;            
            SelectObject(dc, hbr) ;            
            FillRect(dc, rct, hbr) ;
        }

        // This function draws a frame around the button with given color & width.
        void drawBtnFrame(HDC dc, RECT* rct, COLORREF clr, int penWidth, int rcSize = 1) {                       
            if (rcSize != 0) InflateRect(rct, rcSize, rcSize) ;                      
            auto framePen = CreatePen(PS_SOLID, penWidth, clr) ;
            scope(exit) DeleteObject(framePen) ;
            SelectObject(dc, framePen) ;
            Rectangle(dc, rct.left, rct.top, rct.right, rct.bottom) ;
        }
        
        // This function fills the button's bakground with a gradient color pattern.
        void paintWithGradientBrush(HDC dc, RECT* rct, int rcSize, Gradient gd ) {           
            if (rcSize != 0) InflateRect(rct, rcSize, rcSize);           
            auto gradBrush = createGradientBrush(dc, rct, gd) ;
            scope(exit) DeleteObject(gradBrush) ;
            SelectObject(dc, gradBrush) ;
            FillRect(dc, rct, gradBrush) ;            
        }




        
    //-----------------------------------------------------------------------
    
    
}// End Button Class---------------------------------------------------------

//Button getButton(DWORD_PTR refData) {return cast(Button)cast(void*)refData;}


extern(Windows)
private LRESULT btnWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, 
                                                UINT_PTR scID, DWORD_PTR refData)  
{
    try  
    {   
        Button btn = getControl!Button(refData) ; 
        switch (message) {
            case WM_DESTROY :
                btn.remSubClass(scID);
                break ;

            case WM_PAINT :
                if (btn.onPaint) {
                    PAINTSTRUCT  ps ;
                    HDC hdc = BeginPaint(hWnd, &ps) ;
                    auto pea = new PaintEventArgs(&ps) ;
                    btn.onPaint(btn, pea) ;
                    EndPaint(hWnd, &ps) ;
                    return 0 ;
                }  break ;

            case WM_SETFOCUS :
                if (btn.onGotFocus) {
                    auto ea = new EventArgs() ;
                    btn.onGotFocus(btn, ea) ;
                    return 0 ;
                } break ;
                //return 1 ;

            case WM_KILLFOCUS :
                if (btn.onLostFocus) {
                    auto ea = new EventArgs() ;
                    btn.onLostFocus(btn, ea) ;
                    return 0 ;
                } break ;

            case WM_LBUTTONDOWN : { 
                btn.lDownHappened = true ;  
               if (btn.onMouseDown) {
                   auto mea = new MouseEventArgs(message, wParam, lParam);
                   btn.onMouseDown(btn, mea) ;
                   return 0 ;
               }
                break ;
            }

            case WM_LBUTTONUP :
                if (btn.onMouseUp) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    btn.onMouseUp(btn, mea) ;                    
                }
                if (btn.lDownHappened) {
                    btn.lDownHappened = false ;
                    sendMsg(btn.handle, CM_LEFTCLICK, 0, 0) ;                    
                } break ;

            case CM_LEFTCLICK :
                if (btn.onMouseClick) {
                    auto ea = new EventArgs() ;
                    btn.onMouseClick(btn, ea) ;
                } break ;


            case WM_RBUTTONDOWN :
                btn.rDownHappened = true ;
                if (btn.onRightMouseDown) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    btn.onRightMouseDown(btn, mea) ; 
                    return 0 ;
                } break ;

            case WM_RBUTTONUP :
                if (btn.onRightMouseUp) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    btn.onRightMouseUp(btn, mea) ;                     
                } 
                if (btn.rDownHappened) {
                    btn.rDownHappened = false ;
                    sendMsg(btn.handle, CM_RIGHTCLICK, 0, 0) ;                    
                } break ;

            case CM_RIGHTCLICK :
                if (btn.onRightClick) {
                    auto ea = new EventArgs() ;
                    btn.onRightClick(btn, ea) ;
                } break ;

            case WM_MOUSEWHEEL :
                if (btn.onMouseWheel) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    btn.onMouseWheel(btn, mea) ; 
                } break ;

            case WM_MOUSEMOVE :
                if (btn.isMouseEntered) {
                    if (btn.onMouseMove) {
                        auto mea = new MouseEventArgs(message, wParam, lParam) ;
                        btn.onMouseMove(btn, mea) ;
                    }
                } else {
                    btn.isMouseEntered = true ;
                    if (btn.onMouseEnter) {
                        auto ea = new EventArgs() ;
                        btn.onMouseEnter(btn, ea) ;
                    }
                } break ;

            case WM_MOUSELEAVE :
                btn.isMouseEntered = false ;
                if (btn.onMouseLeave) {
                    auto ea = new EventArgs() ;
                    btn.onMouseLeave(btn, ea) ;
                } break ;

            case CM_NOTIFY :               
                if (btn.mDrawMode != BtnDrawMode.normal) {
                    auto nmp = cast(NMCUSTOMDRAW*) lParam ;
                    switch (btn.mDrawMode) {
                        case BtnDrawMode.textOnly:                        
                            return btn.setBtnForeColor(nmp) ;
                            break ;
                        case BtnDrawMode.bkgOnly :
                            return btn.setBtnBackColor(nmp) ; 
                            break ;                          
                        case BtnDrawMode.textBkg :
                            btn.setBtnBackColor(nmp) ;
                            btn.setBtnForeColor(nmp) ;
                            return CDRF_NOTIFYPOSTPAINT ;
                            break ;
                        case BtnDrawMode.gradient :
                            return btn.setBtnGradientInternl(nmp) ;
                            break ;
                        case BtnDrawMode.gradientText :
                            btn.setBtnGradientInternl(nmp) ;
                            btn.setBtnForeColor(nmp) ;
                            return CDRF_NOTIFYPOSTPAINT ;
                            break ;
                        default : break ;       
                    }
                } break ;

            default : return DefSubclassProc(hWnd, message, wParam, lParam) ;
        }
        
    }
    catch (Exception e) {} 

    
    return DefSubclassProc(hWnd, message, wParam, lParam);
}



