
// Created on: 27-May-22 02:42:52 PM
/*==============================================ListBox Docs=====================================
    Constructor:
        this(Form parent)
        this(Form parent, int x, int y)
        this(Form parent, int x, int y, int w, int h)

	Properties:
		ListBox inheriting all Control class properties	
        hasHScroll          : bool
        hasVScroll          : bool
        selectedIndex       : int
        selectedIndices     : int[]
        selectedItem        : string
        selectedItems       : string[]
			
    Methods:
        createHandle
        selectAll
        clearSelection
        insertItem
        getIndex
        getHotIndex
        getHotItem
        getItem
        removeItem
        removeAll
        addItem
        addRange
        
    Events:
        All public events inherited from Control class. (See controls.d)
        EventHandler - void delegate(Control, EventArgs)
            onSelectionChanged       
=============================================================================================*/

module wings.listbox;
import wings.d_essentials;
import std.conv;
import std.array;
import std.algorithm;
import wings.wings_essentials;
import std.stdio;

enum wchar[] mClassName = ['L', 'I', 'S', 'T', 'B', 'O', 'X', 0];
enum DWORD lbxStyle = WS_VISIBLE | WS_CHILD | WS_BORDER  | LBS_NOTIFY | LBS_HASSTRINGS;

class ListBox: Control {

    this(Form parent, int x, int y, int w, int h)
    {
        mixin(repeatingCode);
        ++lbxNumber;
        mControlType = ControlType.listBox;
        this.mFont = new Font(parent.font);
        mStyle = lbxStyle;
        mExStyle = 0;
        mBackColor(defBackColor);
        mForeColor(defForeColor);
        this.mName = format("%s_%d", "ListBox_", lbxNumber);
        this.mParent.mControls ~= this;
        this.mHasFont = true;
        this.mCtlId = Control.stCtlId;
        ++Control.stCtlId;
        if (parent.mAutoCreate) this.createHandle();
    }

    this(Form parent) { this(parent, 20, 20, 180, 200); }
    this(Form parent, int x, int y) { this(parent, x, y, 180, 200);}


    mixin finalProperty!("hasHScroll", this.mUseHscroll);
    mixin finalProperty!("hasVScroll", this.mUseVscroll);

    /// Get the seleted index from ListBox. (Only for single selection mode)
    final int selectedIndex() { return this.mSelIndex; }

    /// Set the selected index of ListBox.(Only for single selection mode)
    final void selectedIndex(int value)
    {
        if (this.mIsCreated) {
            auto res = this.sendMsg(LB_SETCURSEL, value, 0);
            if (res != LB_ERR) this.mSelIndex = value;
        } else this.mDummyIndex = value;
    }

    /// Get the selected indices from ListBox. (Only for multi selection mode)
    final intArray selectedIndices()
    {
        intArray selItems;
        if (this.mMultiSel && this.mIsCreated) {
            auto selCount = this.sendMsg(LB_GETSELCOUNT, 0, 0);
            if (selCount != LB_ERR) {
                selItems.length = selCount;
                this.sendMsg(LB_GETSELITEMS, selCount, selItems.ptr);
            }
        }
        return selItems;
    }

    /// Get the selected item from ListBox. (Only for single selection mode)
    final string selectedItem()
    {
        if (this.mIsCreated && this.mSelIndex > -1) return getItemInternal(this.mSelIndex);
        return "";
    }

    /// Get the selected items from ListBox. (Only for multi selection mode)
    final string[] selectedItems()
    {
        string[] result;
        if (this.mIsCreated) {
            auto selCount = this.sendMsg(LB_GETSELCOUNT, 0, 0);
            if (selCount != LB_ERR) {
                intArray iBuffer;
                iBuffer.length = selCount;
                this.sendMsg(LB_GETSELITEMS, selCount, iBuffer.ptr);
                foreach (indx; iBuffer) result ~= getItemInternal(indx);
            }
        }
        return result;
    }

    /// Select all items of a multi selection list box
    final void selectAll()
    {
        if (this.mIsCreated && this.mMultiSel) this.sendMsg(LB_SETSEL, true, -1 );
    }

    /// Clear selection from a list box
    final void clearSelection()
    {
        if (this.mIsCreated) {
            if (this.mMultiSel) {
                this.sendMsg(LB_SETSEL, false, -1 );
            } else {
                this.sendMsg(LB_SETCURSEL, -1, 0 );
            }
        }
    }

