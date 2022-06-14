
// Created on 02-May-2022 15:02:41
module wings.combobox ; 

private import core.sys.windows.windows ;
private import core.sys.windows.commctrl ;
private import std.string ;
private import std.utf;
private import std.conv ;
private import std.algorithm.mutation  ; // We have a function called 'remove'. So this must be renamed.

//----------------------------------------------------
private import wings.commons ; 
private import wings.controls : Control;
private import wings.window : Window; 
private import wings.enums : ControlType ;
private import wings.events;
private import wings.fonts;
private import wings.enums ;
private import wings.colors ;

struct ComboInfo {
	HWND lbHwnd ;
	HWND tbHwnd ;
	HWND cmbHwnd ;     
	bool noTbMsg ;
    int comboId ; 
    int tbSubClsId ;
    RECT rcEdit ;

    this(COMBOBOXINFO c, HWND hw, int cId, int subId) {
        this.lbHwnd = c.hwndList;
        this.tbHwnd = c.hwndItem;
        this.cmbHwnd = hw;
        this.noTbMsg = false;
        this.comboId = cId;
        this.tbSubClsId = subId;
        this.rcEdit = c.rcItem;
    }

    void changeData(ref ComboInfo c) {
        this.lbHwnd = c.lbHwnd ;
        this.tbHwnd = c.tbHwnd ;
        this.cmbHwnd = c.cmbHwnd ;
        this.noTbMsg = c.noTbMsg ;        

    } 
}




private int cmbNumber = 1 ;
private int editSubClsID = 4000;
/**
 * ComboBox : Control 
 */
class ComboBox : Control {

    /// Returns the items collection of ComboBox
	final string[] items() {return this.mItems ;}

	
    /// Get the selected index of ComboBox.
	final int selectedIndex() {
        if (this.mIsCreated) this.mSelIndex = cast(int) this.sendMsg(CB_GETCURSEL, 0, 0) ;
        return this.mSelIndex;
    }

    /// Set the selected index of ComboBox.
	final void selectedIndex(int value) {
        this.mSelIndex = value ;
        if (this.mIsCreated) {
            this.sendMsg(CB_SETCURSEL, value, 0) ;
        }
	}

    /// Get the selected item from ComboBox.
    final string selectedItem() {
        string result ;
        if (this.mIsCreated) {
            this.mSelIndex = cast(int) this.sendMsg(CB_GETCURSEL, 0, 0) ;
            result = this.mItems[this.mSelIndex];
        }
        return result ;
    }

    /// Set the drop down style of ComboBox. 
    final void dropDownStyle(DropDownStyle value) {        
        /* There is no other way to change the dropdown style of an existing combo box.
         * We need to delete the old combo and create a new one. 
         * Then make it look like the old combo. So this function will do that */
        if (this.mIsCreated) {
            if (value == DropDownStyle.labelCombo) {
                if (this.mCmbStyle == DropDownStyle.labelCombo) return ;
                this.mStyle = WS_CHILD | WS_VISIBLE | CBS_DROPDOWNLIST ;
            } else {
                if (this.mCmbStyle == DropDownStyle.textCombo) return ;            
                this.mStyle = WS_CHILD | WS_VISIBLE | CBS_DROPDOWN ;
            }
            this.mCmbStyle = value ;
            this.mRecreateEnabled = true ;
            DestroyWindow(this.mHandle) ;
            this.create() ;
        } else this.mCmbStyle = value ; // We just need to set the value.        
    }

    /// Get the drop down style of ComboBox.
    final DropDownStyle dropDownStyle() {return this.mCmbStyle ;}

    /// Add an item into ComboBox's items collection.
    void addItem(T)(T value) {
        string item = value.toString;       
        this.mItems ~= item ;
        if (this.mIsCreated) this.sendMsg(CB_ADDSTRING, 0, item.toUTF16z) ; 
    }

