
/*==============================================ComboBox Docs=====================================
Constructor:
    this(Form parent)
    this (Form parent, int x, int y)
    this(Form parent, int x, int y, int w, int h)

	Properties:
		ComboBox inheriting all Control class properties
        items               : string[]
        selectedIndex       : int
        selectedItem        : string
        dropDownStyle		: DropDownStyle enum [See enums.d]
		itemCount           : int

    Methods:
        createHandle
        addItem
        addRange
        removeItem
        clearItems        
        
    Events:
        All public events inherited from Control class. (See controls.d)
        EventHandler - void delegate(Object, EventArgs)
            onSelectionChanged
            onSelectionCommitted
            onSelectionCancelled
            onTextChanged
            onTextUpdated
            onListOpened
            onListClosed
            onTextMouseClick
            onTextRightClick
        MouseEventHandler - void delegate(Object, MouseEventArgs)
            onTextMouseDown
            onTextMouseUp
            onTextRightDown
            onTextRightUp
        KeyEventHandler - void delegate(Object, KeyEventArgs)
            onTextKeyDown
            onTextKeyUp
        
=============================================================================================*/
module wings.combobox; // Created on 02-May-2022 15:02:41

import wings.d_essentials;
import std.conv;
import std.utf;
import std.stdio;


import std.algorithm.mutation; // We have a function called 'remove'. So this must be renamed.
import wings.wings_essentials;


// private int cmbNumber = 1;
private int editSubClsID = 4000;
/**
 * ComboBox: Control
 */
class ComboBox: Control
{
    this(Form parent, int x, int y, int w, int h)
    {
        mixin(repeatingCode);
        ++cmbNumber;
        mControlType = ControlType.comboBox;
        mStyle = WS_CHILD | WS_VISIBLE;
        mExStyle = WS_EX_CLIENTEDGE;
        mBackColor(defBackColor);
        mForeColor(defForeColor);
        this.mFont = new Font(parent.font);
        mSelIndex = -1;
        this.mName = format("%s_%d", "ComboBox_", cmbNumber);
        this.mParent.mControls ~= this;
        this.mCtlId = Control.stCtlId;
        this.mHasFont = true;
        this.mSpMLeaveProc = &specialMouseLeaveMsgHanlder;
        ++Control.stCtlId;        
        if (parent.mAutoCreate) this.createHandle();
    }

    this(Form parent) { this(parent, 20, 20, 150, 30); }
    this (Form parent, int x, int y) { this(parent, x, y, 150, 30); }

    /// Returns the items collection of ComboBox
	final string[] items() {return this.mItems;}


    /// Get the selected index of ComboBox.
	final int selectedIndex()
    {
        if (this.mIsCreated) this.mSelIndex = cast(int) this.sendMsg(CB_GETCURSEL, 0, 0);
        return this.mSelIndex;
    }

    /// Set the selected index of ComboBox.
	final void selectedIndex(int value)
    {
        this.mSelIndex = value;
        if (this.mIsCreated) {
            this.sendMsg(CB_SETCURSEL, value, 0);
        }
	}

    /// Get the selected item from ComboBox.
    final string selectedItem()
    {
        string result;
        if (this.mIsCreated) {
            this.mSelIndex = cast(int) this.sendMsg(CB_GETCURSEL, 0, 0);
            result = this.mItems[this.mSelIndex];
        }
        return result;
    }

    /// Set the drop down style of ComboBox. Possible values(textCombo, labelCombo)
    final void dropDownStyle(DropDownStyle value) 
    {
        /*----------------------------------------------------------------------- 
        There is no other way to change the dropdown style of an existing combo box.
        We need to destroy the old combo and create new one. Then make it look like 
        the old combo. So this function will do that 
        --------------------------------------------------------------------------*/
        if (this.mIsCreated) {
            if (this.mCmbStyle == value) return;
            this.mSelIndex = cast(int) this.sendMsg(CB_GETCURSEL, 0, 0);
            this.mCmbStyle = value;
            this.mRecreateEnabled = true;
            DestroyWindow(this.mHandle);

            // Revrting styles to default state. 
            // So that we can start from clean state.
            this.mStyle = WS_CHILD | WS_VISIBLE;
            this.createHandle();
        } else {
            // No need to create new combobox.
            this.mCmbStyle = value;
        }
    }

