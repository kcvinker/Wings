module wings.buttons;
//---------------------------------------------------

import wings.d_essentials;
import wings.wings_essentials;
import std.datetime.stopwatch;
import std.stdio;


//------------------------------------------------------

//private DWORD btnStyle = WS_CHILD | BS_NOTIFY | WS_TABSTOP | WS_VISIBLE ;
private DWORD btnExStyle = 0;
private Button[] buttonList;
private static int btnNumber = 1;
private int subClsID = 1001;
private const int mMouseClickFlag = 0b1 ;
private const int mMouseOverFlag = 0b1000000 ;
private const int roundCurve = 5;
//---------------------------------------------------------


/// Button class.
class Button : Control {
    import wings.gradient ;

// Properties

    /// Set the forecolor of the button.
    final override void foreColor(uint value) {
        this.mForeColor(value) ;
        // this.rgbFrg = RgbColor(value) ;
        // switch (this.mDrawMode) {
        //     case BtnDrawMode.normal :
        //         this.mDrawMode = BtnDrawMode.textOnly ; break ;
        //     case BtnDrawMode.bkgOnly :
        //         this.mDrawMode = BtnDrawMode.textBkg ; break ;
        //     case BtnDrawMode.gradient :
        //         this.mDrawMode = BtnDrawMode.gradientText ; break ;
        //     default : break ;
        // }
        if ((this.mDrawFlag & 1) != 1) this.mDrawFlag += 1;
        this.checkRedrawNeeded();
    }

    /// Get the forecolor of the button.
    final override uint foreColor() const {return this.mForeColor.value ;}

    final override void backColor(uint value) {
        this.mBackColor(value) ;
        this.mFDraw.setData(this.mBackColor);
        if ((this.mDrawFlag & 2) != 2) this.mDrawFlag += 2;
        this.checkRedrawNeeded();
    }

    final override uint backColor() const {return this.mBackColor.value ;}

    final void setGradientColors(uint clr1, uint clr2) {
        this.mGDraw.setData(clr1, clr2);
        if ((this.mDrawFlag & 4) != 4) this.mDrawFlag += 4;
        this.checkRedrawNeeded();
    }

    /// Values between 0..1
    final void focusFactor(float value) {
        if (this.mFDraw.isActive) {
            COLORREF crf = this.mBackColor.mouseFocusColor(value);
            this.mFDraw.hotBrush = CreateSolidBrush(crf);
            this.checkRedrawNeeded();
        }
    }

    final void frameFactor(float value) {
        if (this.mFDraw.isActive) {
            COLORREF crf = this.mBackColor.makeFrameColor(value);
            this.mFDraw.defPen = CreatePen(PS_SOLID, 1, crf);
            this.checkRedrawNeeded();
        }
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
        this(parent, btxt, 20, 20, 120, 35) ;
    }

    this(Window parent, string txt) {
        this(parent, txt, 20, 20, 120, 35) ;
    }

    this(Window parent, string txt, size_t x, size_t y) {
        this(parent, txt, x, y, 120, 35) ;
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
		// NMCUSTOMDRAW nmc;
		// this.log(nmc.sizeof, " NMCUSTOMDRAW.size");
    }


    package :
        BtnDrawMode mDrawMode ;
        DWORD mTxtFlag = DT_SINGLELINE | DT_VCENTER | DT_CENTER | DT_NOPREFIX ;






        // Drawing a button's background with gradient brush at the pre paint stage.



    //---------------------------------------------------------------------------------
    private :
        RgbColor rgbBkg ;
        RgbColor rgbFrg ;
        Gradient mGDraw;
        FlatDraw mFDraw;

         // Drawing a button's text at pre paint stage.
        LRESULT drawTextColor(NMCUSTOMDRAW* ncd) { // Private
            SetTextColor(ncd.hdc, this.mForeColor.cref) ;
            SetBkMode(ncd.hdc, 1) ;
            DrawText(ncd.hdc, this.mText.toUTF16z, -1, &ncd.rc, this.mTxtFlag ) ;
            return CDRF_NOTIFYPOSTPAINT ;
        }

