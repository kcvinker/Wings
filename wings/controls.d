module wings.controls;

import core.runtime;
import core.sys.windows.windows;
import std.stdio;
import std.utf;
import core.sys.windows.commctrl ;
import std.conv;




import wings.fonts;
import wings.events;
import wings.enums;
import wings.commons;
import wings.window ;
import wings.colors;

enum repeatingCode = "  mWidth = w ;
                        mHeight = h ;
                        mXpos = x ;
                        mYpos = y ;
                        mParent = parent ;
                        mFont = parent.font;"; /// Setting size, position, and parent font.

mixin template finalProperty(string pName, alias obj) {
    mixin(`final typeof(obj) `, pName, `() { return obj; }`);
    mixin(`final void `, pName, `(typeof(obj) value) { obj = value; }`);
}


/// A base class for all controls
class Control {

    /// Set the text of control
        void text(string value) {
            this.mText = value ;
            if (this.mIsCreated) {
                // TODO
            }
        }

        /// Returns the control text
        string text() {return this.mText ;}

        void visible(bool value) {
            this.mVisible = value;
            if (this.mIsCreated) {
                DWORD flag = value ? SW_SHOW : SW_HIDE;
                ShowWindow(this.mHandle, flag) ;
            }
        }
        bool visible() {return this.mVisible;}

        /// Set & get the width of the control
        mixin finalProperty!("width", this.mWidth);

        /// Set & get the height of control
        mixin finalProperty!("height", this.mHeight);

        /// Set & get the X position of control
        mixin finalProperty!("xPos", this.mXpos);

        /// Set & get the y position of control
        mixin finalProperty!("yPos", this.mYpos);

        /// Returns the window handle
        final HWND handle() {return this.mHandle ;}

        /// Set & get the name of the control
        mixin finalProperty!("name", this.mName);

        // /// Returns the type of a control
        // final ControlType controlType() {return this.mControlType;}

        // /// Set the control type of a control
        // final void controlType(ControlType value) {this.mControlType = value;}
         mixin finalProperty!("controlType", this.mControlType);

        /// Returns the font object
        Font font() {return this.mFont;}

        /// Set the font for a control
        void font(Font value) {
            this.mBaseFontChanged = true;
            this.mFont = value;
            if (this.mIsCreated) this.setFontInternal(); // Setting font if the control is created already.
        }

        /// Set the font of a control.
        void setFont(   string fName, int fSize,
                        FontWeight fWeight = FontWeight.normal,
                        bool fItal = false, bool fUnder = false )
        {
            this.mFont = new Font(fName, fSize, fWeight, fItal, fUnder) ;
            this.mBaseFontChanged = true ;
            if (this.mIsCreated) {
                this.mFont.createFontHandle(this.mHandle) ;
                this.sendMsg(WM_SETFONT, this.mFont.handle, 1) ;
            }
        }

        void printNotifs() {
            enum TRBN_FIRST = -1501U;
            enum TRBN_THUMBPOSCHANGING = TRBN_FIRST-1 ;
            writefln("NM_CUSTOMDRAW %d", TRBN_THUMBPOSCHANGING);
            writefln("CDDS_ITEM %d", CDDS_ITEM);
            writefln("MCN_LAST %d", CDDS_ITEM );
            writefln("DTN_FIRST %d", DTN_FIRST);
            writefln("DTN_DATETIMECHANGE %d", DTN_DATETIMECHANGE);
        }

        /// Returns true if control is created
        final bool isHandleCreated() {return this.mIsCreated;}

        /// Returns the parent object(Window) of this control.
        final Window parent() {return this.mParent ;}

        final int rightX() {return this.mXpos + this.mWidth + 10 ;}
        final int downY() {return this.mYpos + this.mHeight + 10;}
        final int controlID() {return this.mCtlId;}

        void backColor(uint value) {
            this.mBackColor(value);
            if ((this.mDrawFlag & 2) != 2 ) this.mDrawFlag += 2;
            if (this.mIsCreated) this.mBkBrush = CreateSolidBrush(this.mBackColor.cref);
            this.checkRedrawNeeded();
        }

        uint backColor() {return this.mBackColor.value;}

        void foreColor(uint value) {
            this.mForeColor(value) ;
            if ((this.mDrawFlag & 1) != 1) this.mDrawFlag += 1;
            this.checkRedrawNeeded();
        }
        uint foreColor() {return this.mForeColor.value;}




     // end properties
    //-------------------------------------------------------------------

