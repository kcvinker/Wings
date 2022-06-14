module wings.listbox;
// Created on : 27-May-22 02:42:52 PM

import wings.d_essentials;
import std.conv ;
import std.array;
import std.algorithm;
import wings.wings_essentials;


int lbxNumber = 1;
class ListBox : Control {

    this(Window parent, int x, int y, int w, int h) {              
        mWidth = w ;
        mHeight = h ;
        mXpos = x ;
        mYpos = y ;
        mParent = parent ;
        mFont = parent.font ;        
        mControlType = ControlType.listBox ;         
        mStyle = WS_VISIBLE | WS_CHILD | WS_BORDER  | LBS_NOTIFY  ;
        mExStyle = 0 ;         
        mBackColor = defBackColor ;
        mForeColor = defForeColor;
        mBClrRef = getClrRef(defBackColor) ;
        mFClrRef = getClrRef(this.mForeColor) ;
        mClsName = toUTF16z("LISTBOX") ;    
        ++lbxNumber;
       // mMultiSel = true;        
    }

    this(Window parent) { this(parent, 20, 20, 180, 200) ; }
    this(Window parent, int x, int y) { this(parent, x, y, 180, 200);} 

    /// Get the seleted index from ListBox. (Only for single selection mode)
    final int selectedIndex() { return this.mSelIndex; }
    
    /// Set the selected index of ListBox.(Only for single selection mode)
    final void selectedIndex(int value) {                
        if (this.mIsCreated) {
            auto res = this.sendMsg(LB_SETCURSEL, value, 0);
            if (res != LB_ERR) this.mSelIndex = value;
        } else this.mDummyIndex = value;
    }

    /// Get the selected indices from ListBox. (Only for multi selection mode)
    final int[] selectedIndices() {        
        int[] selItems;
        if (this.mMultiSel && this.mIsCreated) {
            auto selCount = this.sendMsg(LB_GETSELCOUNT, 0, 0);
            if (selCount != LB_ERR) {                
                selItems.length = selCount;
                auto res = this.sendMsg(LB_GETSELITEMS, selCount, selItems.ptr);                
            }            
        }
        return selItems;
    }

    /// Get the selected item from ListBox. (Only for single selection mode)
    final string selectedItem() {        
        if (this.mIsCreated && this.mSelIndex > -1) return getItemInternal(this.mSelIndex);         
        return "";
    }

    /// Get the selected items from ListBox. (Only for multi selection mode)
    final string[] selectedItems() {        
        string[] result;
        if (this.mIsCreated) {
            auto selCount = this.sendMsg(LB_GETSELCOUNT, 0, 0);
            if (selCount != LB_ERR) {
                int[] iBuffer;
                iBuffer.length = selCount;
                this.sendMsg(LB_GETSELITEMS, this.mSelIndex, iBuffer.ptr);
                foreach (indx; iBuffer) result ~= getItemInternal(indx);                
            }
        }
        return result;
    }

    /// Select all items of a multi selection list box
    final void selectAll() { 
        if (this.mIsCreated && this.mMultiSel) this.sendMsg(LB_SETSEL, true, -1 ); 
    }

    /// Clear selection from a list box
    final void clearSelection() { 
        if (this.mIsCreated) {
            if (this.mMultiSel) {
                this.sendMsg(LB_SETSEL, false, -1 ); 
            } else this.sendMsg(LB_SETCURSEL, this.mSelIndex, 0 ); 
        }
    }

    /// Insert item to ListBox at the given index
    void insertItem(T)(T item, int index) {        
        auto sItem = item.toString();  
        clearItemsInternal();      
        this.mItems.insertInPlace(index, sItem);
        foreach (elem; this.mItems) this.sendMsg(LB_ADDSTRING, 0, elem.toUTF16z()); // Fill the listbox again.
    }

    /// Get the index of given item from ListBox
    int getIndex(t)(t item) {
        auto sItem = item.toString();
        return this.sendMsg(LB_FINDSTRINGEXACT, -1, sItem.toUTF16z);
    }

    /// Get the index of item under mouse pointer
    final int getHotIndex() {
        if (this.mMultiSel) return this.sendMsg(LB_GETCARETINDEX, 0, 0) ;
        return -1;
    }

    /// Get the item under mouse pointer
    final string getHotItem() {
        if (this.mMultiSel) {
            auto indx = this.sendMsg(LB_GETCARETINDEX, 0, 0);
            if (indx > -1) return getItemInternal(indx);
        }
        return NULL;
    }

    /// Get the item of given index
    final string getItem(int index) in (index >= 0) {
        auto tLen = this.sendMsg(LB_GETTEXTLEN, index, 0);
        if (tLen != LB_ERR) return getItemInternal(index); 
        return NULL ;       
    }
    
