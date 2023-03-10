module wings.textbox; // Created on - 27-July-2022 07:41 AM


import wings.d_essentials;
import wings.wings_essentials;
import std.datetime.stopwatch ;

private int tbNumber = 1 ;
private wchar[] mClassName = ['E', 'd', 'i', 't', 0];

class TextBox : Control {

    this (Window parent, int x, int y, int w, int h)
    {
        mixin(repeatingCode);
        this.mControlType = ControlType.textBox ;
        this.mName = format("%s_%d", "Textbox_", tbNumber);
        //if (txt.length > 0 ) mText = txt ;
        this.mStyle = 0x50010080  ;                               //  WS_CHILD | WS_VISIBLE | ES_LEFT | ES_NOHIDESEL  ;
        this.mExStyle =  0x00000204 ;
        this.mBackColor(0Xffffff); // White
        this.mForeColor(0x000000); // Black
        ++tbNumber;
    }

    this (Window parent, int x, int y) {this(parent, x, y, 120, 25);}
    //this (Window parent, int x, int y, int w, int h) {this(parent, "", x, y, w, h);}

    void create() {
    	this.setTbStyle();
        // printf("textbox style %X", this.mStyle) ;
    	this.createHandle(mClassName.ptr);
    	if (this.mHandle) {

            this.setSubClass(&tbWndProc) ;
            //this.createLogFontInternal();
            if (this.mCue.length > 0) this.sendMsg(EM_SETCUEBANNER, 0x0001, this.mCue.ptr) ;
        }
    }


    private:
        Alignment mTxtPos;
        TextType mTxtType;
        TextCase mTxtCase;
        bool mMultiLine;
        bool mHideSel;
        bool mReadOnly;
        bool mDrawFocus;
        bool mDrawBkClr = true;
        wstring mCue;


        void setTbStyle() { // Private
            if (this.mMultiLine) this.mStyle |= ES_MULTILINE | ES_WANTRETURN;
            if (this.mHideSel) this.mStyle |= ES_NOHIDESEL;
            if (this.mReadOnly) this.mStyle |= ES_READONLY;

            if (this.mTxtCase == TextCase.lowerCase) {this.mStyle |= ES_LOWERCASE;}
            else if (this.mTxtCase == TextCase.upperCase) {this.mStyle |= ES_UPPERCASE;}

            if (this.mTxtType == TextType.numberOnly) {this.mStyle |= ES_NUMBER;}
            else if (this.mTxtType == TextType.passwordChar) {this.mStyle |= ES_PASSWORD;}

            if (this.mTxtPos == Alignment.center) {this.mStyle |= ES_CENTER;}
            else if (this.mTxtPos == Alignment.right) {this.mStyle |= ES_RIGHT;}
            this.mBkBrush = CreateSolidBrush(this.mBackColor.cref);
        }

        void finalize(UINT_PTR subid) {
            RemoveWindowSubclass(this.mHandle, &tbWndProc, subid );
        }


} // End of TextBox class


extern(Windows)
private LRESULT tbWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData)
{
    try
    {
        //sw.start();
        //auto before = MonoTime.currTime();
        TextBox tb = getControl!TextBox(refData)  ;
        //auto tb = tbDict[0];
        //sw.stop();
        //auto timeElap = MonoTime.currTime - before;
        //printf("Textbox retreiving time in nano sec : %s", timeElap);
        switch (message)
        {
            case WM_NCDESTROY : tb.finalize(scID); break;
            case WM_PAINT:
                //if (tb.mDrawFocus) {
                //    PAINTSTRUCT ps;
                //    auto dc = BeginPaint(hWnd, &ps);
                //    auto fBrush = CreateSolidBrush(tb.mFrmCref);
                //    FrameRect(dc, &ps.rcPaint, fBrush);
                //    EndPaint(hWnd, &ps);
                //    return 0;
                //}
            break;

            case WM_SETFOCUS:
                //tb.mDrawFocus = true;

            break;

            case WM_KILLFOCUS:
                //tb.mDrawFocus = false;
            break;

            case CM_COLOR_EDIT:
                if (tb.mDrawFlag) {
                    auto hdc = cast(HDC) wParam;
                    if (tb.mDrawFlag & 1) SetTextColor(hdc, tb.mForeColor.cref);
                    if (tb.mDrawFlag & 2) SetBkColor(hdc, tb.mBackColor.cref);
                }
                return toLresult(tb.mBkBrush);
            break;



            // case CM_CTLCOMMAND :
            // 	if (HIWORD(wParam) == 0) {
            // 		tb.mChecked = cast(bool) tb.sendMsg(BM_GETCHECK, 0, 0);
            // 		if (tb.onStateChanged) {
            // 			auto ea = new EventArgs();
            // 			tb.onStateChanged(tb, ea);
            // 		}
            // 	}
            // 	break;
            //case WM_SETFONT :
            //    print("WM_SETFONT rcvd"); break;

            // case CM_NOTIFY:
            //     auto nmcd = getNmcdPtr(lParam);
            //     switch (nmcd.dwDrawStage) {
            //         case CDDS_PREERASE:
            //             return CDRF_NOTIFYPOSTERASE;
            //             break;
            //         case CDDS_PREPAINT:
            //             RECT rct = nmcd.rc;
            //             if (tb.mRightAlign) { rct.right -= 18;} else {rct.left += 18;}
            //             SetTextColor(nmcd.hdc, tb.mFClrRef);
            //             DrawTextW(nmcd.hdc, tb.text.ptr, -1, &rct, tb.mTxtStyle);
            //             return CDRF_SKIPDEFAULT;
            //             break;
            //         default: break;
            //     }
            //     break;

            case WM_LBUTTONDOWN : tb.mouseDownHandler(message, wParam, lParam); break ;
            case WM_LBUTTONUP : tb.mouseUpHandler(message, wParam, lParam); break ;
            case CM_LEFTCLICK : tb.mouseClickHandler(); break;
            case WM_RBUTTONDOWN : tb.mouseRDownHandler(message, wParam, lParam); break;
            case WM_RBUTTONUP : tb.mouseRUpHandler(message, wParam, lParam); break;
            case CM_RIGHTCLICK : tb.mouseRClickHandler(); break;
            case WM_MOUSEWHEEL : tb.mouseWheelHandler(message, wParam, lParam); break;
            case WM_MOUSEMOVE : tb.mouseMoveHandler(message, wParam, lParam); break;
            case WM_MOUSELEAVE : tb.mouseLeaveHandler(); break;

            default : return DefSubclassProc(hWnd, message, wParam, lParam) ;
        }



    }

    catch (Exception e)
    {
        return DefSubclassProc(hWnd, message, wParam, lParam);
    }
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

