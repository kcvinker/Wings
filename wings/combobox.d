

module wings.combobox ; // Created on 02-May-2022 15:02:41

import wings.d_essentials;
import std.conv ;
import std.utf;

import std.algorithm.mutation  ; // We have a function called 'remove'. So this must be renamed.
import wings.wings_essentials;


//struct ComboInfo {
//	HWND lbHwnd ;
//	HWND tbHwnd ;
//	HWND cmbHwnd ;
//	bool noTbMsg ;
//    int comboId ;
//    int tbSubClsId ;
//    RECT rcEdit ;

//    this(COMBOBOXINFO c, HWND hw, int cId, int subId) {
//        this.lbHwnd = c.hwndList;
//        this.tbHwnd = c.hwndItem;
//        this.cmbHwnd = hw;
//        this.noTbMsg = false;
//        this.comboId = cId;
//        this.tbSubClsId = subId;
//        this.rcEdit = c.rcItem;
//    }

//    void changeData(ref ComboInfo c) {
//        this.lbHwnd = c.lbHwnd ;
//        this.tbHwnd = c.tbHwnd ;
//        this.cmbHwnd = c.cmbHwnd ;
//        this.noTbMsg = c.noTbMsg ;

//    }
//}




private int cmbNumber = 1 ;
private int editSubClsID = 4000;
/**
 * ComboBox : Control
 */
class ComboBox : Control {

    this(Window parent, int x, int y, int w, int h) {
        mixin(repeatingCode);
        mControlType = ControlType.comboBox ;
        mStyle = WS_CHILD | WS_VISIBLE ;
        mExStyle = WS_EX_CLIENTEDGE ;
        mBackColor(defBackColor) ;
        mForeColor(defForeColor) ;
        mSelIndex = -1 ;
        //mBClrRef = getClrRef(defBackColor) ;
        //mFClrRef = getClrRef(defForeColor) ;
        mClsName = "ComboBox" ;
        this.mName = format("%s_%d", "ComboBox_", cmbNumber);
        ++cmbNumber;
    }