    /// Add an array to ComboBox's items collection.
    void addRange(T)( T[] newItems) {
        string[] tempItems;
        static if (is(T == string)) {
            this.mItems ~= newItems ;
            tempItems ~= newItems;
        } else {
            foreach (value; newItems) {
                auto sitem = value.to!string ;
                this.mItems ~= sitem;
                tempItems ~= sitem;
            }        
        }
        if (this.mIsCreated) {
            foreach (item ; tempItems) this.sendMsg(CB_ADDSTRING, 0, item.toUTF16z) ;             
        }
    }

    void addRange(T...)( T newItems) {
        string[] tempItems;
        foreach (value; newItems) {
            static if (is(typeof(value) == string)) {
                this.mItems ~= value ;
                tempItems ~= value;
            } else {
                auto sitem = value.to!string ;
                this.mItems ~= sitem;
                tempItems ~= sitem;
            }        
        }
        if (this.mIsCreated) {
            foreach (item ; tempItems) this.sendMsg(CB_ADDSTRING, 0, item.toUTF16z) ;             
        }
    }

    /// Remove the given item from ComboBox's items collection.
    void removeItem(T)(T item) {
        string cmbItem = item.toString ;           
        if (this.mItems.length > 0) {
            this.mItems = this.mItems.remove!(a => a == cmbItem) ;
            if (this.mIsCreated) { // Remove item from combo also.
                auto iIndex = cast(int) this.sendMsg(CB_FINDSTRING, -1, cmbItem.toUTF16z) ;
                if (iIndex > -1) this.sendMsg(CB_DELETESTRING, iIndex, 0) ;
            }
        }
    }

    /// Remove an item at given index from ComboBox's items collection.
    final void removeItem(int index) { 
        if (this.mItems.length > 0) {
            this.mItems = this.mItems.remove(index) ; 
            if (this.mIsCreated) this.sendMsg(CB_DELETESTRING, index, 0) ;            
        }
    }

    /// Delete all items from ComboBox's items collection.
    final void clearItems() { 
        if (this.mItems.length > 0) {
            this.mItems.length = 0 ; 
            if (this.mIsCreated) this.sendMsg(CB_DELETESTRING, 0, 0) ;
        }
    }

    /// Get the count of items in ComboBox.
    final int itemCount() {return this.mItems.length ;}


	this(Window parent, int x, int y, int w, int h) {              
        mWidth = w ;
        mHeight = h ;
        mXpos = x ;
        mYpos = y ;
        mParent = parent ;
        mFont = parent.font ;
        
        mControlType = ControlType.comboBox ;   
        
        mStyle = WS_CHILD | WS_VISIBLE | CBS_DROPDOWN ;
        mExStyle = WS_EX_CLIENTEDGE ;        
        mBackColor = defBackColor ;
        mForeColor = defForeColor ;
        mSelIndex = -1 ;
        mBClrRef = getClrRef(defBackColor) ;
        mFClrRef = getClrRef(defForeColor) ;  
        mClsName = toUTF16z("ComboBox") ;
        ++cmbNumber;        
    }

    this(Window parent) { this(parent, 20, 20, 150, 30) ; }    
    this (Window parent, int x, int y) { this(parent, x, y, 150, 30) ; }

    EventHandler onSelectionChanged ;
    EventHandler onSelectionCommitted ;
    EventHandler onSelectionCancelled ;
    EventHandler onTextChanged, onTextUpdated ;
    EventHandler onListOpened, onListClosed ;
    MouseEventHandler onTextMouseDown, onTextMouseUp ; //, onTextMouseEnter, onTextMouseLeave ;
    MouseEventHandler onTextRightDown, onTextRightUp ;
    KeyEventHandler onTextKeyDown, onTextKeyUp ;
    EventHandler onTextMouseClick, onTextRightClick ;


