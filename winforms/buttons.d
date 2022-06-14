module winglib.buttons;
//---------------------------------------------------
private import core.runtime;
private import core.sys.windows.windows ;
private import core.sys.windows.commctrl ;
private import std.stdio ;
private import std.string ;
private import std.conv;
private import std.utf;
//----------------------------------------------------
private import winglib.commons ; 
private import winglib.controls : Control;
import winglib.window : Window; 
import winglib.enums : ControlType ;
private import winglib.events;
private import winglib.fonts;




//------------------------------------------------------

private DWORD btnStyle = WS_CHILD | BS_NOTIFY | WS_TABSTOP | WS_VISIBLE | BS_DEFPUSHBUTTON;
private DWORD btnExStyle = 0;
private Button[] buttonList;
private int btnNumber = 1;
private int mIdNum = 101;   
private int subClsID = 1001;

//---------------------------------------------------------


  
class Button : Control { 

    this(Window parent) {          
        this.mText = "Button_" ~btnNumber.to!string ;// format("Button%s", btnNumber.to!string());
        mWidth = 100 ;
        mHeight = 40 ;
        mXpos = 30 ;
        mYpos = 30 ;
        mParent = parent ;
        mFont = parent.font ;
        mControlType = ControlType.button ;        
        ++btnNumber;        
    }

   
    // ~this() 
    // { 
    //     RemoveWindowSubclass(this.handle, this.mBtnWindProc, this.mOwnSubClsId); 
    //     writeln("Removed A button"); 
    // }

    //------------------------------------------------------------------------    
    void create() {
        this.mHandle = CreateWindowEx(  btnExStyle, 
                                        WC_BUTTON.toUTF16z, 
                                        this.mText.toUTF16z, 
                                        btnStyle, 
                                        this.mXpos, 
                                        this.mYpos,
                                        this.mWidth,
                                        this.mHeight, 
                                        this.mParent.handle, 
                                        cast(HMENU) mIdNum, 
                                        Window.mHInstance, 
                                        null);
        if (this.mHandle)
        {
            this.mIsCreated = true;
            this.setSubClass(&btnWndProc) ;
            if (!this.mBaseFontChanged) {this.mFont = this.mParent.font ;}
            this.setFont() ;
                        
            //this.setFont();
            //++mIdNum;        
                  
            //this.mParent.controls ~= this;
            //buttonList~= this;
            //return this.mHandle; 
        }
        
    }
    
    EventHandler onClick ;

   
    
    //---------------------------------------------------------------------------------
    private :  
        Button mThisBtn;
        SUBCLASSPROC mBtnWindProc;
        int mOwnSubClsId ;
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
        switch (message)
        {
            case WM_LBUTTONDOWN : {   
               if (btn.onClick) {
                   auto ea = new EventArgs();
                   btn.onClick(btn, ea) ;
               }
                break ;
            }
            

            default : break ;
        }
        
    }
    catch (Exception e) {} 

    
    return DefSubclassProc(hWnd, message, wParam, lParam);
}



