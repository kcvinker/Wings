module wings.contextmenu; // Created on 30-July-2022 06:52 PM

private int cmNumber = 1;

class ContextMenu : Control {

    this (Window parent, int x, int y, int w, int h) 
    {        
        mixin(repeatingCode);         
        mControlType = ControlType.contextMenu ;                      
        mBackColor = parent.backColor ;
        mBClrRef = getClrRef(mBackColor) ;
        mFClrRef = getClrRef(mForeColor) ;        
        ++cmNumber;        
    } 
    


    private:
        HMENU mHmenu;
        MenuStyle mStyle;
        MenuPosition mPos;
        HWND mOwner;
        bool mNoNotify;
        bool mRetID;
        bool mUseRbutton;



} // End of ContextMenu class

enum MenuStyle {
    leftToRight = 0x400, rightToLeft = 0x800, topToBottom = 0x1000, bottomToTop = 0x2000, none = 0x4000 
}

enum MenuPosition {leftAlign, topAlign = 0, centerAlign = 4, rightAlign = 8, vCenterAlign = 10, bottomAlign = 20}