    /// Create the handle of ComboBox control.
    final void create() {    	
        if (!this.mRecreateEnabled) this.ctlId = Control.stCtlId;
        this.mHandle = CreateWindowEx(  this.mExStyle, 
                                        mClsName, 
                                        this.mText.toUTF16z, 
                                        this.mStyle, 
                                        this.mXpos, 
                                        this.mYpos,
                                        this.mWidth,
                                        this.mHeight, 
                                        this.mParent.handle, 
                                        cast(HMENU) this.ctlId, 
                                        appData.hInstance, 
                                        null);
        if (this.mHandle) {
            this.mIsCreated = true;
            this.mOldHwnd = this.mHandle ;
            this.setSubClass(&cmbWndProc) ;
            if (!this.mBaseFontChanged) this.mFont = this.mParent.font ;
            this.setFontInternal() ;
        	this.getComboInfo() ;        	
            insertItems() ;
            if (this.mSelIndex > -1) this.sendMsg(CB_SETCURSEL, this.mSelIndex, 0) ;                   
            if (!this.mRecreateEnabled) ++Control.stCtlId; 
            this.mRecreateEnabled = false ;             
        }        
    }

    package :
        bool tbMLDownHappened, tbMRDownHappened ;

        // Do the house keeping.
    	final void finalize() {
    		DeleteObject(this.mBkBrush);
            // We need to remove the subclassing of the edit control.
            RemoveWindowSubclass(this.myInfo.tbHwnd, &cmbEditWndProc, this.myInfo.tbSubClsId);             
    	}

        // Check if the mouse pointer is upon combo's rect.
        final int isInComboRect(HWND hw) {
            RECT rc ;
            GetWindowRect(hw, &rc);
            auto pts = getMousePoints() ;    
            return PtInRect(&rc, pts) ;
        }

	

	private :
		DropDownStyle mCmbStyle ;
		string[] mItems ;
		int mVisItemCount ;
		int mSelIndex = -1;
        int ctlId ;
		bool mRecreateEnabled ;
		HBRUSH mBkBrush ;
		HWND mOldHwnd ;
        ComboInfo myInfo ;
         

        // Get and save the internal info of a ComboBox.
		void getComboInfo() {
			COMBOBOXINFO cmbInfo ;
			cmbInfo.cbSize = cmbInfo.sizeof ;
			this.sendMsg(CB_GETCOMBOBOXINFO, 0, &cmbInfo) ;
			bool bFlag = (this.mCmbStyle == DropDownStyle.labelCombo) ? true : false ;
			ComboInfo ci = ComboInfo(cmbInfo, this.mHandle, this.ctlId, editSubClsID) ;			
            this.mParent.saveComboInfo(ci);
            this.myInfo = ci ; // We need this to subclass the edit control.
            ++editSubClsID ;
            SetWindowSubclass(  this.myInfo.tbHwnd, 
                                &cmbEditWndProc, 
                                UINT_PTR(this.myInfo.tbSubClsId), 
                                this.toDwPtr);            
		}

        // Internal function to insert items to ComboBox.
        void insertItems() {
            if (this.mItems.length > 0 ) {
                foreach (item ; this.mItems) {
                    SendMessage(this.mHandle, CB_ADDSTRING, 0, cast(LPARAM) item.toUTF16z) ;
                }
            }
        }      

        //void pCinfo(const ref ComboInfo c) {
        //    import std.stdio : writefln ;
        //    writefln("List handle - %s", c.lbHwnd) ;
        //    writefln("Edit handle - %s", c.tbHwnd) ;
        //    writefln("Combo handle - %s", this.mHandle) ;
        //    writefln("End------------------------") ;
        //}

        

} // End class ComboBox...........................................





    