        // Drawing the flat color bkg
        LRESULT drawBackColor(NMCUSTOMDRAW* ncd) {
            switch (ncd.dwDrawStage) {
                case CDDS_PREERASE : // This happens when the paint starts
                    return CDRF_NOTIFYPOSTERASE; break; // Telling the program to inform us after erase
                case CDDS_PREPAINT: // We get the notification after erase happened.
                    switch (ncd.uItemState) { // We check the control state and draw
                        case mMouseClickFlag:
                            this.paintFlatBtnRoundRect(ncd.hdc, ncd.rc, mFDraw.defBrush, mFDraw.hotPen);
                        break;
                        case mMouseOverFlag:
                            this.paintFlatBtnRoundRect(ncd.hdc, ncd.rc, mFDraw.hotBrush, mFDraw.hotPen);
                        break;
                        default:
                            this.paintFlatBtnRoundRect(ncd.hdc, ncd.rc, mFDraw.defBrush, mFDraw.defPen);
                        break;
                    }
                    return CDRF_NOTIFYPOSTPAINT;
                break ;
                default : break ;
            }
            return CDRF_DODEFAULT ;
        }

        // Drawing the gradient color bkg
        LRESULT drawGradientBackColor(NMCUSTOMDRAW * ncd) {
            switch (ncd.dwDrawStage) {
                case CDDS_PREERASE: // This happens when the paint starts
                    return CDRF_NOTIFYPOSTERASE; // Telling the program to inform us after erase
                break ;
                case CDDS_PREPAINT: // We get the notification after erase happened.
                    switch (ncd.uItemState) { // We check the control state and draw
                        case mMouseClickFlag:
                            this.paintRoundGradient(ncd.hdc, ncd.rc, this.mGDraw.gcDef, this.mGDraw.hotPen);
                        break;
                        case mMouseOverFlag:
                            this.paintRoundGradient(ncd.hdc, ncd.rc, this.mGDraw.gcHot, this.mGDraw.hotPen);
                        break;
                        default:
                            // print("def pen when used ", this.mGDraw.defPen);
                            this.paintRoundGradient(ncd.hdc, ncd.rc, this.mGDraw.gcDef, this.mGDraw.defPen);
                        break;
                    }
                    return CDRF_NOTIFYPOSTPAINT;
                    break ;
                default : break ;
            }
            return CDRF_DODEFAULT ;
        }

        // Helper function for drawing flat color bkg
        void paintFlatBtnRoundRect(HDC dc, RECT rc, HBRUSH hbr, HPEN pen ) {
            SelectObject(dc, pen);
            SelectObject(dc, hbr);
            RoundRect(dc, rc.left, rc.top, rc.right, rc.bottom, roundCurve, roundCurve);
            FillPath(dc);
        }

        // This function draws a frame around the button with given color & width.
        // void drawFrame(HDC hdc, RECT* rc, HPEN pen, int rcSize) {
        //     if (rcSize != 0) InflateRect(rc, rcSize, rcSize) ;
        //     SelectObject(hdc, pen) ;
        //     Rectangle(hdc, rc.left, rc.top, rc.right, rc.bottom);
        // }

        // void roundFrame(HDC dc, RECT* rc, HPEN fp) {
        //     SelectObject(dc, fp);
        //     RoundRect(dc, rc.left, rc.top, rc.right, rc.bottom, 5, 5);
        // }

        // This function fills the button's bakground with a gradient color pattern.
        // void paintWithGradientBrush(HDC dc, RECT* rct, GradColor gdc, HBRUSH fbr ) {
        //     // if (rcSize != 0) InflateRect(rct, rcSize, rcSize);
        //     auto gradBrush = createGradientBrush(dc, rct, gdc.c1, gdc.c2) ;
        //     scope(exit) DeleteObject(gradBrush) ;
        //     SelectObject(dc, gradBrush) ;
        //     FillRect(dc, rct, gradBrush);
        //     FrameRect(dc, rct, fbr);
        //     // FillPath(dc);
        // }

