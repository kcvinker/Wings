module wings.listview; // Created on : 01-Jun-22 11:26:46 AM


import std.conv ;
import wings.d_essentials;
import wings.wings_essentials;
import wings.imagelist ;

//----------------------------------------------------




int lvNumber = 1 ;
Wstring wcLvClass ;
DWORD lvStyle = WS_VISIBLE|WS_CHILD|WS_CLIPCHILDREN|WS_CLIPSIBLINGS|LVS_REPORT|WS_BORDER|LVS_ALIGNLEFT|LVS_SINGLESEL;
bool lvCreated = false ;
class ListView : Control {
    this(Window parent, int x, int y, int w, int h) {   
        if (!lvCreated) {
            lvCreated = true;
            wcLvClass = toUTF16z("SysListView32");
            appData.iccEx.dwICC = ICC_LISTVIEW_CLASSES ;
            InitCommonControlsEx(&appData.iccEx);
        }
        mWidth = w ;
        mHeight = h ;
        mXpos = x ;
        mYpos = y ;
        mParent = parent ;
        mFont = parent.font ;        
        mControlType = ControlType.listView ;
        mLvStyle = ListViewStyle.report;
        mShowGridLines = true ; 
        mFullRowSel = true;        
        mStyle = lvStyle  ;
        mExStyle = 0 ;         
        mBackColor = defBackColor ;
        mForeColor = defForeColor;
        mBClrRef = getClrRef(defBackColor) ;
        mFClrRef = getClrRef(this.mForeColor) ;
        mClsName = wcLvClass ; 
        //mImgList = new ImageList() ;
        ++lvNumber; 
                  
    }

    this(Window parent) { this(parent, 20, 20, 180, 200) ; }
    this(Window parent, int x, int y) { this(parent, x, y, 180, 200);}


    final void create() {
    	this.adjustLVStyles() ;        
        this.createHandle();    
        if (this.mHandle) {                   
            this.setSubClass(&lvWndProc) ;             
            this.setLvExStyles();             
            if (this.mLvStyle == ListViewStyle.tile) this.sendMsg(LVM_SETVIEW, 0x0004, 0);            
           
            // Chances are there to user adds columns before LV is creating.
            // In such cases, we need to add those columns right after creation.
            if (this.mCIList.length > 0) {                
                foreach (ci; this.mCIList) {
                    this.sendMsg(LVM_INSERTCOLUMNW, ci.index, &ci.lvc);
                }
            }
                           
        }        
    }

    

    final void addColumn(ListViewColumn lvc) { this.addColumnInternal(lvc);}    

    final void addColumn(string text) { 
        auto lvc = new ListViewColumn(text);
        this.addColumnInternal(lvc);
    }

    final void addColumn(string text, int width) { 
        auto lvc = new ListViewColumn(text, width);
        this.addColumnInternal(lvc);
    }

    final void addColumn(string text, int width, int imgIndx, ColumnAlignment colAlign = ColumnAlignment.left ) { 
        auto lvc = new ListViewColumn(text, width, imgIndx);
        this.addColumnInternal(lvc);
    }

    
    /// Adds a row of items to listview. Only for Report view. 
    void addRow(T...)(T items) {
        if (this.mLvStyle != ListViewStyle.report || !this.mIsCreated) return;
        auto iLen = items.length;
        auto lvItem = new ListViewItem(items[0].toString);   
        this.addItemInternal(lvItem);     
        for (int i = 1; i < iLen; ++i) {            
            auto sItem = items[i].toString();
            this.addSubItemInternal(sItem, lvItem.index, i);
        }
    }

    /// Adds an item to list view.
    void addItem(T)(T item, int imgIndx = -1) {
        if (this.mIsCreated) {
            auto lvItem = new ListViewItem(item.toString, imgIndx);   
            this.addItemInternal(lvItem);  
        } 
    }

    /// Adds an item to list view.
    void addItem(ListViewItem item) {
        if (this.mIsCreated) this.addItemInternal(item);   
    }

    /// Add sub items to an item at given index. Works only report view.
    void addSubItems(T...)(int itemIndex, T subItems) {
        if (this.mIsCreated && this.mLvStyle == ListViewStyle.report) {
            int subIndx = 1;
            foreach (item; subItems) {
                auto sItem = item.toString;
                this.addSubItemInternal(sItem, itemIndex, subIndx);
                ++subIndx;
            }
        }
    }

    void addSubItem(T)(T subItem, int itemIndex, int subIndx, int imgIndx = -1) {
        if (this.mIsCreated && this.mLvStyle == ListViewStyle.report) {
            this.addSubItemInternal(subItem.toString, itemIndex, subIndx, imgIndx );           
        }
    }

