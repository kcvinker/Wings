// Created on - 27-July-2022 07:41 AM
/*==============================================TextBox Docs=====================================
    Constructor:
        this (Form parent, int x, int y)
        this (Form parent, int x, int y, int w, int h)

	Properties:
		TextBox inheriting all Control class properties	
        readOnly    : bool
			
    Methods:
        createHandle        
        
    Events:
        All public events inherited from Control class. (See controls.d)
        EventHandler - void delegate(Control, EventArgs)
            onTextChanged       
=============================================================================================*/

module wings.textbox; 

import wings.d_essentials;
import wings.wings_essentials;
import std.datetime.stopwatch;
import std.stdio;

enum wchar[] tbClsName = ['E', 'd', 'i', 't', 0];
enum DWORD tbStyle = WS_TABSTOP|WS_CLIPCHILDREN|WS_CLIPSIBLINGS|WS_VISIBLE|WS_CHILD| ES_AUTOHSCROLL| ES_LEFT;
enum DWORD tbExStyle = WS_EX_LEFT|WS_EX_LTRREADING|WS_EX_CLIENTEDGE;

class TextBox: Control
{
    EventHandler onTextChanged;
    this (Form parent, int x, int y, int w, int h)
    {
        mixin(repeatingCode);
        ++tbNumber;
        this.mControlType = ControlType.textBox;
        this.mFont = new Font(parent.font);
        this.mName = format("%s_%d", "Textbox_", tbNumber);
        this.mStyle = tbStyle;  
        this.mExStyle = tbExStyle;
        this.mBackColor(0Xffffff); // White
        this.mForeColor(0x000000); // Black
        this.mParent.mControls ~= this;
        this.mCtlId = Control.stCtlId;
        this.mHasFont = true;
        ++Control.stCtlId;
        this.mBkBrush = CreateSolidBrush(this.mBackColor.cref);
        if (parent.mAutoCreate) this.createHandle();
    }

    this (Form parent, int x, int y) {this(parent, x, y, 120, 25); }
    //this (Form parent, int x, int y, int w, int h) {this(parent, "", x, y, w, h);}

    override void createHandle()
    {
    	this.setTbStyle();
        // printf("textbox style %X", this.mStyle);
    	this.createHandleInternal(tbClsName.ptr);
    	if (this.mHandle) {
            this.setSubClass(&tbWndProc);
            this.createLogFontInternal();
            if (this.mCue.length > 0) this.sendMsg(EM_SETCUEBANNER, 0x0001, this.mCue.ptr);
            // if (this.mReadOnly) this.sendMsg(EM_SETREADONLY, 1, 0);
            // Without this line, textbox looks ugly style. It won't receive WM_NCPAINT message.
            // So we just redraw the non client area and it will receive WM_NCPAINT
            RedrawWindow(this.mHandle, null, null, RDW_FRAME| RDW_INVALIDATE);
        }
    }

    mixin finalProperty!("readOnly", this.mReadOnly);

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
        static int tbNumber;


        void setTbStyle() // Private
        {
            if (this.mMultiLine) this.mStyle |= ES_MULTILINE | ES_WANTRETURN;
            if (this.mHideSel) this.mStyle |= ES_NOHIDESEL;
            if (this.mReadOnly) this.mStyle |= ES_READONLY;
            if (this.mDisabled) this.mStyle |= WS_DISABLED;

            if (this.mTxtCase == TextCase.lowerCase) {
                this.mStyle |= ES_LOWERCASE;
            } else if (this.mTxtCase == TextCase.upperCase) {
                this.mStyle |= ES_UPPERCASE;
            }

            if (this.mTxtType == TextType.numberOnly) {
                this.mStyle |= ES_NUMBER;
            } else if (this.mTxtType == TextType.passwordChar) {
                this.mStyle |= ES_PASSWORD;
            }

            if (this.mTxtPos == Alignment.center) {
                this.mStyle |= ES_CENTER;
            } else if (this.mTxtPos == Alignment.right) {
                this.mStyle |= ES_RIGHT;
            }
            this.mBkBrush = CreateSolidBrush(this.mBackColor.cref);
        }

        void finalize(UINT_PTR subid)
        {
            DeleteObject(this.mBkBrush);
            RemoveWindowSubclass(this.mHandle, &tbWndProc, subid );
        }


} // End of TextBox class


extern(Windows)
private LRESULT tbWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                                UINT_PTR scID, DWORD_PTR refData)
{
    try {
        switch (message) {
            case WM_NCDESTROY: 
                TextBox tb = getControl!TextBox(refData);
                tb.finalize(scID); 
            break;
            case CM_COLOR_EDIT:
                TextBox tb = getControl!TextBox(refData);
                if (tb.mDrawFlag) {
                    auto hdc = cast(HDC) wParam;
                    if (tb.mDrawFlag & 1) SetTextColor(hdc, tb.mForeColor.cref);
                    if (tb.mDrawFlag & 2) SetBkColor(hdc, tb.mBackColor.cref);
                }
                return toLresult(tb.mBkBrush);
            break;
            case CM_CTLCOMMAND:
                TextBox tb = getControl!TextBox(refData);
            	if (HIWORD(wParam) == EN_CHANGE) {
            		if (tb.onTextChanged) tb.onTextChanged(tb, new EventArgs());
            	}
            break;
            case WM_LBUTTONDOWN: 
                TextBox tb = getControl!TextBox(refData);
                tb.mouseDownHandler(message, wParam, lParam); 
            break;
            case WM_LBUTTONUP: 
                TextBox tb = getControl!TextBox(refData);
                tb.mouseUpHandler(message, wParam, lParam); 
            break;
            case WM_RBUTTONDOWN: 
                TextBox tb = getControl!TextBox(refData);
                tb.mouseRDownHandler(message, wParam, lParam); 
            break;
            case WM_RBUTTONUP: 
                TextBox tb = getControl!TextBox(refData);
                tb.mouseRUpHandler(message, wParam, lParam); 
            break;
            case WM_MOUSEWHEEL: 
                TextBox tb = getControl!TextBox(refData);
                tb.mouseWheelHandler(message, wParam, lParam); 
            break;
            case WM_MOUSEMOVE: 
                TextBox tb = getControl!TextBox(refData);
                tb.mouseMoveHandler(message, wParam, lParam); 
            break;
            case WM_MOUSELEAVE: 
                TextBox tb = getControl!TextBox(refData);
                tb.mouseLeaveHandler(); 
            break;
            case CM_FONT_CHANGED:
                TextBox tb = getControl!TextBox(refData);
                tb.updateFontHandle();
                return 0;
            break;
            default: return DefSubclassProc(hWnd, message, wParam, lParam);
        }
    }
    catch (Exception e)  { }
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