    /// Insert item to ListBox at the given index
    void insertItem(T)(T item, int index)
    {
        auto sItem = item.to!string();
        clearItemsInternal();
        this.mItems.insertInPlace(index, sItem);
        foreach (elem; this.mItems) this.sendMsg(LB_ADDSTRING, 0, elem.ptr()); // Fill the listbox again.
    }

    /// Get the index of given item from ListBox
    int getIndex(t)(t item)
    {
        auto sItem = item.toString();
        return this.sendMsg(LB_FINDSTRINGEXACT, -1, sItem.ptr);
    }

    /// Get the index of item under mouse pointer
    final int getHotIndex()
    {
        //long wp = 0;
        //long lp = 0;
        if (this.mMultiSel) return cast(int)this.sendMsg(LB_GETCARETINDEX, 0, 0);
        return -1;
    }

    /// Get the item under mouse pointer
    final string getHotItem()
    {
        if (this.mMultiSel) {
            auto indx = this.sendMsg(LB_GETCARETINDEX, 0, 0);
            if (indx > -1) return getItemInternal(indx);
        }
        return NULL;
    }

    /// Get the item of given index
    final string getItem(int index) in (index >= 0)
    {
        auto tLen = this.sendMsg(LB_GETTEXTLEN, index, 0);
        if (tLen != LB_ERR) return getItemInternal(index);
        return NULL;
    }

    /// Remove an item from listbox.
    final void removeItem(int index)
    {
        // We faced a strange problem here. If we use LB_DELETESTRING msg,
        // one item will be drawned upon  another item. I can't find a
        // solution to this.  So I found a workwround.
        clearItemsInternal(); // Clear all items from listbox
        this.mItems = this.mItems.remove(index);  // Remove item frm my own collection
        foreach (item; this.mItems) this.sendMsg(LB_ADDSTRING, 0, item.ptr); // Fill the listbox again.
    }

    /// Clear all items from list box.
    final void removeAll()
    {
        if (this.mIsCreated) {
            this.sendMsg(LB_RESETCONTENT, 0, 0);
            this.mItems.length = 0;
            assumeSafeAppend(this.mItems);
        }
    }

    /// Add an item to ListBox.
    void addItem(T)(T item)
    {
        string sItem = item.to!string;
        this.mItems ~= sItem;
        if (this.mIsCreated) this.sendMsg(LB_ADDSTRING, 0, sItem.toUTF16z());
    }

    /// Add a range of items to ListBox. (Items of different types)
    void addRange(T...)(T items)
    {
        if (this.mIsCreated) {
            foreach (item; items) {
                auto sitem = item.to!string;
                this.mItems ~= sitem;
                this.sendMsg(LB_ADDSTRING, 0, sitem.toUTF16z);
            }
        } else {
            foreach (item; items) { this.mItems ~= item.to!string;}
        }
    }

    /// Add a range of items to ListBox. (Items of similar type)
    void addRange(T)(T[] items)
    {
        if (this.mIsCreated) {
            foreach (item; items) {
                auto sitem = item.to!string;
                this.mItems ~= sitem;
                this.sendMsg(LB_ADDSTRING, 0, sitem.toUTF16z);
            }
        } else {
            foreach (item; items) { this.mItems ~= item.to!string;}
        }
    }

     // Create the handle of CheckBox
    override void createHandle()
    {
    	this.setLboxStyles();
        this.createHandleInternal(mClassName.ptr);
        if (this.mHandle) {
            this.setSubClass(&lbxWndProc);
            if (this.mItems.length > 0) {
            // We need to add those items to list box
                foreach (item; this.mItems) this.sendMsg(LB_ADDSTRING, 0, item.toUTF16z);
                if (this.mDummyIndex > -1) this.sendMsg(LB_SETCURSEL, this.mDummyIndex, 0);
            }
        }
    }

    // Events
    EventHandler onSelectionChanged;


    private:
        bool mHasSort;
        bool mNoSel;
        bool mMultiCol;
        bool mKeyPrev;
        bool mUseVscroll;
        bool mUseHscroll;
        bool mMultiSel;
        int[] mSelIndices;
        string[] mItems;
        int mDummyIndex = -1;
        int mSelIndex = -1;
        static int lbxNumber;

        // Setting list box styles as per user's choice.
        void setLboxStyles()
        { // Private
            if (this.mHasSort) this.mStyle |= LBS_SORT;
            if (this.mMultiSel) this.mStyle |= LBS_EXTENDEDSEL | LBS_MULTIPLESEL;
            if (this.mMultiCol) this.mStyle |= LBS_MULTICOLUMN;
            if (this.mNoSel) this.mStyle |= LBS_NOSEL;
            if (this.mKeyPrev) this.mStyle |= LBS_WANTKEYBOARDINPUT;
            if (this.mUseHscroll) this.mStyle |= WS_HSCROLL;
            if (this.mUseVscroll) this.mStyle |= WS_VSCROLL;
        }