    /// Get the drop down style of ComboBox.
    /// Possible values(textCombo, labelCombo)
    final DropDownStyle dropDownStyle() 
    {
        return this.mCmbStyle;
    } 

    /// Add an item into ComboBox's items collection.
    void addItem(T)(T value)
    {
        if (this.mIsCreated) {
            auto sitem = value.makeString();
            this.mItems ~= sitem;
            auto witem = sitem.toUTF16z;
            this.sendMsg(CB_ADDSTRING, 0, witem);
        } else {
            this.mItems ~= value.makeString();
        }
    }

    /// Add an array to ComboBox's items collection.
    void addRange(T)( T[] newItems)
    {
        if (this.mIsCreated) {
            foreach (item; newItems) {
                auto sitem = item.makeString();
                auto witem = toUTF16z(sitem);
                this.mItems ~= sitem;
                this.sendMsg(CB_ADDSTRING, 0, witem);
            }
        } else {
            foreach (item; newItems) this.mItems ~= item.makeString();
        }
    }

    void addRange(T...)( T newItems)
    {
        if (this.mIsCreated) {
            foreach (item; newItems) {
                auto sitem = item.makeString();
                auto witem = sitem.toUTF16z;
                this.mItems ~= sitem;
                this.sendMsg(CB_ADDSTRING, 0, witem);
            }
        } else {
            foreach (value; newItems) this.mItems ~= value.makeString();
        }
    }

    /// Remove the given item from ComboBox's items collection.
    void removeItem(T)(T item)
    {
        auto cmbItem = item.toUTF16z; // Zstring ???
        string myItem = item.makeString();
        if (this.mItems.length > 0) {
            this.mItems = this.mItems.remove!(a => a == myItem);
            if (this.mIsCreated) {
            // Remove item from combo also.
                auto iIndex = cast(int) this.sendMsg(CB_FINDSTRING, -1, cmbItem);
                if (iIndex > -1) this.sendMsg(CB_DELETESTRING, iIndex, 0);
            }
        }
    }

    /// Remove an item at given index from ComboBox's items collection.
    final void removeItem(int index)
    {
        if (this.mItems.length > 0) {
            this.mItems = this.mItems.remove(index);
            if (this.mIsCreated) this.sendMsg(CB_DELETESTRING, index, 0);
        }
    }

    /// Delete all items from ComboBox's items collection.
    final void clearItems()
    {
        if (this.mItems.length > 0) {
            this.mItems.length = 0;
            assumeSafeAppend(this.mItems);
            if (this.mIsCreated) this.sendMsg(CB_DELETESTRING, 0, 0);
        }
    }

    /// Get the count of items in ComboBox.
    final int itemCount() {return cast(int) this.mItems.length;}


    EventHandler onSelectionChanged;
    EventHandler onSelectionCommitted;
    EventHandler onSelectionCancelled;
    EventHandler onTextChanged, onTextUpdated;
    EventHandler onListOpened, onListClosed;
    MouseEventHandler onTextMouseDown, onTextMouseUp; //, onTextMouseEnter, onTextMouseLeave;
    MouseEventHandler onTextRightDown, onTextRightUp;
    KeyEventHandler onTextKeyDown, onTextKeyUp;
    EventHandler onTextMouseClick, onTextRightClick;


    /// Create the handle of ComboBox control. 
    override void createHandle()
    {
        /*---------------------------------------------------------------- 
        We are not using the base class function here.
        Because, we sometimes need to create the hwnd for existing combo.
        -------------------------------------------------------------------*/ 
        if (!this.mRecreateEnabled) {
            this.ctlId = Control.stCtlId;
            this.mBkBrush = this.mBackColor.getBrush();
        }
        if (this.mCmbStyle == DropDownStyle.labelCombo) {
            this.mStyle |= CBS_DROPDOWNLIST;
        } else {
            this.mStyle |= CBS_DROPDOWN;
        }
        
        this.mHandle = CreateWindowEx(  this.mExStyle,
                                        this.mClassName.ptr,
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
            this.mOldHwnd = this.mHandle;
            this.setSubClass(&cmbWndProc);
            this.setFontInternal();
        	this.getComboInfo();
            insertItems();
            if (this.mSelIndex > -1) this.sendMsg(CB_SETCURSEL, this.mSelIndex, 0);
            if (!this.mRecreateEnabled) ++Control.stCtlId;
            this.mRecreateEnabled = false;
        }
    }