    /// Remove an item from listbox.
    final void removeItem(int index) { 
        // We faced a strange problem here. If we use LB_DELETESTRING msg, 
        // one item will be drawned upon  another item. I can't find a 
        // solution to this.  So I found a workwround. 
        clearItemsInternal(); // Clear all items from listbox        
        this.mItems = this.mItems.remove(index);  // Remove item frm my own collection        
        foreach (item; this.mItems) this.sendMsg(LB_ADDSTRING, 0, item.toUTF16z()); // Fill the listbox again.
        
    }

    /// Clear all items from list box.
    final void removeAll() { 
        if (this.mIsCreated) {
            this.sendMsg(LB_RESETCONTENT, 0, 0);
            this.mItems.length = 0;  
            assumeSafeAppend(this.mItems);
        }      
    }   

    /// Add an item to ListBox.
    void addItem(T)(T item) {
        string sItem = item.toString;
        this.mItems ~= sItem ;
        if (this.mIsCreated) this.sendMsg(LB_ADDSTRING, 0, sItem.toUTF16z()) ; 
    }

    /// Add a range of items to ListBox. (Items of different types)
    void addRange(T...)(T items) {
        string[] tempItems;        
        foreach (i; items) {
            auto sValue = i.toString;
            this.mItems ~= sValue ;
            tempItems ~= sValue ;           
        }        
        if (this.mIsCreated) {
            foreach (item ; tempItems) this.sendMsg(LB_ADDSTRING, 0, item.toUTF16z()) ;             
        }
    }

    /// Add a range of items to ListBox. (Items of similar type)
    void addRange(T)(T[] items) {
        string[] tempItems;     
        static if (is(T == string))
        {
            this.mItems ~= items;
            tempItems ~= items;
        } else {
            foreach (i; items) {
                string sitem = i.to!string ;
                this.mItems ~= sitem ;
                tempItems ~= sitem ; 
            }
        }            
        if (this.mIsCreated) {
            foreach (item ; tempItems) this.sendMsg(LB_ADDSTRING, 0, item.toUTF16z()) ;             
        }
    }

     // Create the handle of CheckBox
    final void create() {
    	this.setLboxStyles() ;        
        this.createHandle();    
        if (this.mHandle) {            
            this.setSubClass(&lbxWndProc) ;            
            if (this.mItems.length > 0) { // We need to add those items to list box
                foreach (item; this.mItems) this.sendMsg(LB_ADDSTRING, 0, item.toUTF16z());
                if (this.mDummyIndex > -1) this.sendMsg(LB_SETCURSEL, this.mDummyIndex, 0);
            }          
        }        
    }

    // Events
    EventHandler onSelectionChanged;


    package :
        HBRUSH mBkBrush ;
        int mSelIndex = -1 ;
        bool mMultiSel; // We need this in WndProc. So it must be at package scope.


        final void finalize() { // Package           
            DeleteObject(this.mBkBrush) ;
        }

    
    private :
        bool mHasSort;
        bool mNoSel ;        
        bool mMultiCol;
        bool mKeyPrev;
        int[] mSelIndices;
        string[] mItems;        
        int mDummyIndex = -1;

        // Setting list box styles as per user's choice.
        void setLboxStyles() { // Private
            if (this.mHasSort) this.mStyle |= LBS_SORT;
            if (this.mMultiSel) this.mStyle |= LBS_EXTENDEDSEL | LBS_MULTIPLESEL;
            if (this.mMultiCol) this.mStyle |= LBS_MULTICOLUMN;
            if (this.mNoSel) this.mStyle |= LBS_NOSEL;
            if (this.mKeyPrev) this.mStyle |= LBS_WANTKEYBOARDINPUT;
        }

        // Helper function to get the item from listbox.
        string getItemInternal(int index) in (index >= 0) { // Private      
            auto tLen = this.sendMsg(LB_GETTEXTLEN, index, 0);
            if (tLen != LB_ERR) {
                wchar[] buffer = new wchar[](tLen);
                this.sendMsg(LB_GETTEXT, index, buffer.ptr);
                return buffer.to!string;
            }
            return NULL;
        }

        void clearItemsInternal() {
            this.sendMsg(LB_RESETCONTENT, 0, 0);       
            UpdateWindow(this.mHandle); 
        }

} // End of ListBox class

