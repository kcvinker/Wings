
// GroupBox class -  Created on: 24-May-22 10:59:01 AM
/*==============================================GroupBox Docs=====================================
    Constructor:
        this(Form parent, string txt)
        this(Form parent, string txt, int x, int y)
        this(Form parent, string txt, int x, int y, int w, int h)

	Properties:
		GroupBox inheriting all Control class properties	
        getYpos : int
			
    Methods:
        createHandle
        
    Events:
        All public events inherited from Control class. (See controls.d)       
=============================================================================================*/

module wings.groupbox;

import wings.d_essentials;
import wings.wings_essentials;
import wings.graphics;



enum DWORD gb_style = WS_CHILD | WS_VISIBLE | BS_GROUPBOX | BS_NOTIFY | BS_TOP |
                WS_OVERLAPPED| WS_CLIPCHILDREN| WS_CLIPSIBLINGS;
enum DWORD gb_exstyle = WS_EX_RIGHTSCROLLBAR| WS_EX_CONTROLPARENT;
enum UINT PEN_WIDTH = 4;
enum WCHAR[1] EWSA = [0];
enum WCHAR* EMP_WSTR_PTR = EWSA.ptr; 

class GroupBox: Control
{
    this(Form parent, string txt, int x, int y, int w, int h, GroupBoxStyle style = GroupBoxStyle.system)
    {
        mixin(repeatingCode);
        ++gbNumber;
        mControlType = ControlType.groupBox;
        this.mFont = new Font(parent.font);
        mText = txt;
        mStyle = gb_style; 
        mExStyle = gb_exstyle; 
        mBackColor = parent.mBackColor;
        mWtext = new WideString(txt);
        this.mDBFill = true;
        this.mGetWidth = true;
        this.mGBStyle = GroupBoxStyle.system;
        this.mName = format("%s_%d", "GroupBox_", gbNumber);
        this.mParent.mControls ~= this;
        this.mHasFont = true;
        this.mCtlId = Control.stCtlId;
        ++Control.stCtlId;        
        if (parent.mAutoCreate) this.createHandle();
    }

    this(Form parent, string txt, int x, int y)
    {
        this(parent, txt, x, y, 150, 150);
    }

    this(Form parent, string txt)
    {
        this(parent, txt, 20, 20, 150, 150);
    }

    override void createHandle()
    {
        import wings.buttons: btnClassName;        
        this.mBkBrush = CreateSolidBrush(this.mBackColor.cref);
        if (this.mGBStyle == GroupBoxStyle.overriden) {
            this.mPen = CreatePen(PS_SOLID, PEN_WIDTH, this.mBackColor.cref );
        }
        SetRect(&this.mRect, 0, 0, this.mWidth, this.mHeight);
        this.createHandleInternal(btnClassName.ptr);
        if (this.mHandle) {
            if (this.mGBStyle == GroupBoxStyle.classic) {
				SetWindowTheme(this.mHandle, EMP_WSTR_PTR, EMP_WSTR_PTR);
            	this.mThemeOff = true;
			}
            this.setSubClass(&gbWndProc);
            this.setFontInternal();
        }
    }

    final override void backColor(uint value)
    {
        this.mBackColor(value);
        this.resetGDIObjects(true);        
        this.checkRedrawNeeded();
    }

    /* To change Group box's fore color, we need either classic or overriden style.
        Here in this property we choose classic if current style is system.*/
    final override void foreColor(uint value) {
        this.mForeColor(value);
		if (this.mGBStyle == GroupBoxStyle.system) this,mGBStyle = GroupBoxStyle.classic;
		if (this.mGBStyle == GroupBoxStyle.classic) {
			if (!this.mThemeOff) {
				SetWindowTheme(this.mHandle, EMP_WSTR_PTR, EMP_WSTR_PTR);
            	this.mThemeOff = true;
			}			
		}
		if (this.mGBStyle == GroupBoxStyle.overriden) {
			this.mGetWidth = true;
			if (!this.mPen) this.mPen = CreatePen(PS_SOLID, PEN_WIDTH, this.mBackColor.cref);
		}
		this.checkRedrawNeeded();
    }

    override final void text(string value)
    {
        this.mText = value;
        this.mWtext.updateBuffer(value);
        this.mGetWidth = true;
        if (this.mIsCreated) SetWindowTextW(this.mHandle, this.mWtext.ptr);
        this.checkRedrawNeeded();
    }