        void paintRoundGradient(HDC dc, RECT rc, GradColor gc, HPEN pen) {
            auto gradBrush = createGradientBrush(dc, rc, gc.c1, gc.c2) ;
            scope(exit) DeleteObject(gradBrush) ;

            SelectObject(dc, pen);
            SelectObject(dc, gradBrush);
            RoundRect(dc, rc.left, rc.top, rc.right, rc.bottom, roundCurve, roundCurve);
            FillPath(dc);
        }

        LRESULT wmNotifyHandler(LPARAM lpm) {
            LRESULT ret = CDRF_DODEFAULT;
            if (this.mDrawFlag) {
                NMCUSTOMDRAW* nmcd = cast(NMCUSTOMDRAW*)lpm;
                switch (this.mDrawFlag) {
                        case 1: ret = this.drawTextColor(nmcd); break; // ForeColor only
                        case 2: ret = this.drawBackColor(nmcd); break; // BackColor only
                        case 3://-----------------------------------------Back & Fore colors
                            this.drawBackColor(nmcd);
                            ret = this.drawTextColor(nmcd);
                        break;
                        case 4: ret = this.drawGradientBackColor(nmcd); break; // Gradient only
                        case 5: //------------------------------------------------Gradient & fore colors
                            this.drawGradientBackColor(nmcd);
                            ret = this.drawTextColor(nmcd);
                        break;
                    default: return CDRF_DODEFAULT; break;
                }


            }
            return ret;
        }

        void finalize(UINT_PTR scID) {
            // this.remSubClass(scID);
            RemoveWindowSubclass(this.mHandle, &btnWndProc, scID);
        }







    //-----------------------------------------------------------------------


}// End Button Class---------------------------------------------------------

struct FlatDraw {
    HBRUSH defBrush;
	HBRUSH hotBrush;
    HBRUSH dFrmBrush;
    HBRUSH hFrmBrush;
	HPEN defPen;
	HPEN hotPen;
    bool isActive;

    ~this() {
        if (this.defBrush) DeleteObject(this.defBrush);
	    if (this.hotBrush) DeleteObject(this.hotBrush);
	    if (this.defPen) DeleteObject(this.defPen);
	    if (this.hotPen) DeleteObject(this.hotPen);
	    if (this.dFrmBrush) DeleteObject(this.dFrmBrush);
	    if (this.hFrmBrush) DeleteObject(this.hFrmBrush);
        print("FlatDraw resources freed");
    }

    void setData(Color c) {
        import std.stdio;
        auto hotRc = RgbColor(c.value);
        auto frmRc = RgbColor(c.value);
        double hadj = hotRc.isDark() ? 1.5 : 1.2;
        hotRc.changeShade(hadj);
        print("hadj ", hadj);
        this.defBrush = CreateSolidBrush(c.cref);
        this.hotBrush = CreateSolidBrush(hotRc.cref);
        this.defPen = CreatePen(PS_SOLID, 1, frmRc.makeFrameColor(0.6));
        this.hotPen = CreatePen(PS_SOLID, 1, frmRc.makeFrameColor(0.3));
        // this.dFrmBrush = CreateSolidBrush(c.makeFrameColor(0.3));
        // this.hFrmBrush = CreateSolidBrush(c.makeFrameColor(0.6));

        this.isActive = true;
    }
}


extern(Windows)
private LRESULT btnWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                                UINT_PTR scID, DWORD_PTR refData)
{
    try {

        Button btn = getControl!Button(refData) ;
        //btn.log(message, "Button message ");
        switch (message) {
            case WM_DESTROY : btn.finalize(scID); break ;
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
            case CM_NOTIFY : return btn.wmNotifyHandler(lParam); break ;

            default : return DefSubclassProc(hWnd, message, wParam, lParam) ;
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}