    /// Set the image list for list view.
    final void setImageList(ImageList img, ImageType imgTyp = ImageType.smallImage) { 
        if (this.mIsCreated) this.sendMsg(LVM_SETIMAGELIST, imgTyp, img.handle);       
    }

    /// Sets the left to right order of columns
    final void setColumnOrder(int[] ordList...) {
        if (this.mIsCreated) {
            this.sendMsg(LVM_SETCOLUMNORDERARRAY, ordList.length, ordList.ptr);
        }
    }

    // Property section

    final bool alignItemTop() {return this.mitemTopAlign;}
    final void alignItemTop(bool value) {this.mitemTopAlign = value;}

    final bool hideSelection() {return this.mHideSel;}
    final void hideSelection(bool value) {this.mHideSel = value;}

    final bool multiSelection() {return this.mMultiSel;}
    final void multiSelection(bool value) {this.mMultiSel = value;}

    final bool fullRowSelection() {return this.mFullRowSel;}
    final void fullRowSelection(bool value) {this.mFullRowSel = value;}

    final bool hasCheckBox() {return this.mHasCheckBox;}
    final void hasCheckBox(bool value) {this.mHasCheckBox = value;}

    final bool showGridLines() {return this.mShowGridLines;}
    final void showGridLines(bool value) {this.mShowGridLines = value;}

    final bool oneClickActivate() {return this.mOneClickAct;}
    final void oneClickActivate(bool value) {this.mOneClickAct = value;}

    final bool hotTrackSelection() {return this.mHotTrackSel;}
    final void hotTrackSelection(bool value) {this.mHotTrackSel = value;}

    final bool editLabel() {return this.mEditLabel;}
    final void editLabel(bool value) {this.mEditLabel = value;}

    final bool noHeaders() {return this.mNoHeader;}
    final void noHeaders(bool value) {this.mNoHeader = value;}

    final ListViewStyle viewStyle() {return this.mLvStyle;}
    final void viewStyle(ListViewStyle value) {this.mLvStyle = value;}

    private :
        bool mitemTopAlign;
        bool mHideSel;
        bool mMultiSel;
        bool mHasCheckBox;
        bool mFullRowSel;
        bool mShowGridLines;
        bool mOneClickAct;
        bool mHotTrackSel;
        bool mEditLabel;
        bool mNoHeader;

        ColumnAlignment mColAlign;
        ListViewStyle mLvStyle;

        ListViewColumn[] mColumns;
        ListViewItem[] mItems;
        ColAndIndex[] mCIList; 

        int mColIndex ;
        ImageList mImgList;

        void addColumnInternal(ListViewColumn lvCol) { // Private
            LVCOLUMNW lvc ;
            lvc.mask = LVCF_FMT | LVCF_TEXT  | LVCF_WIDTH ;// | LVCF_SUBITEM | LVCF_ORDER;
            lvc.fmt = lvCol.alignment;
            lvc.cx = lvCol.width;
            lvc.pszText = lvCol.text.toWchrPtr;

            if (lvCol.hasImage) {
                lvc.mask |= LVCF_IMAGE;
                lvc.fmt |= LVCFMT_COL_HAS_IMAGES | LVCFMT_IMAGE ;
                lvc.iImage = lvCol.imageIndex;        
                if (lvCol.imageOnRight) lvc.fmt |= LVCFMT_BITMAP_ON_RIGHT ;        
            }
            
            if (this.mIsCreated) {
                this.sendMsg(LVM_INSERTCOLUMNW, lvCol.index, &lvc);
            } else {
                // We need to collect this info in mCIList.
                // This list contains LVCOLUMNW struct and index of the column.
                this.mCIList ~= ColAndIndex(lvCol.index, lvc);
            }
            this.mColumns ~= lvCol ;
            
        }

        void addItemInternal(ListViewItem item) { // Private
            LVITEMW lvi;
            lvi.mask = LVIF_TEXT | LVIF_PARAM | LVIF_STATE;
            if (item.imageIndex != -1) lvi.mask |= LVIF_IMAGE;
            lvi.state = 0;
            lvi.stateMask = 0;
            lvi.iItem = item.index;
            lvi.iSubItem = 0;
            lvi.iImage = item.imageIndex;
            lvi.pszText = item.text.toWchrPtr;
            lvi.cchTextMax = item.text.length;
            lvi.lParam = cast(LPARAM) &item;
            this.sendMsg(LVM_INSERTITEMW, 0, &lvi);
        }  

        void addSubItemInternal(string sItem, int itemIndx, int subIndx, int imgIndx = -1) {
            LVITEMW lw ;
            lw.iSubItem = subIndx;
            lw.pszText = sItem.toWchrPtr;
            lw.iImage = imgIndx;
            this.sendMsg(LVM_SETITEMTEXT, itemIndx, &lw);
        }     