    this(Window parent) { this(parent, 20, 20, 150, 30) ; }
    this (Window parent, int x, int y) { this(parent, x, y, 150, 30) ; }

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
            if (this.mCmbStyle == value) return;
            this.mCmbStyle = value;
            this.mRecreateEnabled = true;
            DestroyWindow(this.mHandle);
            this.create();
        } else {
            // No need to create a new one.
            this.mCmbStyle = value;
        }
    }

    /// Get the drop down style of ComboBox.
    final DropDownStyle dropDownStyle() {return this.mCmbStyle ;}

    /// Add an item into ComboBox's items collection.
    void addItem(T)(T value) {
        if (this.mIsCreated) {
            auto sitem = value.to!string;
            this.mItems ~= sitem;
            auto witem = sitem.toUTF16z;
            this.sendMsg(CB_ADDSTRING, 0, witem);
        } else {
            this.mItems ~= value.to!string;
        }
    }

    /// Add an array to ComboBox's items collection.
    void addRange(T)( T[] newItems) {
        if (this.mIsCreated) {
            foreach (item ; newItems) {
                auto witem = toUTF16z(item) ;
                this.mItems ~= item.to!string;
                this.sendMsg(CB_ADDSTRING, 0, witem);
            }
        } else {
            foreach (item; newItems) this.mItems ~= item.to!string;
        }
    }

    void addRange(T...)( T newItems) {
        if (this.mIsCreated) {
            foreach (item ; newItems) {
                auto sitem = item.to!string;
                auto witem = sitem.toUTF16z;
                this.mItems ~= sitem;
                this.sendMsg(CB_ADDSTRING, 0, witem) ;
            }
        } else {
            foreach (value; newItems) this.mItems ~= value.to!string;
        }
    }

    /// Remove the given item from ComboBox's items collection.
    void removeItem(T)(T item) {
        zstring cmbItem = item.toUTF16z ;
        string myItem = item.to!string;
        if (this.mItems.length > 0) {
            this.mItems = this.mItems.remove!(a => a == myItem) ;
            if (this.mIsCreated) { // Remove item from combo also.
                auto iIndex = cast(int) this.sendMsg(CB_FINDSTRING, -1, cmbItem) ;
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
            assumeSafeAppend(this.mItems);
            if (this.mIsCreated) this.sendMsg(CB_DELETESTRING, 0, 0) ;
        }
    }

    /// Get the count of items in ComboBox.
    final int itemCount() {return cast(int) this.mItems.length ;}




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
        if (this.mCmbStyle == DropDownStyle.labelCombo) {
            this.mStyle |= CBS_DROPDOWNLIST;
        } else {
            this.mStyle |= CBS_DROPDOWN;
        }
        this.mHandle = CreateWindowEx(  this.mExStyle,
                                        mClsName.ptr,
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
        //ComboInfo myInfo ;


        // Get and save the internal info of a ComboBox.
		void getComboInfo() {
			COMBOBOXINFO cmbInfo ;
			cmbInfo.cbSize = cmbInfo.sizeof ;
			this.sendMsg(CB_GETCOMBOBOXINFO, 0, &cmbInfo) ;
            this.mParent.cmb_dict[cmbInfo.hwndList] = this.mHandle; // Put the handle in parent's dic
            SetWindowSubclass(  cmbInfo.hwndItem,
                                &cmbEditWndProc,
                                UINT_PTR(editSubClsID),
                                this.toDwPtr);
            ++editSubClsID ;
		}

        // Internal function to insert items to ComboBox.
        void insertItems() {
            if (this.mItems.length > 0 ) {
                foreach (item; this.mItems) {
                    auto witem = toUTF16z(item);
                    this.sendMsg(CB_ADDSTRING, 0, witem) ;
                }
            }
        }

        void finalize(UINT_PTR scID) {
    		DeleteObject(this.mBkBrush);
            // We need to remove the subclassing of the edit control.
           // RemoveWindowSubclass(this.myInfo.tbHwnd, &cmbEditWndProc, this.myInfo.tbSubClsId);
            this.remSubClass(scID);
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
            case WM_DESTROY : cmb.finalize(scID); break;
            case WM_PAINT: cmb.paintHandler(); break;
            case WM_LBUTTONUP : cmb.mouseUpHandler(message, wParam, lParam); break ;
            case CM_LEFTCLICK : cmb.mouseClickHandler(); break;
            case WM_RBUTTONDOWN : cmb.mouseRDownHandler(message, wParam, lParam); break;
            case WM_RBUTTONUP : cmb.mouseRUpHandler(message, wParam, lParam); break;
            case CM_RIGHTCLICK : cmb.mouseRClickHandler(); break;
            case WM_MOUSEWHEEL : cmb.mouseWheelHandler(message, wParam, lParam); break;
            case WM_MOUSEMOVE : cmb.mouseMoveHandler(message, wParam, lParam); break;
            case WM_MOUSELEAVE :
                // Here, we need to do a trick. Actually, in a Combobox, when it's
                // text input mode enabled, we get two mouse leave msg & two mouse move msg
                // Because, combo's text area is an edit control. It is surrounded by the combo.
                // So, when mouse enters the combo's rect, we get a mouse move msg.
                // But when mouse enters into text box's rect, we get a mouse leave from
                // combo and mouse move from textbox. So here we are checking the mouse is
                // in combo's rect or not. If it is stil inside, we suppress the mouse leave
                // and continue receiving the mouse move msgs from text are.
                if (cmb.dropDownStyle == DropDownStyle.textCombo) {
                    if (cmb.isInComboRect(hWnd)) {
                        return 1;
                    } else {
                        if (cmb.onMouseLeave) cmb.onMouseLeave(cmb, new EventArgs());
                    }
                } else {
                    if (cmb.onMouseLeave) cmb.onMouseLeave(cmb, new EventArgs());
                }
            break ;

            case WM_KEYDOWN :
                // To get this message here, cmb's drop down style must be labelCombo.
                if (cmb.onKeyDown) {
                    auto kea = new KeyEventArgs(wParam);
                    cmb.onKeyDown(cmb, kea) ;
                }
            break ;

            case WM_KEYUP :
                // To get this message here, cmb's drop down style must be labelCombo.
                if (cmb.onKeyUp) {
                    auto kea = new KeyEventArgs(wParam);
                    cmb.onKeyUp(cmb, kea) ;
                }
            break ;

            case CM_COLOR_CMB_LIST :
                // We can change the colors of List area & text area of a combo. Here we are dealing with list area.
                // NOTE : You can change colors OF both text & list only when DropDownStyle = textCombo.
                // NOTE : In labelCombo mode, if you change the color, it won't be affect in text area.
                // Only change the color if user wants to be.
                if (cmb.mBackColor.value != defBackColor || cmb.mForeColor.value != defForeColor) {
                    auto hdc = cast(HDC) wParam ;
                    SetBkMode(hdc, TRANSPARENT) ;
                    if (cmb.mForeColor.value != defForeColor) SetTextColor(hdc, cmb.mForeColor.reff) ;
                    cmb.mBkBrush = CreateSolidBrush(cmb.mBackColor.reff);
                    return cast(LRESULT) cmb.mBkBrush ;
                } else {
                    // Otherwise return the default color(white) brush.
                    // If you don't do this, you can see black background inthe listbox.
                    cmb.mBkBrush = CreateSolidBrush(cmb.mBackColor.reff);
                    return cast(LRESULT) cmb.mBkBrush ;
                }
            break ;

            case CM_CTLCOMMAND :
                auto nCode = HIWORD(wParam) ;
                print("ncode ", nCode);
                switch (nCode) {
                    case CBN_SELCHANGE :
                        if (cmb.onSelectionChanged) cmb.onSelectionChanged(cmb, new EventArgs());
                    break ;

                    case CBN_SETFOCUS :
                        if (cmb.onGotFocus) cmb.onGotFocus(cmb, new EventArgs());
                    break ;

                    case CBN_KILLFOCUS :
                        if (cmb.onLostFocus) cmb.onLostFocus(cmb, new EventArgs());
                    break ;

                    case CBN_EDITCHANGE :
                        if (cmb.onTextChanged) cmb.onTextChanged(cmb, new EventArgs());
                    break ;

                    case CBN_EDITUPDATE :
                        if (cmb.onTextUpdated) cmb.onTextUpdated(cmb, new EventArgs());
                    break ;

                    case CBN_DROPDOWN :
                        if (cmb.onListOpened) cmb.onListOpened(cmb, new EventArgs());
                    break ;

                    case CBN_CLOSEUP :
                        if (cmb.onListClosed) cmb.onListClosed(cmb, new EventArgs());
                    break ;

                    case CBN_SELENDOK :
                        if (cmb.onSelectionCommitted) cmb.onSelectionCommitted(cmb, new EventArgs());
                    break ;

                    case CBN_SELENDCANCEL :
                        if (cmb.onSelectionCancelled) cmb.onSelectionCancelled(cmb, new EventArgs());
                    break;

                    default : break ;
                }
            break ;

            default : return DefSubclassProc(hWnd, message, wParam, lParam) ; break;
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
            case WM_DESTROY:
                RemoveWindowSubclass(hWnd, &cmbEditWndProc, scID);
            break;

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
                }
            break ;

            case WM_LBUTTONUP :
                if (cmb.dropDownStyle == DropDownStyle.textCombo) {
                    if (cmb.onTextMouseUp) {
                       auto mea = new MouseEventArgs(message, wParam, lParam);
                       cmb.onTextMouseUp(cmb, mea) ;
                    }
                }
                if (cmb.tbMLDownHappened) {
                    cmb.tbMLDownHappened = false ;
                    sendMsg(cmb.mHandle, CM_LEFTCLICK, 0, 0) ;
                }
            break ;

            case CM_LEFTCLICK :
                if (cmb.onTextMouseClick) {
                    auto ea = new EventArgs() ;
                    cmb.onMouseClick(cmb, ea) ;
                }
            break ;

            case WM_RBUTTONDOWN :
                if (cmb.dropDownStyle == DropDownStyle.textCombo) {
                    cmb.tbMRDownHappened = true ;
                    if (cmb.onTextRightDown) {
                       auto mea = new MouseEventArgs(message, wParam, lParam);
                       cmb.onTextRightDown(cmb, mea) ;
                       return 0 ;
                    }
                }
            break ;

            case WM_RBUTTONUP :
                if (cmb.dropDownStyle == DropDownStyle.textCombo) {
                    if (cmb.onTextRightUp) {
                       auto mea = new MouseEventArgs(message, wParam, lParam);
                       cmb.onTextRightUp(cmb, mea) ;
                    }
                }
                if (cmb.tbMRDownHappened) {
                    cmb.tbMRDownHappened = false ;
                    sendMsg(cmb.mHandle, CM_RIGHTCLICK, 0, 0) ;
                }
            break ;

            case CM_RIGHTCLICK :
                if (cmb.onTextRightClick) {
                    auto ea = new EventArgs() ;
                    cmb.onTextRightClick(cmb, ea) ;
                }
            break ;

            case CM_COLOR_EDIT:
                // Here, we receive color changing message for text box of combo.
                // NOTE: this is only work for text typing combo box.
                if (cmb.mBackColor.value != defBackColor || cmb.mForeColor.value != defForeColor) {
                    auto hdc = cast(HDC) wParam ;
                    SetBkMode(hdc, TRANSPARENT) ;
                    if (cmb.mForeColor.value != defForeColor) SetTextColor(hdc, cmb.mForeColor.reff) ;
                    cmb.mBkBrush = CreateSolidBrush(cmb.mBackColor.reff);
                    return cast(LRESULT) cmb.mBkBrush ;
                }
            break;

            case WM_MOUSEMOVE:
                cmb.mouseMoveHandler(message, wParam, lParam);
            break;

            default : return DefSubclassProc(hWnd, message, wParam, lParam) ; break;
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}