    package:
        RECT mMyRect;

	private:
    // Variables
		DropDownStyle mCmbStyle;
		string[] mItems;
		int mVisItemCount;
		int mSelIndex = -1;
        int ctlId;
		bool mRecreateEnabled;
        bool tbMLDownHappened, tbMRDownHappened;
		HWND mOldHwnd;
        static wchar[] mClassName = ['C', 'o', 'm', 'b', 'o', 'B', 'o', 'x', 0];
        static int cmbNumber;
        //ComboInfo myInfo;
    // End of private vars


        // Get and save the internal info of a ComboBox.
		void getComboInfo() // Private
        { 
			COMBOBOXINFO cmbInfo;
			cmbInfo.cbSize = cmbInfo.sizeof;
			this.sendMsg(CB_GETCOMBOBOXINFO, 0, &cmbInfo);
            this.mParent.cmb_dict[cmbInfo.hwndList] = this.mHandle; // Put the handle in parent's dic
            SetWindowSubclass(  cmbInfo.hwndItem,
                                &cmbEditWndProc,
                                UINT_PTR(editSubClsID),
                                this.toDwPtr);
            ++editSubClsID;
            RECT r;
            GetClientRect(this.mHandle, &r);
            printRct(r, POINT(1, 1), false);
            SetRect(&this.mMyRect, this.mXpos, this.mYpos, this.mXpos + r.right, this.mYpos + r.bottom);
            printRct(this.mMyRect, POINT(0, 0), false);
		}

        // Internal function to insert items to ComboBox.
        void insertItems() // Private
        { 
            if (this.mItems.length > 0 ) {
                foreach (item; this.mItems) {
                    auto witem = toUTF16z(item);
                    this.sendMsg(CB_ADDSTRING, 0, witem);
                }
            }
        }

        int isInComboRect(HWND hw) // Private
        { 
            RECT rc;
            POINT pts;
            GetWindowRect(hw, &rc);
            getMousePoints(pts);
            return PtInRect(&rc, pts);
        }

        void finalize(UINT_PTR scID) // Private
        { 
            if (!this.mRecreateEnabled) DeleteObject(this.mBkBrush);
            RemoveWindowSubclass(this.mHandle, &cmbWndProc, scID);
            // print("Combo finalizer worked");
    	}

} // End class ComboBox...........................................

int x1 = 1;
void printRct(RECT r, POINT p, BOOL res) {
        stdout.flush();
		writefln("[%d]  [%d, %d, %d, %d], [%d, %d] == %s", x1, r.left, r.top, r.right, r.bottom, p.x, p.y, res);
		x1 += 1;
        
	}

MsgHandlerResult specialMouseLeaveMsgHanlder(Control ctl)
{
    /* Since combo box is a combination of a button control and an
        * edit control, we need special treatment for mouse leave event.
        * We need to check if the mouse pointer is inside our control
        * rect each time we get a mouse leave message. Some times, user
        * moves the mouse from edit to arrow button or vice versa.*/
    if (ctl.onMouseLeave || ctl.onMouseEnter || ctl.onMouseMove) {
        auto self = cast(ComboBox) ctl;
        POINT pt;
        GetCursorPos(&pt);
        ScreenToClient(self.mParent.mHandle, &pt);        
        BOOL inside = PtInRect(&self.mMyRect, pt);
        
        if (inside) {     
            printRct(self.mMyRect, pt, inside);   
            return MsgHandlerResult.returnOne;
        } else {
            // self._isMouseEntered = false;
            if (self.mIsMouseTracking &&  self.onMouseLeave) {
                self.mIsMouseTracking = false;
                self.onMouseLeave(self, new EventArgs());
            }
        }
    }
    return MsgHandlerResult.callDefProc; 
}