        void adjustLVStyles() { // Private
            switch (this.mLvStyle) {
                case ListViewStyle.largeIcon : 
                    this.mStyle |= LVS_ICON;
                    break;
                case ListViewStyle.report :
                    this.mStyle |= LVS_REPORT;
                    break;
                case ListViewStyle.smallIcon :
                    this.mStyle |= LVS_SMALLICON;
                    break;
                case ListViewStyle.list :
                    this.mStyle |= LVS_LIST; 
                    break;
                default : break;
            }
            if (this.mEditLabel) this.mStyle |= LVS_EDITLABELS;
            if (this.mHideSel) this.mStyle |= LVS_SHOWSELALWAYS;
            if (this.mNoHeader) this.mStyle |= LVS_NOCOLUMNHEADER;
        }

        void setLvExStyles() { // Private
            DWORD lvExStyle ;
            if (this.mShowGridLines) lvExStyle |= LVS_EX_GRIDLINES;
            if (this.mHasCheckBox) lvExStyle |= LVS_EX_CHECKBOXES;
            if (this.mFullRowSel) lvExStyle |= LVS_EX_FULLROWSELECT;
            if (this.mOneClickAct) lvExStyle |= LVS_EX_ONECLICKACTIVATE;
            if (this.mHotTrackSel) lvExStyle |= LVS_EX_TRACKSELECT;
            this.sendMsg(LVM_SETEXTENDEDLISTVIEWSTYLE, 0, lvExStyle);
        }

       


} // End of class ListView

class ListViewColumn {
    this(string header, int width, int img = -1, bool imgRight = false) 
    {
        this.mText  = header;
        this.mWidth = width;        
        this.mColAlign = ColumnAlignment.left;
        this.mIndex = mIndexNum;
        this.mImgIndex = img;
        this.mImgOnRight = imgRight;  
           
        ++mIndexNum;
        
    }
    
    this(string header) {this(header, 100);}

    final string text() {return this.mText;}
    final void text(string value) {this.mText = value;}
    
    final int width() {return this.mWidth;}
    final void width(int value) {this.mWidth = value;}

    final int imageIndex() {return this.mImgIndex;}
    final void imageIndex(int value) {this.mImgIndex = value;}

    final ColumnAlignment alignment() {return this.mColAlign;}
    final void alignment(ColumnAlignment value) {this.mColAlign = value;}    

    final bool imageOnRight() {return this.mImgOnRight;}
    final void imageOnRight(bool value) {this.mImgOnRight = value;}

    final int index() {return this.mIndex;}
    final bool hasImage() {return (this.mImgIndex > -1) ? true : false;}

    
    private :
        string mText;
        int mWidth;
        int mIndex;
        int mImgIndex = -1 ;
        int mOrder;
        //bool mHasImg;
        bool mImgOnRight;
        ColumnAlignment mColAlign;
        //static mOrderNum = 1;
        static mIndexNum = 0;
}

class ListViewItem {

    this(string txt, uint bgc, uint fgc, int img = -1) 
    {
        this.mText = txt;
        this.mBkClr = bgc;
        this.mFrClr = fgc;
        this.mImgIndex = img;
        this.mIndex = mStIndex;
        ++mStIndex;
    }

    this(string txt, int img) { this(txt, defBackColor, defForeColor, img ); }
    this(string txt) { this(txt, defBackColor, defForeColor, -1); }

    final int imageIndex() {return this.mImgIndex;}
    final void imageIndex(int value) {this.mImgIndex = value;}    
    
    final string text() {return this.mText;}
    final void text(string value) {this.mText = value;}

    final uint backColor() {return this.mBkClr;}
    final void backColor(uint value) {this.mBkClr = value;}

    final uint foreColor() {return this.mFrClr;}
    final void foreColor(uint value) {this.mFrClr = value;}

    final Font font() {return this.mFont;}
    final void font(Font value) {this.mFont = value;}

    final int index() {return this.mIndex;}    
    
    private :
        int mIndex;
        int mImgIndex;       
        uint mBkClr;
        uint mFrClr;
        Font mFont;
        string mText;
        string[] mSubItems;

        static int mStIndex ;
        
}

// class ListViewSubItem {
//     string mText;
//     Font mFont;
//     uint mBkClr;
//     uint mFrClr;

// }

struct ColAndIndex {
    int index ;
    LVCOLUMNW lvc;
}


extern(Windows)
private LRESULT lvWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData)  {
    try {   
        ListView lv = getControl!ListView(refData)  ;
        switch (message) {
            case WM_DESTROY :
               // lv.finalize ;
                lv.remSubClass(scID);
                break ;
            default : return DefSubclassProc(hWnd, message, wParam, lParam) ;
        }
        
    }
    catch (Exception e) {}     
    return DefSubclassProc(hWnd, message, wParam, lParam);
}