    override final void width(int value)
    {
        this.mWidth = value;
        this.resetGDIObjects(false);  
        if (this.mIsCreated) this.ctlSetPos();
    }

    override final void height(int value)
    {
        this.mHeight = value;
        this.resetGDIObjects(false);  
        if (this.mIsCreated) this.ctlSetPos();
    }

    override final void font(Font value)
    {
        this.mFont = value;
        this.mGetWidth = true; 
        this.checkRedrawNeeded();
    }

    void changeFont(string fname, int fsize, FontWeight fweight = FontWeight.normal) 
    {
        auto fnt = new Font(fname, fsize, fweight);
        this.mFont = new Font(fnt);
        this.mGetWidth = true; 
        this.checkRedrawNeeded();
    }



    int getYpos()
    {
        if (this.mIsCreated) {
            return this.mRect.top + 10;
        } else {
            RECT rct = RECT(this.mXpos, this.mYpos, (this.mXpos + this.mWidth), (this.mYpos + this.mHeight));
            MapWindowPoints(this.parent.mHandle, this.mParent.mHandle, cast(LPPOINT)&rct, 2 );
            return rct.top + 10;
        }
    }

    private:
        HPEN mPen;
        HDC mMemDc;
        HBITMAP mBmp;
        RECT mRect;
        bool isPaintBkg;
        bool mDBFill;
        bool mGetWidth;
        bool mThemeOff;
        int mTxtWidth;
        static int gbNumber;
        GroupBoxStyle mGBStyle;
        Control[] mControls;


        void resetGDIObjects(bool brpn) {
            if (brpn) {
                if (this.mBkBrush) DeleteObject(this.mBkBrush);
                this.mBkBrush = CreateSolidBrush(this.mBackColor.cref);
                if (this.mGBStyle == GroupBoxStyle.overriden) {
                    if (this.mPen) DeleteObject(this.mPen);                
                    this.mPen = CreatePen(PS_SOLID, PEN_WIDTH, this.mBackColor.cref );
                }
            }
            if (this.mMemDc) DeleteDC(this.mMemDc);
            if (this.mBmp) DeleteObject(this.mBmp);
            this.mDBFill = true;
        }

        /*void drawTextDblBuff() {
            RECT rc;
            SIZE ss;
            int yp = 11;
            HDC hdc = GetDC(this.mHandle);
            SelectObject(hdc, this.mFont.handle);
            GetTextExtentPoint32(hdc, this.mTmpText.toUTF16z, this.mTmpText.length, &ss );
            ss.cx += 10;
            // ss.cy += 10;
            HDC dcMem = CreateCompatibleDC(hdc);
            int ndcMem = SaveDC(dcMem);
            HBITMAP hbm = CreateCompatibleBitmap(hdc, ss.cx, ss.cy);
            scope(exit) {
                RestoreDC(dcMem, ndcMem);
                DeleteObject(hbm);
                DeleteDC(dcMem);
                ReleaseDC(this.mHandle, hdc);
            }
            SelectObject(dcMem, hbm);
            BitBlt(dcMem, 0, 0, ss.cx, ss.cy, hdc, 10, 0, SRCCOPY);

            SelectObject(dcMem, this.mPen);
            MoveToEx(dcMem, 10, yp, null);
            LineTo(dcMem, ss.cx, yp);
            SetRect(&rc, 10, 0, ss.cx, ss.cy);
            SetBkMode(dcMem, TRANSPARENT);
            SelectObject(dcMem, this.mFont.handle);
            SetTextColor(dcMem, this.mForeColor.cref);
            DrawTextW(dcMem, this.mTmpText.toUTF16z, -1, &rc, DT_CENTER|DT_SINGLELINE );
            // TextOutW(dcMem, 10, 0, this.mTmpText.toUTF16z, this.mTmpText.length);
            BitBlt(hdc, 10, 0, ss.cx, ss.cy, dcMem, 0, 0, SRCCOPY);
        } */

        void finalize()
        { 
            // This is our destructor. Clean all the dirty stuff
            DeleteObject(this.mBkBrush);
            DeleteObject(this.mPen);
            DeleteObject(this.mBmp);
            DeleteDC(this.mMemDc);            
        }


} // End of GroupBox class