    ///EventHandler onLeftDown ;
    EventHandler onMouseEnter, onMouseClick, onMouseLeave, onRightClick, onDoubleClick ;
    MouseEventHandler onMouseWheel, onMouseHover, onMouseMove, onMouseDown, onMouseUp ;
    MouseEventHandler onRightMouseDown, onRightMouseUp ;
    KeyEventHandler onKeyDown, onKeyUp ;
    PaintEventHandler onPaint ;
    EventHandler onKeyPress, onGotFocus, onLostFocus, wndProc ;

    /// Hide a control.
    void hide() { ShowWindow(this.mHandle, SW_HIDE);}




    protected :
		DWORD mStyle;
        DWORD mExStyle;
        string mText;
        string mName;
        int mWidth;
        int mHeight;
        int mXpos;
        int mYpos;
        int mCtlId;
        bool mIsCreated;
        bool mBaseFontChanged;
        bool mVisible = true;
        Font mFont;
        ControlType mControlType;
        static int mSubClassId = 1000;
        static int stCtlId = 100 ;




        // A simple helper function for convert a control to DWORD_PTR
        final DWORD_PTR toDwPtr() {return cast(DWORD_PTR) (cast(void*) this);} // Protected

        // Helper function to invalidate & redraw a control.
        final void checkRedrawNeeded() {if (this.mIsCreated) InvalidateRect(this.mHandle, null, true);} // Protected




    package:
        bool lDownHappened;
        bool rDownHappened;
        bool isMouseEntered;
        Color mBackColor;
        Color mForeColor;
        uint mDrawFlag;
        // SUBCLASSPROC wndProcPtr;
        HWND mHandle;
        HBRUSH mBkBrush;
        Window mParent ;

        final void createHandle(wchar* clsname) {  // protected
            // This function works for almost all controls except combo box.
            // This will save us 150+ lines of code.
            this.mCtlId = Control.stCtlId ;
            this.mHandle = CreateWindowEx(  this.mExStyle,
                                            clsname,
                                            this.mText.toUTF16z,
                                            this.mStyle,
                                            this.mXpos,
                                            this.mYpos,
                                            this.mWidth,
                                            this.mHeight,
                                            this.mParent.handle,
                                            cast(HMENU) this.mCtlId,
                                            appData.hInstance,
                                            null);
            if (this.mHandle) {
                ++Control.stCtlId; // Increasing protected static member for next control iD
                this.mIsCreated = true;
                if (!this.mBaseFontChanged) this.mFont = this.mParent.font;
                this.createLogFontInternal();
                // writefln("TVI_ROOT %s", TVI_ROOT);
                // writefln("TVI_FIRST %s", TVI_FIRST);
                // writefln("TVI_LAST %s", TVI_LAST);
                // writefln("TVI_SORT %s", TVI_SORT);
            }
        }

        final void setFontInternal() {   // Package
            // This function is used for setting font for a control right after it created
            if (!this.mFont.isCreated) {this.mFont.createFontHandle(this.mHandle) ; }
            this.sendMsg(WM_SETFONT, this.mFont.handle, 1) ;
        }

        final void setSubClass(SUBCLASSPROC ctlWndProc) {    // Protected
            /*  We need to implement a special WndProc function for each control.
            In order to do that, we need to subclass a control. Here, subclassing means...
            just replacing the parent's own WndProc with our function. */
            SetWindowSubclass(this.mHandle, ctlWndProc, UINT_PTR(mSubClassId), this.toDwPtr);
            ++mSubClassId ;
        }

        // final void remSubClass(UINT_PTR subClsId) { // Package
        //     // We must remove the subclass when a control destroyed
        //     auto res = RemoveWindowSubclass(this.mHandle, this.wndProcPtr, subClsId);
        //     writefln("Removing subclass of %s and result - %d ", this.mName, res) ;
        // }

        final auto sendMsg(wpt, lpt)(uint uMsg, wpt wp, lpt lp) { // Package
            // A helper function for sending messages to controls & window.
            return SendMessage(this.mHandle, uMsg, cast(WPARAM) wp, cast(LPARAM) lp);
        }

        final void createLogFontInternal() { // Package
            if (!this.mFont.isCreated) this.mFont.createFontHandle(this.mHandle);
            this.sendMsg(WM_SETFONT, this.mFont.handle, 1) ;
        }

        final string getControlText(HWND hw) {
            auto txtLen = GetWindowTextLengthW(hw) + 1;
            wchar[] buffer = new wchar[](txtLen);
            GetWindowTextW(hw, buffer.ptr, txtLen );
            return buffer.to!string;
        }

        final string getControlTextANSI(HWND hw) {
            auto txtLen = GetWindowTextLengthW(hw) + 1;
            char[] buffer = new char[](txtLen);
            GetWindowTextA(hw, buffer.ptr, txtLen );
            return buffer.to!string;
        }