extern(Windows)
private LRESULT cmbWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                                UINT_PTR scID, DWORD_PTR refData)
{
    try {        
        //print("ComboBox Messages", message);
        ComboBox self = getControl!ComboBox(refData);
        auto res = self.commonMsgHandler(hWnd, message, wParam, lParam);
        if (res == MsgHandlerResult.callDefProc) {
            return DefSubclassProc(hWnd, message, wParam, lParam);
        } else if (res == MsgHandlerResult.returnOne || res == MsgHandlerResult.returnZero) {
            return cast(LRESULT) res;
        }
        switch (message) {
            case WM_DESTROY:                 
                self.finalize(scID); 
            break;
            case WM_PAINT: 
                self.paintHandler(); 
            break;            
            case CM_COLOR_CMB_LIST:
                /*---------------------------------------------------------------
                We can change the colors of List area & text area of a combo. 
                Here we are dealing with list area. NOTE: You can change 
                colors of both text & list only when DropDownStyle = textCombo.
                NOTE: In labelCombo mode, if you change the color, it won't 
                affect in text area. Only change the color if user wants to be.
                ------------------------------------------------------------------*/
                if (self.mDrawFlag) {
                    auto hdc = cast(HDC) wParam;
                    SetBkMode(hdc, TRANSPARENT);
                    if ((self.mDrawFlag & 1) == 1) SetTextColor(hdc, self.mForeColor.cref);
                    if ((self.mDrawFlag & 2) == 2) SetBkColor(hdc, self.mBackColor.cref);

                }
                return cast(LRESULT)self.mBkBrush;
            break;
            case CM_CTLCOMMAND:
                auto nCode = HIWORD(wParam);
                switch (nCode) {
                    case CBN_SELCHANGE:
                        if (self.onSelectionChanged) self.onSelectionChanged(self, new EventArgs());
                    break;

                    case CBN_SETFOCUS:
                        if (self.onGotFocus) self.onGotFocus(self, new EventArgs());
                    break;

                    case CBN_KILLFOCUS:
                        if (self.onLostFocus) self.onLostFocus(self, new EventArgs());
                    break;

                    case CBN_EDITCHANGE:
                        if (self.onTextChanged) self.onTextChanged(self, new EventArgs());
                    break;

                    case CBN_EDITUPDATE:
                        if (self.onTextUpdated) self.onTextUpdated(self, new EventArgs());
                    break;

                    case CBN_DROPDOWN:
                        if (self.onListOpened) self.onListOpened(self, new EventArgs());
                    break;

                    case CBN_CLOSEUP:
                        if (self.onListClosed) self.onListClosed(self, new EventArgs());
                    break;

                    case CBN_SELENDOK:
                        if (self.onSelectionCommitted) self.onSelectionCommitted(self, new EventArgs());
                    break;

                    case CBN_SELENDCANCEL:
                        if (self.onSelectionCancelled) self.onSelectionCancelled(self, new EventArgs());
                    break;
                    default: break;
                }
            break;
            default: 
                return DefSubclassProc(hWnd, message, wParam, lParam); 
            break;
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

/*========================================================================================
We are using special Wndproc function to handle the text box operations...
of a combo box in 'textCombo' drop down style. Because otherwise, we cannot implement...
a key down or key up message handler in textCombo style. The only caveat of this...
approach is, we need to take extra care on the mouse enter & mouse leave messages.
In textCombo mode, we need to check the mouse pointer is inside the combo's rect.
==========================================================================================*/
extern(Windows)
private LRESULT cmbEditWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                                    UINT_PTR scID, DWORD_PTR refData)
{ // @suppress(dscanner.style.long_line)
    try {
        ComboBox self = getControl!ComboBox(refData);
        auto res = self.commonMsgHandler(hWnd, message, wParam, lParam);
        if (res == MsgHandlerResult.callDefProc) {
            return DefSubclassProc(hWnd, message, wParam, lParam);
        } else if (res == MsgHandlerResult.returnOne || res == MsgHandlerResult.returnZero) {
            return cast(LRESULT) res;
        }
        switch (message) {
            case WM_DESTROY: 
                RemoveWindowSubclass(hWnd, &cmbEditWndProc, scID); 
            break;            
            case CM_COLOR_EDIT:
                // Here, we receive color changing message for text box of combo.
                // NOTE: this is only work for text typing combo box.
                if (self.mDrawFlag) {
                    auto hdc = cast(HDC) wParam;
                    // SetBkMode(hdc, TRANSPARENT);
                    if (self.mDrawFlag & 1) SetTextColor(hdc, self.mForeColor.cref);
                    if (self.mDrawFlag & 2) SetBkColor(hdc, self.mBackColor.cref);
                }
                return cast(LRESULT) self.mBkBrush;
            break;
            default: 
                return DefSubclassProc(hWnd, message, wParam, lParam); 
            break;
        }
    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}
