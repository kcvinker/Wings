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



/// A base class for all controls
class Control {    

    /// Set the text of control
        final void text(string value) {this.mText = value ;}       

        /// Returns the control text
        final string text() {return this.mText ;} 

        /// Set the width of the control
        final void width(int value) {this.mWidth = value ;}

        /// Return the width of control
        final int width() {return this.mWidth ;} 

        /// Set the height of control
        final void height(int value) {this.mHeight = value ; }

        /// Returns the height of control
        final int height() {return this.mHeight ;} 

        /// Set the X position of control
        final void xPos(int value) {this.mXpos = value ;}

        /// Return the x position of control
        final int xPos() {return this.mXpos ; } 

        /// Set the y position of control
        final void yPos(int value) {this.mYpos = value ;}

        /// Returns the y position of control
        final int yPos() {return this.mYpos ;} 

        /// Returns the window handle
        final HWND handle() {return this.mHandle ;} 

        /// Set the name of the control
        final void name(string value) {this.mName = value ;}

        /// Return the name of control
        final string name() {return this.mName ; }    
    
        /// Returns the type of a control
        final ControlType controlType() {return this.mControlType;}

        /// Set the control type of a control
        final void controlType(ControlType value) {this.mControlType = value;}

        /// Returns the font object
        Font font() {return this.mFont;}        

        /// Set the font for a control
        void font(Font value) {
            this.mBaseFontChanged = true;
            this.mFont = value;
            if (this.mIsCreated) this.setFontInternal();
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

        /// Returns true if control is created
        final bool isHandleCreated() {return this.mIsCreated;}

        /// Returns the parent object(Window) of this control.
        final Window parent() {return this.mParent ;}

        final int rightX() {return this.mXpos + this.mWidth + 10 ;}
        final int downY() {return this.mYpos + this.mHeight + 10;}
        final int controlID() {return this.mCtlId;}

        void backColor(uint value) {
            this.mBackColor = value;
            this.mBClrRef = getClrRef(value);
            this.reDraw();
        }

        uint backColor() {return this.mBackColor;}

        void foreColor(uint value) {
            this.mForeColor = value ;
            this.mFClrRef = getClrRef(value) ;
            this.reDraw();
        }
        uint foreColor() {return this.mForeColor;}

        


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
		DWORD mStyle ;
        DWORD mExStyle ;
        Wstring mClsName ;
        string mText ;
        int mWidth ;
        int mHeight ;
        int mXpos ;
        int mYpos ;
        static int stCtlId = 100 ;
        Window mParent ;
        bool mIsCreated;
        bool mBaseFontChanged ;
        Font mFont;
        
        HWND mHandle ;            
        string mName ;         
        ControlType mControlType;
        static int mSubClassId = 1000 ;       
        int mCtlId ;

        

        // A simple helper function for convert a control to DWORD_PTR
        final DWORD_PTR toDwPtr() {return cast(DWORD_PTR) (cast(void*) this);} // Protected

        // Helper function to invalidate & redraw a control.
        final void reDraw() {if (this.mIsCreated) InvalidateRect(this.mHandle, null, true);} // Protected
        
        
            
        
    package :
        bool lDownHappened ;
        bool rDownHappened ;
        bool isMouseEntered ;
        COLORREF mBClrRef ;
        COLORREF mFClrRef ;
        uint mBackColor ;
        uint mForeColor ;
        SUBCLASSPROC wndProcPtr;

        final void createHandle() {  // protected
            // This function works for almost all controls except combo box. 
            // This will save us 150+ lines of code. 
            this.mCtlId = Control.stCtlId ;
            this.mHandle = CreateWindowEx(  this.mExStyle, 
                                    this.mClsName, 
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
                if (!this.mBaseFontChanged) this.mFont = this.mParent.font ;
                this.setFontInternal() ;                               
            }      
        }

        final void setFontInternal() {   // Package
            // This function is used for setting font for a control right after it created
            if (!this.mFont.isCreated) this.mFont.createFontHandle(this.mHandle) ;           
            this.sendMsg(WM_SETFONT, this.mFont.handle, 1) ;                            
        }        

        final void setSubClass(SUBCLASSPROC ctlWndProc) {    // Protected   
            /*  We need to implement a special WndProc function for each control.
            In order to do that, we need to subclass a control. Here, subclassing means...
            just replacing the parent's own WndProc with our function. */            
            SetWindowSubclass(this.mHandle, ctlWndProc, UINT_PTR(mSubClassId), this.toDwPtr);
            this.wndProcPtr = ctlWndProc;           
            ++mSubClassId ;             
        }         

        final void remSubClass(UINT_PTR subClsId) { // Package
            // We must remove the subclass when a control destroyed
            RemoveWindowSubclass(this.mHandle, this.wndProcPtr, subClsId); 
            //writeln("Removed subclass of - ", this.mControlType) ;
        }

        final auto sendMsg(wpt, lpt)(uint uMsg, wpt wp, lpt lp) { // Package
            // A helper function for sending messages to controls & window.
            return SendMessage(this.mHandle, uMsg, cast(WPARAM) wp, cast(LPARAM) lp);
        }

        final string getControlText(HWND hw) {            
            auto txtLen = GetWindowTextLengthW(hw) + 1;            
            wchar[] buffer = new wchar[](txtLen);
            GetWindowTextW(hw, buffer.ptr, txtLen );
            return buffer.to!string;
        }

    private :
        int widthOffset = 20; // Might be useless
        int heightOffset = 3;

       

            


} // End Control Class