extern(Windows)
private LRESULT gbWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                                UINT_PTR scID, DWORD_PTR refData)
{
    try {
        switch (message) {
            
            case WM_DESTROY: 
                RemoveWindowSubclass(hWnd, &gbWndProc, scID);
                GroupBox gb = getControl!GroupBox(refData);
                gb.finalize(); 
            break;
            case WM_SETFOCUS: 
                GroupBox gb = getControl!GroupBox(refData);
                gb.setFocusHandler(); 
            break;
            case WM_KILLFOCUS: 
                GroupBox gb = getControl!GroupBox(refData);
                gb.killFocusHandler(); 
            break;
            case WM_LBUTTONDOWN: 
                GroupBox gb = getControl!GroupBox(refData);
                gb.mouseDownHandler(message, wParam, lParam); 
            break;
            case WM_LBUTTONUP: 
                GroupBox gb = getControl!GroupBox(refData);
                gb.mouseUpHandler(message, wParam, lParam); 
            break;
            case WM_RBUTTONDOWN: 
                GroupBox gb = getControl!GroupBox(refData);
                gb.mouseRDownHandler(message, wParam, lParam); 
            break;
            case WM_RBUTTONUP: 
                GroupBox gb = getControl!GroupBox(refData);
                gb.mouseRUpHandler(message, wParam, lParam); 
            break;
            case WM_MOUSEWHEEL: 
                GroupBox gb = getControl!GroupBox(refData);
                gb.mouseWheelHandler(message, wParam, lParam); 
            break;
            case WM_MOUSEMOVE: 
                GroupBox gb = getControl!GroupBox(refData);
                gb.mouseMoveHandler(message, wParam, lParam); 
            break;
            case WM_MOUSELEAVE: 
                GroupBox gb = getControl!GroupBox(refData);
                gb.mouseLeaveHandler(); 
            break;
            case WM_GETTEXTLENGTH: 
                GroupBox gb = getControl!GroupBox(refData);
                if (gb.mGBStyle == GroupBoxStyle.overriden) return 0;
            break;
            case CM_COLOR_STATIC:
                GroupBox gb = getControl!GroupBox(refData);
                if (gb.mGBStyle == GroupBoxStyle.classic) {
                    HDC hdc = cast(HDC)wParam;
                    SetBkMode(hdc, TRANSPARENT);
                    SetTextColor(hdc, gb.mForeColor.cref);    
                }
        	    return cast(LRESULT)gb.mBkBrush;
            break;
            case WM_ERASEBKGND:
                GroupBox gb = getControl!GroupBox(refData);
                auto hdc = cast(HDC)wParam;
                if (gb.mGetWidth) {
                    SIZE sz;
                    SelectObject(hdc, gb.mFont.mHandle);
                    GetTextExtentPoint32(hdc, gb.mWtext.constPtr, gb.mWtext.inputLen, &sz);
                    gb.mTxtWidth = sz.cx + 10;
                    gb.mGetWidth = false;                    
                }
                if (gb.mDBFill) {
                    gb.mMemDc = CreateCompatibleDC(hdc);
                    gb.mBmp = CreateCompatibleBitmap(hdc, gb.mWidth, gb.mHeight);
                    SelectObject(gb.mMemDc, gb.mBmp);
                    FillRect(gb.mMemDc, &gb.mRect, gb.mBkBrush);
                    gb.mDBFill = false;
                }
                BitBlt(hdc, 0, 0, gb.mWidth, gb.mHeight, gb.mMemDc, 0, 0, SRCCOPY);
                return 1;
                
            break;
            case WM_PAINT:
                GroupBox gb = getControl!GroupBox(refData);
                if (gb.mGBStyle == GroupBoxStyle.overriden) {
                    auto ret = DefSubclassProc(hWnd, message, wParam, lParam);
                    auto gfx = new Graphics(hWnd);
                    gfx.drawHLine(gb.mPen, 10, 9, gb.mTxtWidth);
                    gfx.drawText(gb, 12, 0);
                    return ret;
                }
            break;
            case CM_FONT_CHANGED:
                GroupBox gb = getControl!GroupBox(refData);
                gb.updateFontHandle();
                return 0;
            break;
            default: 
                return DefSubclassProc(hWnd, message, wParam, lParam); 
            break;
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