extern(Windows)
private LRESULT cmbWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData)  {
    try {   
        ComboBox cmb = getControl!ComboBox(refData) ; 
        //print("ComboBox Messages", message) ;
        switch (message) {
            case WM_DESTROY :
                cmb.finalize ;
                cmb.remSubClass(scID);
                break ;

            case WM_PAINT :
                if (cmb.onPaint) {
                    PAINTSTRUCT  ps ;
                    HDC hdc = BeginPaint(hWnd, &ps) ;
                    auto pea = new PaintEventArgs(&ps) ;
                    cmb.onPaint(cmb, pea) ;
                    EndPaint(hWnd, &ps) ;
                    return 0 ;
                } break ;

            /+case WM_COMMAND :
                /* Combo box will receive only two notifications via WM_COMMAND directly.
                (1) EN_UPDATE, (2) EN_CHANGE. Other notifications are received by parent window.
                So we will get them through CM_CTLCOMMAND message. But these two will arrive first.
                So we can use them as key down & key up messges.
                NOTE : These messages are only received when the drop down style = textCombo.
                */
                auto nCode = HIWORD(wParam) ;                
                switch (nCode) {
                    case EN_UPDATE :
                        if (cmb.onTextKeyDown) {
                            auto ea = new EventArgs();
                            cmb.onTextKeyDown(cmb, ea) ;
                        }
                        break ;
                    case EN_CHANGE :
                        if (cmb.onTextKeyUp) {
                            auto ea = new EventArgs();
                            cmb.onTextKeyUp(cmb, ea) ;
                        }
                        break ;
                    default : break ; 
                }
                break ; +/

            case CM_COMBOLBCOLOR, CM_COMBOTBCOLOR : 
                // We can change the colors of List box area & text area of combo.
                // NOTE : You can change colors OF both text & list only when DropDownStyle = textCombo.
                // NOTE : In labelCombo mode, if you change the color, it won't be affect in text area.
                // Only change the color if user wants to be.                
                if (cmb.mBackColor != defBackColor || cmb.mForeColor != defForeColor) {
                    auto hdc = cast(HDC) wParam ;
                    SetBkMode(hdc, TRANSPARENT) ;
                    if (cmb.mForeColor != defForeColor) SetTextColor(hdc, cmb.mFClrRef) ;
                    cmb.mBkBrush = CreateSolidBrush(cmb.mBClrRef);                    
                    return cast(LRESULT) cmb.mBkBrush ;
                } else {
                    // Otherwise return the default color(white) brush.
                    // If you don't do this, you can see black background inthe listbox.
                    cmb.mBkBrush = CreateSolidBrush(cmb.mBClrRef);
                    return cast(LRESULT) cmb.mBkBrush ;
                }
                break ;     

            case CM_CTLCOMMAND :
                auto nCode = HIWORD(wParam) ;
                switch (nCode) {
                    case CBN_SELCHANGE :
                        if (cmb.onSelectionChanged) {
                            auto ea = new EventArgs();
                            cmb.onSelectionChanged(cmb, ea) ;
                        } break ;

                    case CBN_SETFOCUS :
                        if (cmb.onGotFocus) {
                            auto ea = new EventArgs();
                            cmb.onGotFocus(cmb, ea) ;
                        } break ;
                    case CBN_KILLFOCUS :
                        if (cmb.onLostFocus) {
                            auto ea = new EventArgs();
                            cmb.onLostFocus(cmb, ea) ;
                        } break ;
                    case CBN_EDITCHANGE :
                        
                        if (cmb.onTextChanged) {
                            auto ea = new EventArgs();
                            cmb.onTextChanged(cmb, ea) ;
                        } break ;
                    case CBN_EDITUPDATE :
                        
                        if (cmb.onTextUpdated) {
                            auto ea = new EventArgs();
                            cmb.onTextUpdated(cmb, ea) ;
                        } break ;
                    case CBN_DROPDOWN :                        
                        if (cmb.onListOpened) {
                            auto ea = new EventArgs();
                            cmb.onListOpened(cmb, ea) ;
                        } break ;
                    case CBN_CLOSEUP :                        
                        if (cmb.onListClosed) {
                            auto ea = new EventArgs();
                            cmb.onListClosed(cmb, ea) ;
                        } break ;
                    case CBN_SELENDOK :
                        if (cmb.onSelectionCommitted) {
                            auto ea = new EventArgs();
                            cmb.onSelectionCommitted(cmb, ea) ;
                        } break ;
                    case CBN_SELENDCANCEL :
                        if (cmb.onSelectionCancelled) {
                            auto ea = new EventArgs();
                            cmb.onSelectionCancelled(cmb, ea) ;
                        } break ;
                    default : break ;
                }
                break ;
           
            /*case WM_PARENTNOTIFY :
                auto wpLoWrd = LOWORD(wParam);
                switch (wpLoWrd) {
                    case 512 :  // WM_MOUSEFIRST              
                        if (cmb.onTextMouseEnter) {
                            auto ea = new EventArgs();
                            cmb.onTextMouseEnter(cmb, ea);
                        }
                        break;
                    case 513 : // WM_LBUTTONDOWN
                        if (cmb.onTextClick) {
                            auto ea = new EventArgs();
                            cmb.onTextClick(cmb, ea);
                        }
                        break;
                    case 675 : // WM_MOUSELEAVE
                        if (cmb.onTextMouseLeave) {
                            auto ea = new EventArgs();
                            cmb.onTextMouseLeave(cmb, ea);
                        }
                        break;
                    default : break ;
                }
                break ; */

            case WM_LBUTTONDOWN : 
                //print("in main wnd proc", 1) ;
                cmb.lDownHappened = true ;  
                if (cmb.onMouseDown) {
                   auto mea = new MouseEventArgs(message, wParam, lParam);
                   cmb.onMouseDown(cmb, mea) ;
                   return 0 ;
                }
                break ;
            

            case WM_LBUTTONUP :
                if (cmb.onMouseUp) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    cmb.onMouseUp(cmb, mea) ;                    
                }
                if (cmb.lDownHappened) {
                    cmb.lDownHappened = false ;
                    sendMsg(cmb.handle, CM_LEFTCLICK, 0, 0) ;                    
                } break ;

            case CM_LEFTCLICK :
                if (cmb.onMouseClick) {
                    auto ea = new EventArgs() ;
                    cmb.onMouseClick(cmb, ea) ;
                } break ;


            case WM_RBUTTONDOWN :
                cmb.rDownHappened = true ;
                if (cmb.onRightMouseDown) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    cmb.onRightMouseDown(cmb, mea) ; 
                    return 0 ;
                } break ;

            case WM_RBUTTONUP :
                if (cmb.onRightMouseUp) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    cmb.onRightMouseUp(cmb, mea) ;                     
                } 
                if (cmb.rDownHappened) {
                    cmb.rDownHappened = false ;
                    sendMsg(cmb.handle, CM_RIGHTCLICK, 0, 0) ;                    
                } break ;

            case CM_RIGHTCLICK :
                if (cmb.onRightClick) {
                    auto ea = new EventArgs() ;
                    cmb.onRightClick(cmb, ea) ;
                } break ;

            case WM_MOUSEWHEEL :
                if (cmb.onMouseWheel) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    cmb.onMouseWheel(cmb, mea) ; 
                } break ;

            case WM_MOUSEMOVE :
                if (cmb.isMouseEntered) {
                    if (cmb.onMouseMove) {
                        auto mea = new MouseEventArgs(message, wParam, lParam) ;
                        cmb.onMouseMove(cmb, mea) ;
                    }
                } else {
                    cmb.isMouseEntered = true ;
                    //print("entered in main wnd proc", 2) ; 
                    if (cmb.onMouseEnter) {
                        auto ea = new EventArgs() ;
                        cmb.onMouseEnter(cmb, ea) ;
                    }
                } break ;

            case WM_MOUSELEAVE : 
                if (cmb.dropDownStyle == DropDownStyle.textCombo) {
                    if (cmb.isInComboRect(hWnd) == 0) {
                        cmb.isMouseEntered = false ;                        
                        if (cmb.onMouseLeave) {
                            auto ea = new EventArgs() ;
                            cmb.onMouseLeave(cmb, ea) ;
                        } 
                    }
                } else {
                    cmb.isMouseEntered = false ;
                    if (cmb.onMouseLeave) {
                        auto ea = new EventArgs() ;
                        cmb.onMouseLeave(cmb, ea) ;
                    } 
                }           
                break ;

            

            case WM_KEYDOWN : 
                // To get this message here, cmb's drop down style must be labelCombo.                
                if (cmb.onKeyDown) {
                    auto kea = new KeyEventArgs(wParam);
                    cmb.onKeyDown(cmb, kea) ;
                } break ;

            case WM_KEYUP : 
                // To get this message here, cmb's drop down style must be labelCombo.
                if (cmb.onKeyUp) {
                    auto kea = new KeyEventArgs(wParam);
                    cmb.onKeyUp(cmb, kea) ;
                } break ;

            default : return DefSubclassProc(hWnd, message, wParam, lParam) ;
        }

        
    }
    catch (Exception e) {}     
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

