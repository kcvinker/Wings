module winglib.controls;

private import core.runtime;
private import core.sys.windows.windows;
private import std.stdio;
private import std.utf;
private import core.sys.windows.commctrl ;


private import winglib.fonts;
private import winglib.events;



/// A base class for all controls
class Control {
    
    import winglib.window : Window;
    import winglib.enums : ControlType ;   
    

    /// Set the text of control
    @property void text(string value) {this.mText = value ;}

    /// Returns the control text
    @property string text() {return this.mText ;} 

    /// Set the width of the control
    @property void width(int value) {this.mWidth = value ;}

    /// Return the width of control
    @property int width() {return this.mWidth ;} 

    /// Set the height of control
    @property void height(int value) {this.mHeight = value ; }

    /// Returns the height of control
    @property int height() {return this.mHeight ;} 

    /// Set the X position of control
    @property void xPos(int value) {this.mXpos = value ;}

    /// Return the x position of control
    @property int xPos() {return this.mXpos ; } 

    /// Set the y position of control
    @property void yPos(int value) {this.mYpos = value ;}

    /// Returns the y position of control
    @property int yPos() {return this.mYpos ;} 

   /// Returns the window handle
    @property HWND handle() {return this.mHandle ;} 


    /// Set the name of the control
    @property void name(string value) {this.mName = value ;}

    /// Return the name of control
    @property string name() {return this.mName ; } 

    ///
    //@property void parent(Window value) {this.mParent = value ;}

    ///
    //@property Window parent() {return this.mParent ;}

    @property ControlType controlType() {return this.mControlType;}

    @property Font font() {return this.mFont;}

    

    @property bool isHandleCreated() {return this.mIsCreated;}
    //-------------------------------------------------------------------

    ///EventHandler onLeftDown ;
    EventHandler onMouseEnter ; 
    MouseEventHandler onMouseWheel ; 
    MouseEventHandler onMouseHover ; 
    MouseEventHandler onMouseMove ; 
    EventHandler onMouseClick ; 
    EventHandler onMouseLeave ; 
    MouseEventHandler onMouseDown ; 
    MouseEventHandler onMouseUp ; 
    MouseEventHandler onRMouseDown ; 
    MouseEventHandler onRMouseUp ; 
    KeyEventHandler onKeyDown ; 
    KeyEventHandler onKeyUp ; 
    EventHandler onKeyPress ; 
    EventHandler onPaint   ; 
    EventHandler wndProc ;

    void hide() { ShowWindow(this.mHandle, SW_HIDE);}
    void setFont(string fName, int fSize, bool fBold = false, bool fItal = false, bool fUnder = false )
    {
        this.mFont = new Font(fName, fSize, fBold, fItal, fUnder) ;
        this.mBaseFontChanged = true ;
        if (this.mIsCreated)
        {
            this.mFont.createFontHandle(this.mHandle) ;
            this.sendMsg(WM_SETFONT, this.mFont.fontHandle, 1) ;
        }
        
    }
	
    //void show(){ShowWindow(this.mHandle, SW_SHOW);}
	
    
    
     
    

    protected :
            string mText ;
            int mWidth ;
            int mHeight ;
            int mXpos ;
            int mYpos ;
			uint mBackColor ;
			uint mForeColor ;
            DWORD mStyle ;
            DWORD mExStyle ;
            HWND mHandle ;            
            string mName ;            
            Font mFont;
            bool mIsCreated;
            ControlType mControlType;
            static int mSubClassId = 1000 ;
            Window mParent ;
            bool mBaseFontChanged ;

            


            DWORD_PTR toDwPtr() {return cast(DWORD_PTR) ((cast(void*) this));}

            void setFont()
            {   
                this.mFont.createFontHandle(this.mHandle) ;
                this.sendMsg(WM_SETFONT, this.mFont.fontHandle, 1) ;                
            }

            void sendMsg(wpt, lpt)(uint uMsg, wpt wp, lpt lp) {
                SendMessage(this.mHandle, uMsg, cast(WPARAM) wp, cast(LPARAM) lp);
            }

            void setSubClass(SUBCLASSPROC ctlWndProc) {                   
                SetWindowSubclass(this.mHandle, ctlWndProc, UINT_PTR(mSubClassId), this.toDwPtr);
                ++mSubClassId ;             
            }

            


}