        final RECT clientRect() {
            RECT rc ;
            GetClientRect(this.mHandle, &rc);
            return rc;
        }
        final RECT clientRect(HWND hw) {
            RECT rc ;
            GetClientRect(hw, &rc);
            return rc;
        }

        final RECT windowRect(HWND hw) {
            RECT rc ;
            GetWindowRect(hw, &rc);
            return rc;
        }

        final log(T)(T obj, string msg = "") {
            writefln("%s log [%d]  %s - %s", this.mName, this.mLogNum, msg, obj);
            ++this.mLogNum;
        }

        final log(T)(string msg = "") {
            writefln("%s log [%d]  %s", this.mName, this.mLogNum);
            ++this.mLogNum;
        }


        // Common WndProc Message Handlers.=================================
            LRESULT paintHandler() {
                if (this.onPaint) {
                    PAINTSTRUCT  ps ;
                    BeginPaint(this.mHandle, &ps) ;
                    auto pea = new PaintEventArgs(&ps) ;
                    this.onPaint(this, pea) ;
                    EndPaint(this.mHandle, &ps) ;
                    return 0 ;
                }
                return 0 ;
            }

            void setFocusHandler() {
                if (this.onGotFocus) this.onGotFocus(this, new EventArgs());
            }

            void killFocusHandler() {
                 if (this.onLostFocus) this.onLostFocus(this, new EventArgs());
            }

            void mouseDownHandler(UINT msg, WPARAM wp, LPARAM lp) {
                this.lDownHappened = true ;
                if (this.onMouseDown) {
                    auto mea = new MouseEventArgs(msg, wp, lp);
                    this.onMouseDown(this, mea);
                }
            }

            void mouseUpHandler(UINT msg, WPARAM wp, LPARAM lp) {
                if (this.onMouseUp) {
                    auto mea = new MouseEventArgs(msg, wp, lp) ;
                    this.onMouseUp(this, mea) ;
                }
                if (this.lDownHappened) {
                    this.lDownHappened = false ;
                    this.sendMsg(CM_LEFTCLICK, 0, 0) ;
                }
            }

            void mouseClickHandler() {
                if (this.onMouseClick) this.onMouseClick(this, new EventArgs());
            }

            void mouseRDownHandler(UINT msg, WPARAM wp, LPARAM lp) {
                this.rDownHappened = true ;
                if (this.onRightMouseDown) {
                    auto mea = new MouseEventArgs(msg, wp, lp) ;
                    this.onRightMouseDown(this, mea) ;
                }
            }

            void mouseRUpHandler(UINT msg, WPARAM wp, LPARAM lp) {
                if (this.onRightMouseUp) {
                    auto mea = new MouseEventArgs(msg, wp, lp) ;
                    this.onRightMouseUp(this, mea) ;
                }
                if (this.rDownHappened) {
                    this.rDownHappened = false ;
                    this.sendMsg(CM_RIGHTCLICK, 0, 0) ;
                }
            }

            void mouseRClickHandler() {
                if (this.onRightClick) this.onRightClick(this, new EventArgs());
            }

            void mouseWheelHandler(UINT msg, WPARAM wp, LPARAM lp) {
                if (this.onMouseWheel) {
                    auto mea = new MouseEventArgs(msg, wp, lp) ;
                    this.onMouseWheel(this, mea) ;
                }
            }

            void mouseMoveHandler(UINT msg, WPARAM wp, LPARAM lp) {
                if (this.isMouseEntered) {
                    if (this.onMouseMove) {
                        auto mea = new MouseEventArgs(msg, wp, lp) ;
                        this.onMouseMove(this, mea) ;
                    }
                } else {
                    this.isMouseEntered = true ;
                    if (this.onMouseEnter) this.onMouseEnter(this, new EventArgs());
                }
            }

            void mouseLeaveHandler() {
                this.isMouseEntered = false ;
                if (this.onMouseLeave) this.onMouseLeave(this, new EventArgs());
            }

            void keyDownHandler(WPARAM wpm) {
                if (this.onKeyDown) this.onKeyDown(this, new KeyEventArgs(wpm));
            }

            void keyUpHandler(WPARAM wpm) {
                if (this.onKeyUp) this.onKeyUp(this, new KeyEventArgs(wpm));
            }

            void keyPressHandler(WPARAM wpm) {
                if (this.onKeyPress) this.onKeyPress(this, new KeyEventArgs(wpm));
            }



        // End of common message handlers.

    private :
        int mLogNum = 1;
        // int widthOffset = 20; // Might be useless
        // int heightOffset = 3;






} // End Control Class