        // Helper function to get the item from listbox.
        string getItemInternal(long index) in (index >= 0)
        { // Private
            auto tLen = this.sendMsg(LB_GETTEXTLEN, index, 0);
            if (tLen != LB_ERR) {
                wchar[] buffer = new wchar[](tLen);
                this.sendMsg(LB_GETTEXT, index, buffer.ptr);
                return buffer.to!string;
            }
            return NULL;
        }

        void clearItemsInternal()
        { // private
            this.sendMsg(LB_RESETCONTENT, 0, 0);
            UpdateWindow(this.mHandle);
        }

        void finalize(UINT_PTR scID)
        { 
            DeleteObject(this.mBkBrush);
            RemoveWindowSubclass(this.mHandle, &lbxWndProc, scID);
        }

} // End of ListBox class

extern(Windows)
private LRESULT lbxWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                                UINT_PTR scID, DWORD_PTR refData)
{
    try {
        switch (message) {
            case WM_DESTROY: 
                ListBox lbx = getControl!ListBox(refData);
                lbx.finalize(scID); 
            break;
            case WM_PAINT: 
                ListBox lbx = getControl!ListBox(refData);
                lbx.paintHandler(); 
            break;
            case WM_LBUTTONDOWN: 
                ListBox lbx = getControl!ListBox(refData);
                lbx.mouseDownHandler(message, wParam, lParam); 
            break;
            case WM_LBUTTONUP: 
                ListBox lbx = getControl!ListBox(refData);
                lbx.mouseUpHandler(message, wParam, lParam); 
            break;
            case WM_RBUTTONDOWN: 
                ListBox lbx = getControl!ListBox(refData);
                lbx.mouseRDownHandler(message, wParam, lParam); 
            break;
            case WM_RBUTTONUP: 
                ListBox lbx = getControl!ListBox(refData);
                lbx.mouseRUpHandler(message, wParam, lParam); 
            break;
            case WM_MOUSEWHEEL: 
                ListBox lbx = getControl!ListBox(refData);
                lbx.mouseWheelHandler(message, wParam, lParam); 
            break;
            case WM_MOUSEMOVE: 
                ListBox lbx = getControl!ListBox(refData);
                lbx.mouseMoveHandler(message, wParam, lParam); 
            break;
            case WM_MOUSELEAVE: 
                ListBox lbx = getControl!ListBox(refData);
                lbx.mouseLeaveHandler(); 
            break;
            case CM_COLOR_EDIT:
                ListBox lbx = getControl!ListBox(refData);
                if (lbx.mDrawFlag) {
                    auto hdc = cast(HDC) wParam;
                    SetBkMode(hdc, TRANSPARENT);
                    if (lbx.mDrawFlag & 1) SetTextColor(hdc, lbx.mForeColor.cref);
                    lbx.mBkBrush = CreateSolidBrush(lbx.mBackColor.cref);
                    //print("cm ctl color on lbx");
                    return cast(LRESULT) lbx.mBkBrush;
                }
            break;
            case CM_CTLCOMMAND:
                ListBox lbx = getControl!ListBox(refData);
                auto nCode = HIWORD(wParam);
                switch (nCode) {
                    case LBN_DBLCLK:
                        if (lbx.onDoubleClick) lbx.onDoubleClick(lbx, new EventArgs());
                    break;
                    case LBN_KILLFOCUS:
                        if (lbx.onLostFocus) lbx.onLostFocus(lbx, new EventArgs());
                    break;
                    case LBN_SELCHANGE:
                        if (!lbx.mMultiSel) {
                            auto selIndx = lbx.sendMsg(LB_GETCURSEL, 0, 0);
                            if (selIndx != LB_ERR) {
                                lbx.mSelIndex = cast(int) selIndx;
                                if (lbx.onSelectionChanged) 
                                    lbx.onSelectionChanged(lbx, new EventArgs());
                            }
                        }
                    break;
                    case LBN_SETFOCUS:
                        if (lbx.onGotFocus) lbx.onGotFocus(lbx, new EventArgs());
                    break;
                    // case LBN_SELCANCEL: break;
                    // case LBN_ERRSPACE: break;
                    default: break;
                }
            break;
            case CM_FONT_CHANGED:
                ListBox lbx = getControl!ListBox(refData);
                lbx.updateFontHandle();
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