extern(Windows)
private LRESULT lbxWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData)  {
    try {   
        ListBox lbx = getControl!ListBox(refData)  ;
        switch (message) {
            case WM_DESTROY :
                lbx.finalize ;
                lbx.remSubClass(scID);
                break ;
            case WM_PAINT :            
                if (lbx.onPaint) {
                    PAINTSTRUCT  ps ;
                    BeginPaint(hWnd, &ps) ;
                    auto pea = new PaintEventArgs(&ps) ;
                    lbx.onPaint(lbx, pea) ;
                    EndPaint(hWnd, &ps) ;
                    return 0 ;
                }  break ;
            
            case CM_CTLCOLOR :
                if (lbx.mForeColor != defForeColor || lbx.mBackColor != defBackColor) {
                    auto hdc = cast(HDC) wParam;
                    SetBkMode(hdc, TRANSPARENT);
                    if (lbx.mForeColor != defForeColor) SetTextColor(hdc, lbx.mFClrRef);
                    lbx.mBkBrush = CreateSolidBrush(lbx.mBClrRef);
                    return cast(LRESULT) lbx.mBkBrush;
                } break ;

            case CM_CTLCOMMAND :                
                auto nCode = HIWORD(wParam);
                switch (nCode) {
                    case LBN_DBLCLK :
                        if (lbx.onDoubleClick) {
                            auto ea = new EventArgs() ;
                            lbx.onDoubleClick(lbx, ea);
                        } break ;

                    case LBN_KILLFOCUS :
                        if (lbx.onLostFocus) {
                            auto ea = new EventArgs() ;
                            lbx.onLostFocus(lbx, ea);
                        } break ;

                    case LBN_SELCHANGE :                        
                        if (!lbx.mMultiSel) {
                            auto selIndx = lbx.sendMsg(LB_GETCURSEL, 0, 0);
                            if (selIndx != LB_ERR) {
                                lbx.mSelIndex = selIndx;                                
                                if (lbx.onSelectionChanged) {
                                    auto ea = new EventArgs() ;
                                    lbx.onSelectionChanged(lbx, ea);
                                }
                            }
                        } break;
                    
                    case LBN_SETFOCUS :
                        if (lbx.onGotFocus) {
                            auto ea = new EventArgs() ;
                            lbx.onGotFocus(lbx, ea);
                        } break ;

                    case LBN_SELCANCEL :
                        break ;                   
                    
                    default : break;
                } break;

            case WM_LBUTTONDOWN : 
                lbx.lDownHappened = true ;  
                if (lbx.onMouseDown) {
                   auto mea = new MouseEventArgs(message, wParam, lParam);
                   lbx.onMouseDown(lbx, mea) ;
                   return 0 ;
                } break ;            

            case WM_LBUTTONUP :
                if (lbx.onMouseUp) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    lbx.onMouseUp(lbx, mea) ;                    
                }
                if (lbx.lDownHappened) {
                    lbx.lDownHappened = false ;
                    sendMsg(lbx.handle, CM_LEFTCLICK, 0, 0) ;                    
                } break ;

            case CM_LEFTCLICK :
                if (lbx.onMouseClick) {
                    auto ea = new EventArgs() ;
                    lbx.onMouseClick(lbx, ea) ;
                } break ;


            case WM_RBUTTONDOWN :
                lbx.rDownHappened = true ;
                if (lbx.onRightMouseDown) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    lbx.onRightMouseDown(lbx, mea) ; 
                    return 0 ;
                } break ;

            case WM_RBUTTONUP :
                if (lbx.onRightMouseUp) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    lbx.onRightMouseUp(lbx, mea) ;                     
                } 
                if (lbx.rDownHappened) {
                    lbx.rDownHappened = false ;
                    sendMsg(lbx.handle, CM_RIGHTCLICK, 0, 0) ;                    
                } break ;

            case CM_RIGHTCLICK :
                if (lbx.onRightClick) {
                    auto ea = new EventArgs() ;
                    lbx.onRightClick(lbx, ea) ;
                } break ;

            case WM_MOUSEWHEEL :
                if (lbx.onMouseWheel) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    lbx.onMouseWheel(lbx, mea) ; 
                } break ;

            case WM_MOUSEMOVE :
                if (lbx.isMouseEntered) {
                    if (lbx.onMouseMove) {
                        auto mea = new MouseEventArgs(message, wParam, lParam) ;
                        lbx.onMouseMove(lbx, mea) ;
                    }
                } else {
                    lbx.isMouseEntered = true ;
                    if (lbx.onMouseEnter) {
                        auto ea = new EventArgs() ;
                        lbx.onMouseEnter(lbx, ea) ;
                    }
                } break ;

            case WM_MOUSELEAVE :
                lbx.isMouseEntered = false ;
                if (lbx.onMouseLeave) {
                    auto ea = new EventArgs() ;
                    lbx.onMouseLeave(lbx, ea) ;
                } break ;

            default : return DefSubclassProc(hWnd, message, wParam, lParam) ;
        }
        
    }
    catch (Exception e) {}     
    return DefSubclassProc(hWnd, message, wParam, lParam);
}