/*
    We are using second Wndproc function to handle the text box operations...
    of a combo box in textCombo drop down style. Because otherwise, we cannot implement...
    a key down or key up message in this style. The one and only caveat of this...
    approach is, we need to take extra care in the mouse enter & mouse leave messages.
    In textCombo mode, we need to check the mouse pointer is inside the combo's rect.
*/
extern(Windows)
private LRESULT cmbEditWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData)  { // @suppress(dscanner.style.long_line)
    try {   
        ComboBox cmb = getControl!ComboBox(refData) ; 
        //print("ComboBox Messages", message) ;
        switch (message) {

            case WM_KEYDOWN:
                if (cmb.onTextKeyDown) {
                    auto kea = new KeyEventArgs(wParam) ;
                    cmb.onTextKeyDown(cmb, kea) ;
                } 
                break ;
            case WM_KEYUP :
                if (cmb.onTextKeyUp) {
                    auto kea = new KeyEventArgs(wParam) ;
                    cmb.onTextKeyUp(cmb, kea) ;
                } 
                break ;

            case WM_LBUTTONDOWN : 
                if (cmb.dropDownStyle == DropDownStyle.textCombo) {
                    cmb.tbMLDownHappened = true ;  
                    if (cmb.onTextMouseDown) {
                       auto mea = new MouseEventArgs(message, wParam, lParam);
                       cmb.onTextMouseDown(cmb, mea) ;
                       return 0 ;
                    }
                } break ;

            case WM_LBUTTONUP : 
                if (cmb.dropDownStyle == DropDownStyle.textCombo) {                    
                    if (cmb.onTextMouseUp) {
                       auto mea = new MouseEventArgs(message, wParam, lParam);
                       cmb.onTextMouseUp(cmb, mea) ;                    
                    }
                } 
                if (cmb.tbMLDownHappened) {
                    cmb.tbMLDownHappened = false ;
                    sendMsg(cmb.handle, CM_LEFTCLICK, 0, 0) ;                    
                } break ;

            case CM_LEFTCLICK :
                if (cmb.onTextMouseClick) {
                    auto ea = new EventArgs() ;
                    cmb.onMouseClick(cmb, ea) ;
                } break ;

            case WM_RBUTTONDOWN : 
                if (cmb.dropDownStyle == DropDownStyle.textCombo) {
                    cmb.tbMRDownHappened = true ;  
                    if (cmb.onTextRightDown) {
                       auto mea = new MouseEventArgs(message, wParam, lParam);
                       cmb.onTextRightDown(cmb, mea) ;
                       return 0 ;
                    }
                } break ;

            case WM_RBUTTONUP : 
                if (cmb.dropDownStyle == DropDownStyle.textCombo) {                    
                    if (cmb.onTextRightUp) {
                       auto mea = new MouseEventArgs(message, wParam, lParam);
                       cmb.onTextRightUp(cmb, mea) ;                    
                    }
                } 
                if (cmb.tbMRDownHappened) {
                    cmb.tbMRDownHappened = false ;
                    sendMsg(cmb.handle, CM_RIGHTCLICK, 0, 0) ;                    
                } break ;

            case CM_RIGHTCLICK :
                if (cmb.onTextRightClick) {
                    auto ea = new EventArgs() ;
                    cmb.onTextRightClick(cmb, ea) ;
                } break ;

            default : return DefSubclassProc(hWnd, message, wParam, lParam) ;
        }
        

        
    }
    catch (Exception e) {}     
    return DefSubclassProc(hWnd, message, wParam, lParam);
}
