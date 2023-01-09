module wings.buttons;
//---------------------------------------------------

import wings.d_essentials;
import wings.wings_essentials;
import std.datetime.stopwatch;

//------------------------------------------------------

//private DWORD btnStyle = WS_CHILD | BS_NOTIFY | WS_TABSTOP | WS_VISIBLE ;
private DWORD btnExStyle = 0;
private Button[] buttonList;
private static int btnNumber = 1;
private int subClsID = 1001;
private const int mMouseClickFlag = 0b1 ;
private const int mMouseOverFlag = 0b1000000 ;

//---------------------------------------------------------


/// Button class.
class Button : Control {
    import wings.gradient ;

// Properties

    /// Set the forecolor of the button.
    final override void foreColor(uint value) {
        this.mForeColor(value) ;
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
        this.checkRedrawNeeded();
    }

    /// Get the forecolor of the button.
    final override uint foreColor() const {return this.mForeColor.value ;}

    final override void backColor(uint value) {
        this.mBackColor(value) ;
        this.rgbBkg = RgbColor(value) ;
        switch (this.mDrawMode) {
            case BtnDrawMode.normal :
                this.mDrawMode = BtnDrawMode.bkgOnly ; break ;
            case BtnDrawMode.textOnly :
                this.mDrawMode = BtnDrawMode.textBkg ; break ;
            default : break ;
        }
        this.checkRedrawNeeded();
    }

    final override uint backColor() const {return this.mBackColor.value ;}

    final void setGradientColors(uint clr1, uint clr2, GradientStyle gStyle = GradientStyle.topToBottom) {
        this.gradData = Gradient(clr1, clr2, gStyle) ;
        switch (this.mDrawMode) {
            case BtnDrawMode.textOnly, BtnDrawMode.textBkg :
                this.mDrawMode = BtnDrawMode.gradientText ; break ;
            default :
                this.mDrawMode = BtnDrawMode.gradient ; break ;
        }
        //writeln("btn draw mode - ", this.mDrawMode) ;
        this.checkRedrawNeeded();
    }

// End of Properties

    void testObj() {
        LOGFONTW lf;
        auto value = 0x640A1A04;
        void* vp = cast(void*) value;
        auto res = GetObject(vp, LOGFONTW.sizeof, &lf );
        print("result ", res);
        print("lfFaceName - ", lf.lfFaceName);
    }




// Ctors
    this(Window parent, string txt, int x, int y, int w, int h) {

        mClsName = "Button" ;
        this.mName = format("%s_%d", "Button", btnNumber);
        mixin(repeatingCode);
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

    this(Window parent, string txt, size_t x, size_t y) {
        this(parent, txt, x, y, 100, 35) ;
    }

    this(Window parent, size_t x, size_t y, size_t w, size_t h) {
        string btxt = format("%s_%d", "Button", btnNumber);
        this(parent, btxt, x, y, w, h) ;
    }
// End of Ctors


    //------------------------------------------------------------------------
    final void create() {
        //auto sw = StopWatch(AutoStart.no);
        //sw.start();
        this.createHandle() ;
        //sw.stop();
        //print("btn create speed in micro sec : ", sw.peek.total!"usecs");
        if (this.mHandle) {
            this.setSubClass(&btnWndProc) ;
        }
    }


    package :
        BtnDrawMode mDrawMode ;
        DWORD mTxtFlag = DT_SINGLELINE | DT_VCENTER | DT_CENTER | DT_NOPREFIX ;

        // Drawing a button's text at pre paint stage.
        final LRESULT setBtnForeColor(NMCUSTOMDRAW * ncd) {
            SetTextColor(ncd.hdc, this.mForeColor.reff) ;
            SetBkMode(ncd.hdc, 1) ;
            DrawText(ncd.hdc, this.mText.toUTF16z, -1, &ncd.rc, this.mTxtFlag ) ;
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
                        drawBackColor(ncd.hdc, &ncd.rc, this.mBackColor.reff, -1) ;
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
    try {
        Button btn = getControl!Button(refData) ;
        switch (message) {
            case WM_DESTROY : btn.remSubClass(scID); break ;
            case WM_PAINT : btn.paintHandler(); break;
            case WM_SETFOCUS :
                btn.setFocusHandler();
                return 1;
            break;
            case WM_KILLFOCUS :
                btn.killFocusHandler();
                return 1;
            break;
            case WM_LBUTTONDOWN : btn.mouseDownHandler(message, wParam, lParam); break ;
            case WM_LBUTTONUP : btn.mouseUpHandler(message, wParam, lParam); break ;
            case CM_LEFTCLICK : btn.mouseClickHandler(); break;
            case WM_RBUTTONDOWN : btn.mouseRDownHandler(message, wParam, lParam); break;
            case WM_RBUTTONUP : btn.mouseRUpHandler(message, wParam, lParam); break;
            case CM_RIGHTCLICK : btn.mouseRClickHandler(); break;
            case WM_MOUSEWHEEL : btn.mouseWheelHandler(message, wParam, lParam); break;
            case WM_MOUSEMOVE : btn.mouseMoveHandler(message, wParam, lParam); break;
            case WM_MOUSELEAVE : btn.mouseLeaveHandler(); break;
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



