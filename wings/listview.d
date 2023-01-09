module wings.listview; // Created on : 01-Jun-22 11:26:46 AM


import std.conv ;
import std.algorithm ;
import wings.d_essentials;
import wings.wings_essentials;
import wings.imagelist ;

//----------------------------------------------------

int bottomClrAdj = 11;

int lvNumber = 1 ;
wstring wcLvClass ;
DWORD lvStyle = WS_VISIBLE|WS_CHILD|WS_CLIPCHILDREN|WS_CLIPSIBLINGS|LVS_REPORT|WS_BORDER|LVS_ALIGNLEFT|LVS_SINGLESEL;
bool lvCreated = false ;
enum DWORD HDN_FILTERCHANGE = HDN_FIRST - 12;
enum DWORD HDI_STATE =  0x0200;

DWORD mTxtFlag = DT_SINGLELINE | DT_VCENTER | DT_CENTER | DT_NOPREFIX;
enum DWORD txtFlag = DT_SINGLELINE | DT_VCENTER | DT_NOPREFIX;


class ListView : Control {
    this(Window parent, int x, int y, int w, int h) {
        if (!lvCreated) {
            lvCreated = true;
            wcLvClass = "SysListView32";
            appData.iccEx.dwICC = ICC_LISTVIEW_CLASSES ;
            InitCommonControlsEx(&appData.iccEx);
        }

        mixin(repeatingCode);
        mControlType = ControlType.listView ;
        mLvStyle = ListViewStyle.report;
        mShowGridLines = true ;
        mFullRowSel = true;
        mStyle = lvStyle  ;
        mExStyle = 0 ;
        mBackColor(defBackColor) ;
        mForeColor(defForeColor);
        mHdrBackColor(0x80b3ff); 
        mHdrForeColor(0x000000);   
        mClsName = wcLvClass ;
        mHdrFont = parent.font;
        this.mName = format("%s_%d", "ListView_", lvNumber);
        ++lvNumber;

    }

    this(Window parent) { this(parent, 20, 20, 250, 200) ; }
    this(Window parent, int x, int y) { this(parent, x, y, 250, 200);}


    final void create() {
    	this.adjustLVStyles() ;        
        this.createHandle();
        if (this.mHandle) {
            this.setSubClass(&lvWndProc) ;
            this.setLvExStyles();
            if (this.mLvStyle == ListViewStyle.tile) this.sendMsg(LVM_SETVIEW, 0x0004, 0);

            /+  Chances are there to user adds columns before LV is created.
                In such cases, we need to add those columns right after creation.+/
            if (this.mCIList.length > 0) {
                foreach (ci; this.mCIList) {
                    this.sendMsg(LVM_INSERTCOLUMNW, ci.index, &ci.lvc);
                }
            }

            this.hwHeader = ListView_GetHeader(this.mHandle)  ;
            SetWindowSubclass(this.hwHeader, &hdrWndProc, UINT_PTR(Control.mSubClassId), this.toDwPtr());
            ++Control.mSubClassId ;
            if (this.mBackColor.value != defBackColor) ListView_SetBkColor(this.mHandle, this.mBackColor.reff);
            if (this.mSetCbLast) {
                auto ordList = changeColumnOrder();
                this.sendMsg(LVM_SETCOLUMNORDERARRAY, ordList.length, ordList.ptr);
                this.mCbisLast = true;
            }

        }
    }

    // Methods
        final bool checked() {return this.mChecked;} /// Chacked state of the checkbox.
        final void addColumn(ListViewColumn lvc) { this.addColumnInternal(lvc);}

        final void addColumn(string text) {
            auto lvc = new ListViewColumn(text);
            this.addColumnInternal(lvc);
        }

        final void addColumn(string text, int width) {
            auto lvc = new ListViewColumn(text, width);
            this.addColumnInternal(lvc);
        }

        final void addColumn(string text, int width, int imgIndx ) {
            auto lvc = new ListViewColumn(text, width, imgIndx);
            this.addColumnInternal(lvc);
        }


        /// Set the back color for header. Use headerCurve for adjust the curvy look.
        final void headerBackColor(uint value) {
            this.mHdrBackColor(value);
            this.checkRedrawNeeded();
        }

        /// Set fore color for header
        final void headerForeColor(uint value) {
            this.mHdrForeColor(value);
            this.checkRedrawNeeded();
        }

        /// Set header font.
        final void headerFont(Font value) {
            this.mHdrFont = value;
            this.mHdrDrawFont = true;
            if (value.handle == null) this.mHdrFont.createFontHandle();
            this.checkRedrawNeeded();
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

        /// Add bulk of items to listiview.
        void addItems(string[] items...) {
            if (this.mLvStyle != ListViewStyle.report || !this.mIsCreated) return;
            auto iLen = items.length;
            auto lvItem = new ListViewItem(items[0]);
            this.addItemInternal(lvItem);
            for (int i = 1; i < iLen; ++i) {
                this.addSubItemInternal(items[i], lvItem.index, i);
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

        /// Add subitem to listview.
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

        final void checkBoxColumnLast() {
            if (!this.mHasCheckBox) this.mHasCheckBox = true;
            if (mColumns.length > 0 ) { // There are some columns
                if (this.mIsCreated) {
                    auto ordList = changeColumnOrder();
                    this.sendMsg(LVM_SETCOLUMNORDERARRAY, ordList.length, ordList.ptr);
                    this.mCbisLast = true;
                } else {
                    this.mSetCbLast = true;
                }
           } else {
                this.mSetCbLast = true;
           }
        }

        /// Enable viual styles for header. Otherwise, color & font won't changes.
        final void enableHeaderVisualStyle() {
            if (this.mColumns.length > 0 ) {
                MyHdItem hdi ;
                foreach (col; this.mColumns) {
                    hdi.mask = HDI_FORMAT ;
                    hdi.fmt = HDF_OWNERDRAW;
                    SendMessage(hwHeader, HDM_SETITEM, WPARAM(col.index), cast(LPARAM) &hdi);
                }
            }

        }

        /// Set the height of header.
        final void headerHeight(int value) {
            this.mChangeHdrHeight = true;
            this.mHdrHeight = value;
            this.checkRedrawNeeded();
        }

        final bool hasCheckBox() {return this.mHasCheckBox;}
        final void hasCheckBox(bool value) {
            this.mHasCheckBox = value;
            if (this.mIsCreated) {
                print("Can't create checkboxes after ListView created");
            }
        }


    // Property section
        /// Set flat color header for this ListView
        // final void flatHeader(bool value) {this.mFlatHdr = value;}
        // /// Get flatHeader value is set or not.
        // final bool flatHeader() {return this.mFlatHdr;}
        //mixin finalProperty!("flatHeader", this.mFlatHdr);

        ///// Set the curve look for header. 12 is default.
        //final void headerCurve(int value) {
        //    if (this.mHdrColors.isBcOkay) {
        //        // Means, back color is already set. We need to re-set it.
        //        this.mHdrColors.changeCurveValue(value);
        //    } else {
        //        this.mHdrColors.mCurveValue = value;
        //    }
        //}
        ///// Get the header curve value.
        //final int headerCurve() {return this.mHdrColors.mCurveValue;}

        /// When mouse enteres, header color will change from main color with this value.
        //final void headerHoverColorShade(int value) {
        //    if (this.mHdrColors.isBcOkay) {
        //        // Means, back color is already set. We need to re-set it.
        //        this.mHdrColors.changeLightShadeValue(value);
        //    } else {
        //        this.mHdrColors.mLightShadeValue = value;
        //    }
        //}

        final override void backColor(uint value) {
            this.mBackColor(value);
            if (this.mIsCreated) ListView_SetBkColor(this.mHandle,this.mBackColor.reff );
        }
        final override uint backColor() {return this.mBackColor.value;}

        // final int selectedIndex() {return this.mSelIndex;}
        // final ListViewItem selectedItem() {return this.mSelItem;}
        mixin finalProperty!("selectedIndex", this.mSelIndex);
        //final void alignItemTop(bool value) {this.mitemTopAlign = value;}

        final ListViewColumn[] columns() {return this.mColumns;}

        // final bool alignItemTop() {return this.mitemTopAlign;}
        // final void alignItemTop(bool value) {this.mitemTopAlign = value;}
        mixin finalProperty!("alignItemTop", this.mitemTopAlign);

        // final bool hideSelection() {return this.mHideSel;}
        // final void hideSelection(bool value) {this.mHideSel = value;}
        mixin finalProperty!("hideSelection", this.mHideSel);

        // final bool multiSelection() {return this.mMultiSel;}
        // final void multiSelection(bool value) {this.mMultiSel = value;}
        mixin finalProperty!("multiSelection", this.mMultiSel);

        // final bool fullRowSelection() {return this.mFullRowSel;}
        // final void fullRowSelection(bool value) {this.mFullRowSel = value;}
        mixin finalProperty!("fullRowSelection", this.mFullRowSel);

        // final bool hasCheckBox() {return this.mHasCheckBox;}
        // final void hasCheckBox(bool value) {this.mHasCheckBox = value;}
        mixin finalProperty!("hasCheckBox", this.mHasCheckBox);

        // final bool showGridLines() {return this.mShowGridLines;}
        // final void showGridLines(bool value) {this.mShowGridLines = value;}
        mixin finalProperty!("showGridLines", this.mShowGridLines);

        // final bool oneClickActivate() {return this.mOneClickAct;}
        // final void oneClickActivate(bool value) {this.mOneClickAct = value;}
        mixin finalProperty!("oneClickActivate", this.mOneClickAct);

        // final bool hotTrackSelection() {return this.mHotTrackSel;}
        // final void hotTrackSelection(bool value) {this.mHotTrackSel = value;}
        mixin finalProperty!("hotTrackSelection", this.mHotTrackSel);

        // final bool editLabel() {return this.mEditLabel;}
        // final void editLabel(bool value) {this.mEditLabel = value;}
        mixin finalProperty!("editLabel", this.mEditLabel);

        // final bool noHeaders() {return this.mNoHeader;}
        // final void noHeaders(bool value) {this.mNoHeader = value;}
        mixin finalProperty!("noHeaders", this.mNoHeader);

        // final ListViewStyle viewStyle() {return this.mLvStyle;}
        // final void viewStyle(ListViewStyle value) {this.mLvStyle = value;}
        mixin finalProperty!("viewStyle", this.mLvStyle);

        final void deleteItem(int index) {
            if (this.mIsCreated && this.mItems.length > 0) {
                this.sendMsg(LVM_DELETEITEM, index, 0);
                // TODO delete from mItems
            }
        }

    // Event section
    EventHandler onSelectionChanged, onCheckedChanged, onItemClicked, onItemDblClicked, onItemHover;

    package :
        int mSelIndex = -1;
        ListViewItem mSelItem;
        bool mEditLabel;
        bool mDrawHeader; // Need this to check in WM_NOTIFY msg // TODO - Rename this.

        HWND hwLabel;
        HWND hwHeader;



        void finalize() {
            if (this.mHdrBkBrushTop != null) DeleteObject(this.mHdrBkBrushTop);
            if (this.mHdrBkBrushBot != null) DeleteObject(this.mHdrBkBrushBot);
        }

        // void finalizeHeader(UINT_PTR subClsId) {
        //     RemoveWindowSubclass(this.mHandle, this.wndProcPtr, subClsId);
        // }




    private :
        // Variables
            bool mitemTopAlign;
            bool mHideSel;
            bool mMultiSel;
            bool mHasCheckBox;
            bool mFullRowSel;
            bool mShowGridLines;
            bool mOneClickAct;
            bool mHotTrackSel;
            bool mNoHeader;
            bool mChangeHdrHeight;
            bool mHdrDrawFont;
            bool mFlatHdr;
            bool mSetCbLast;
            bool mCbisLast;
            bool mChecked;
            bool mMouseOnHdr;
            bool mHdrClickable = true;
            Font mHdrFont;

            
            HBRUSH mHdrBkBrushTop;
            HBRUSH mHdrBkBrushBot;
            HBRUSH mHdrDefBkBrush;
            HBRUSH mHdrHotBkBrush;
            Alignment mColAlign;
            ListViewStyle mLvStyle;
            ListViewColumn[] mColumns;
            ListViewItem[] mItems;
            ColAndIndex[] mCIList;
            int mColIndex ;
            int mOldHotHdrIndx = -1;
            int mHdrHeight;
            int mSelItemIndx;
            int mSelSubIndx;

            Color mHdrBackColor;
            Color mHdrForeColor;


            ImageList mImgList;
            POINT mHdrMousePoint;

        // End of Variables.

        int[] changeColumnOrder() {
            int[] indices;
            foreach (lc; this.mColumns) {if (lc.index > 0) indices ~= lc.index;}
            indices ~= 0;
            return indices;
        }



        void addColumnInternal(ListViewColumn lvCol) { // Private
            LVCOLUMNW lvc ;
            lvc.mask = LVCF_FMT | LVCF_TEXT  | LVCF_WIDTH  | LVCF_SUBITEM ;//| LVCF_ORDER;
            lvc.fmt = lvCol.alignment;
            lvc.cx = lvCol.width;
            lvc.pszText = cast(wchar*) lvCol.text.toUTF16z;

            if (lvCol.hasImage) {
                lvc.mask |= LVCF_IMAGE;
                lvc.fmt |= LVCFMT_COL_HAS_IMAGES | LVCFMT_IMAGE ;
                lvc.iImage = lvCol.imageIndex;
                if (lvCol.imageOnRight) lvc.fmt |= LVCFMT_BITMAP_ON_RIGHT ;
            }

            if (this.mIsCreated) {
                this.sendMsg(LVM_INSERTCOLUMNW, lvCol.index, &lvc);
                // We need this to do the painting in wm notify.
               // if (!this.mDrawColumns && lvCol.mDrawNeeded) this.mDrawColumns = true;
            } else {
                // We need to collect this info in mCIList.
                // This list contains LVCOLUMNW struct and index of the column.
                // We can insert these items right after we create the lv handle.
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
            lvi.pszText = cast(wchar*) item.text.toUTF16z;
            lvi.cchTextMax = cast(int)item.text.length;
            lvi.lParam = cast(LPARAM) &item;
            this.sendMsg(LVM_INSERTITEMW, 0, &lvi);
            this.mItems ~= item;
        }

        void addSubItemInternal(string sItem, int itemIndx, int subIndx, int imgIndx = -1) {
            LVITEMW lw ;
            lw.iSubItem = subIndx;
            auto x = sItem.toUTF16z;
            lw.pszText =cast(LPWSTR) x;
            lw.iImage = imgIndx;
            this.sendMsg(LVM_SETITEMTEXT, itemIndx, &lw);
            this.mItems[itemIndx].addSubItem(sItem);
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

            // Set some more styles...
            if (this.mEditLabel) this.mStyle |= LVS_EDITLABELS;
            if (this.mHideSel) this.mStyle |= LVS_SHOWSELALWAYS;
            if (this.mNoHeader) this.mStyle |= LVS_NOCOLUMNHEADER;
            if (this.mMultiSel) this.mStyle ^= LVS_SINGLESEL;

            // Set some brushes for coloring.
            this.mHdrDefBkBrush = CreateSolidBrush(this.mHdrBackColor.reff);
            this.mHdrHotBkBrush = this.mHdrBackColor.getHotBrush(1.2);
        }

        // Set some EX styles...
        void setLvExStyles() { // Private
            DWORD lvExStyle ;
            if (this.mShowGridLines) lvExStyle |= LVS_EX_GRIDLINES;
            if (this.mHasCheckBox) lvExStyle |= LVS_EX_CHECKBOXES;
            if (this.mFullRowSel && !this.mEditLabel) lvExStyle |= LVS_EX_FULLROWSELECT;
            if (this.mOneClickAct) lvExStyle |= LVS_EX_ONECLICKACTIVATE;
            if (this.mHotTrackSel) lvExStyle |= LVS_EX_TRACKSELECT;
            this.sendMsg(LVM_SETEXTENDEDLISTVIEWSTYLE, 0, lvExStyle);
        }        


        DWORD headerCustomDraw(NMCUSTOMDRAW* nmcd) {
            /* We need colors in header's background & foreground.
             * But there are two ways to achieve that. Owner draw & Custom draw.
             * It seems to me that custom draw is pretty easy and simple.
             */
            auto col = this.mColumns[nmcd.dwItemSpec];
            SetBkMode(nmcd.hdc, TRANSPARENT);
            if (col.index > 0) nmcd.rc.left += 1;
            if (this.mHdrClickable) {
                if (nmcd.uItemState & CDIS_SELECTED) { 
                    // Header is clicked. So we will change the back color.               
                    FillRect(nmcd.hdc, &nmcd.rc, this.mHdrDefBkBrush);
                } else {            
                    if (this.mMouseOnHdr && PtInRect(&nmcd.rc, this.mHdrMousePoint)) { 
                        // Mouse pointer is on header. So we will change the back color.               
                        FillRect(nmcd.hdc, &nmcd.rc, this.mHdrHotBkBrush);
                    } else {
                        FillRect(nmcd.hdc, &nmcd.rc, this.mHdrDefBkBrush);
                    }
                }
                
                if (nmcd.uItemState & CDIS_SELECTED) {
                    /* Here we are mimicing dot net's same technique.
                     * We will change the rect's left and top a little bit when header got clicked.
                     * So user will feel the header is pressed. */
                    nmcd.rc.left += 2;
                    nmcd.rc.top += 2;
                }
            } else {
                FillRect(nmcd.hdc, &nmcd.rc, this.mHdrDefBkBrush);
            }

            SelectObject(nmcd.hdc, this.mHdrFont.handle);
            SetTextColor(nmcd.hdc, this.mHdrForeColor.reff);            
            DrawText(nmcd.hdc, col.text.toUTF16z, -1, &nmcd.rc, col.mHdrTxtFlag ) ;
            return CDRF_SKIPDEFAULT;
        }

        void setHdrMouseLeave() {foreach (col1; mColumns) col1.mIsHotItem = false;}






} // End of class ListView

class ListViewColumn {
    this(string header, int width, int img = -1, bool imgRight = false)
    {
        this.mText  = header;
        this.mWidth = width;
        this.mColAlign = Alignment.left;
        this.mIndex = mIndexNum;
        this.mImgIndex = img;
        this.mImgOnRight = imgRight;
        this.mHdrTxtAlign = Alignment.left;
        this.mHdrTxtFlag = DT_SINGLELINE | DT_VCENTER | DT_CENTER | DT_NOPREFIX;
        ++mIndexNum;
    }

    this() {}

    this(string header) {this(header, 100);}

    mixin finalProperty!("text", this.mText);
    mixin finalProperty!("width", this.mWidth);
    mixin finalProperty!("imageIndex", this.mImgIndex);
    mixin finalProperty!("alignment", this.mColAlign);

    final Alignment headerAlign() {return this.mHdrTxtAlign;}
    final void headerAlign(Alignment value) {
        this.mHdrTxtAlign = value;
        switch (value) {
            case Alignment.left:
                this.mHdrTxtFlag |= DT_SINGLELINE | DT_VCENTER | DT_LEFT | DT_NOPREFIX;
            break;
            case Alignment.center:
                this.mHdrTxtFlag |= DT_SINGLELINE | DT_VCENTER | DT_CENTER | DT_NOPREFIX;
            break;
            case Alignment.right:
                this.mHdrTxtFlag |= DT_SINGLELINE | DT_VCENTER | DT_RIGHT | DT_NOPREFIX;
            break;
            default: break;
        }
    }


    mixin finalProperty!("imageOnRight", this.mImgOnRight);
    final int index() {return this.mIndex;}
    final bool hasImage() {return (this.mImgIndex > -1) ? true : false;}

    package :
        bool mDrawNeeded;
        bool mIsHotItem ;

    private :
        string mText;
        int mWidth;
        int mIndex;
        int mImgIndex = -1 ;
        int mOrder;

        Color mBackColor;
        Color mForeColor;
        bool mImgOnRight;

        Alignment mColAlign;
        Alignment mHdrTxtAlign;
        DWORD mHdrTxtFlag;
        static mIndexNum = 0;

} // End of ListViewColumn class


class ListViewItem {

    this(string txt, uint bgc, uint fgc, int img = -1)
    {
        this.mText = txt;
        this.mBkClr(bgc);
        this.mFrClr(fgc);
        this.mImgIndex = img;
        this.mIndex = mStIndex;
        ++mStIndex;
    }

    this(string txt, int img) { this(txt, defBackColor, defForeColor, img ); }
    this(string txt) { this(txt, defBackColor, defForeColor, -1); }


    mixin finalProperty!("imageIndex", this.mImgIndex);
    mixin finalProperty!("text", this.mText);
    //mixin finalProperty!("backColor", this.mBkClr.value);     IMPORTANT:: Re-Write this as normal props
    //mixin finalProperty!("foreColor", this.mFrClr.value);
    mixin finalProperty!("font", this.mFont);

    final int index() {return this.mIndex;}
    final void addSubItem(string subItm) { this.mSubItems ~= subItm; }
    final string[] subItems() {return this.mSubItems;}

    private :
        int mIndex;
        int mImgIndex;
        Color mBkClr;
        Color mFrClr;
        Font mFont;
        string mText;
        string[] mSubItems;

        static int mStIndex ;

} // ListViewItem class



struct MyHdItem {
    uint    mask;
    int     cxy;
    LPWSTR  pszText;
    HBITMAP hbm;
    int     cchTextMax;
    int     fmt;
    LPARAM  lParam;
    int     iImage;
    int     iOrder;
    uint    type;
    void*   pvFilter;
    uint    state;
}

struct HeaderRects {
    RECT rct;
    int headerIndex;
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

enum LVN_HOTTRACK = LVN_FIRST - 21;
extern(Windows)
private LRESULT lvWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData)  {
    try {
        ListView lv = getControl!ListView(refData)  ;
        //printWinMsg(message);
        switch (message) {
            case WM_DESTROY :
               // lv.finalize ;
                lv.remSubClass(scID);
            break ;

            case WM_PAINT : lv.paintHandler(); break;
            case WM_SETFOCUS : lv.setFocusHandler(); break;
            case WM_KILLFOCUS : lv.killFocusHandler(); break;
            case WM_LBUTTONDOWN : lv.mouseDownHandler(message, wParam, lParam); break ;
            case WM_LBUTTONUP : lv.mouseUpHandler(message, wParam, lParam); break ;
            case CM_LEFTCLICK : lv.mouseClickHandler(); break;
            case WM_RBUTTONDOWN : lv.mouseRDownHandler(message, wParam, lParam); break;
            case WM_RBUTTONUP : lv.mouseRUpHandler(message, wParam, lParam); break;
            case CM_RIGHTCLICK : lv.mouseRClickHandler(); break;
            case WM_MOUSEWHEEL : lv.mouseWheelHandler(message, wParam, lParam); break;
            case WM_MOUSEMOVE : lv.mouseMoveHandler(message, wParam, lParam); break;
            case WM_MOUSELEAVE : lv.mouseLeaveHandler(); break;

            //case WM_DRAWITEM :  // This is coming from child controls( aka Header)
            //    auto pdi = cast(DRAWITEMSTRUCT*) lParam;
            //    auto col = lv.mColumns[pdi.itemID];
            //    SetBkMode(pdi.hDC, TRANSPARENT);
            //    if (pdi.itemState == 1 ) {
            //        //pdi.rcItem.top += 1;
            //        pdi.rcItem.left += 1;
            //        pdi.rcItem.bottom -= 1;
            //        pdi.rcItem.right -= 1 ;
            //    }  else {
            //        if (col.mIsHotItem) {
            //            lv.mHdrBkBrushTop = lv.mHdrColors.lightColorBrushTop;
            //            lv.mHdrBkBrushBot = lv.mHdrColors.lightColorBrushBot;
            //        } else {
            //            lv.mHdrBkBrushTop = lv.mHdrColors.backColorBrushTop;
            //            lv.mHdrBkBrushBot = lv.mHdrColors.backColorBrushBot;
            //        }
            //    }

            //    if (lv.mFlatHdr) {
            //        pdi.rcItem.left += 1;
            //        FillRect(pdi.hDC, &pdi.rcItem, lv.mHdrBkBrushTop );
            //    } else {
            //        auto topRect = lv.makeHalfSizeRect(pdi.rcItem, true) ;
            //        auto botRect = lv.makeHalfSizeRect(pdi.rcItem, false) ;
            //        FillRect(pdi.hDC, &topRect, lv.mHdrBkBrushTop );
            //        FillRect(pdi.hDC, &botRect, lv.mHdrBkBrushBot );
            //    }

            //    if (col.index > 0) {
            //        drawVLine(pdi.hDC, pdi.rcItem.left, pdi.rcItem.top, pdi.rcItem.bottom, getClrRef(Colors.white));
            //    }
            //    if (lv.mHdrDrawFont)  SelectObject(pdi.hDC, lv.mHdrFont.handle);
            //    SetTextColor(pdi.hDC, lv.mHdrColors.foreColorRef);
            //    pdi.rcItem.left += 1 ;
            //    DrawText(pdi.hDC, col.text.toUTF16z, -1, &pdi.rcItem, col.mHdrTxtFlag ) ;
            //    return trueLresult;
            //break;

            case CM_NOTIFY :
                // Windows will send this msg to parent window and parent window transfer this to here.
                auto nmhdr = cast(NMHDR*) lParam;
                //print("cm notify code", nmhdr.code);
                switch (nmhdr.code) {
                    case NM_CUSTOMDRAW :
                        auto nmLvCd = cast(NMLVCUSTOMDRAW*) lParam;
                        switch (nmLvCd.nmcd.dwDrawStage) {
                            case CDDS_PREPAINT : return CDRF_NOTIFYITEMDRAW; break;
                            case CDDS_ITEMPREPAINT :
                                nmLvCd.clrTextBk = lv.mBackColor.reff;
                                return CDRF_NEWFONT | CDRF_DODEFAULT;
                            break;
                            default : break;
                        }
                    break;
                    case LVN_ITEMCHANGING:
                    break;
                    case LVN_ITEMCHANGED:
                        auto nmlv = cast(NMLISTVIEW *) lParam;
                        if (nmlv.uNewState == 8192 || nmlv.uNewState == 4096) {
                            lv.mChecked = nmlv.uNewState == 8192 ? true : false;
                            if (lv.onCheckedChanged) {
                                auto ea = new EventArgs();
                                lv.onCheckedChanged(lv, ea);
                            }
                        } else {
                            if (nmlv.uNewState == 3) {
                                //print("this area oka");
                                lv.mSelItemIndx = nmlv.iItem;
                                lv.mSelSubIndx = nmlv.iSubItem;
                                if (lv.onSelectionChanged) {
                                    auto ea = new EventArgs();
                                    lv.onSelectionChanged(lv, ea);
                                }
                            }
                        }
                    break;
                    case NM_DBLCLK:
                        if (lv.onItemDblClicked) {
                            auto ea = new EventArgs();
                            lv.onItemDblClicked(lv, ea);
                        }
                    break;
                    case NM_CLICK:
                       // auto nmia = cast(NMITEMACTIVATE *) lParam;
                        if (lv.onItemClicked) {
                            auto ea = new EventArgs();
                            lv.onItemClicked(lv, ea);
                        }
                    break;
                    case NM_HOVER:
                        print("hover test");
                        if (lv.onItemHover) {
                            auto ea = new EventArgs();
                            lv.onItemHover(lv, ea);
                        }
                        //return 0;
                    break;
                    //case LVN_HOTTRACK : print("lvn hot track", 1); break;
                    /++case NM_RELEASEDCAPTURE  :
                       print("LVN_ITEMCHANGED", 12); break;
                    case NM_CLICK :
                        // lv.mSelIndex = lv.sendMsg(LVM_GETNEXTITEM, -1, LVNI_SELECTED);
                        // lv.mSelItem = lv.mItems[lv.mSelIndex];
                        // if (lv.onSelectionChanged) {
                        //     auto ea = new EventArgs();
                        //     lv.onSelectionChanged(lv, ea);
                        // }
                        // break;

                    case LVN_BEGINLABELEDITW :
                        lv.hwLabel = ListView_GetEditControl(lv.mHandle);
                        //return cast(LRESULT) false;
                        break;

                    case LVN_COLUMNCLICK :
                        // Implement column click event here.

                    case LVN_ENDLABELEDITW :
                        if (lv.mEditLabel) {
                           // print("label edit ok");
                        }
                        return trueLresult;
                        break;+/

                    default : break;
                } break;

            case WM_NOTIFY: // This msg is coming from Header control.
                 auto nmh= cast(NMHDR*) lParam;
                // auto nmlist = cast(NMLISTVIEW*) lParam;
                // //print("nmcd.code", nmcd.code);

                // if (nmcd.code == LVN_ITEMCHANGED) {
                //     print("item changed");
                //     if (nmlist.uNewState & LVIS_STATEIMAGEMASK)
                //     {print("cb clicked");}
                //     // ListView_SetCheckState(lv.mHandle, nmlist.iItem, 1);
                // }

                switch (nmh.code) {                    
                    case NM_CUSTOMDRAW :  // Let's draw header back & fore colors
                        auto nmcd = cast(NMCUSTOMDRAW*) lParam;
                        if (!lv.mDrawHeader) {
                            switch (nmcd.dwDrawStage) { // NM_CUSTOMDRAW is always -12 when item painting
                                case CDDS_PREPAINT :
                                    /* When drawing started, system will send a NM_CUSTOMDRAW notification to...
                                    parent of the control. Here, parent of header control is list view. So we...
                                    get the notification with WM_NOTIFY message. We returns the CDRF_NOTIFYITEMDRAW...
                                    value so that system will notify us when the pre paint stage begins for each item.*/
                                    //print("Draw Started", nmcd.lItemlParam);
                                    return CDRF_NOTIFYITEMDRAW ; break;

                                case CDDS_ITEMPREPAINT :
                                    /* So we get the notification at the pre paint statge. We can draw the header...
                                    colors, text and tell the system to not to draw anything on this header. So...
                                    system will skip the default drawing jobs. */
                                    //print("at prepaint",nmcd.dwItemSpec);
                                    return lv.headerCustomDraw(nmcd);
                                break;

                                //case CDDS_ITEMPOSTPAINT :
                                //   // lv.headerCustomDraw(nmcd);
                                //    return CDRF_NEWFONT | CDRF_DODEFAULT;
                                //    break;
                                default : break;
                            }
                        }
                        break;
                    default : /*print("other code ", nmcd.hdr.code); */ break;
                    
                }
                break;

            default : return DefSubclassProc(hWnd, message, wParam, lParam) ; break;
        }

    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

extern(Windows)
private LRESULT hdrWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData)  {
    try {
       ListView lv = getControl!ListView(refData)  ;
       //printWinMsg(message);
        switch (message) {
            case WM_DESTROY :
                RemoveWindowSubclass(hWnd, &hdrWndProc, scID);
                //print("removed hdr subcls");
            break;

            case WM_MOUSEMOVE :
                /** We need to some extra job here. Because, there is no notification
                    for a header control when mouse pointer passes upon it. So We collect
                    the mouse pointer coordinates and send the HDM_HITTEST message to header
                    control. The control will fill the iItem member of the struct. It contains
                    the item index which is under the pointer. So we can set the drawing
                    flag for that column. */
                lv.mHdrMousePoint = getMousePos(lParam);
                lv.mMouseOnHdr = true;
                InvalidateRect(hWnd, null, false);
                //HD_HITTESTINFO hinfo;
                //hinfo.pt = lv.mHdrMousePos;
                //SendMessage(hWnd, HDM_HITTEST, 0, cast(LPARAM) &hinfo);
                //auto colIndex =  hinfo.iItem;
                //if (lv.mOldHotHdrIndx > -1) {
                //    if (lv.mOldHotHdrIndx != colIndex) {
                //        lv.mColumns[colIndex].mIsHotItem = true;
                //        lv.mColumns[lv.mOldHotHdrIndx].mIsHotItem = false;
                //        lv.mOldHotHdrIndx = colIndex;
                //        InvalidateRect(hWnd, null, false);
                //    }
                //} else {
                //    if (lv.mColumns) {
                //        lv.mColumns[colIndex].mIsHotItem = true;
                //        lv.mOldHotHdrIndx = colIndex;
                //        InvalidateRect(hWnd, null, false);
                //    }
                //}
            break;

            case WM_MOUSELEAVE :
                /* When mouse leaves the header, we need to set flag as false and repaint */
                //if (lv.mOldHotHdrIndx != -1) lv.mColumns[lv.mOldHotHdrIndx].mIsHotItem = false;
                //lv.mOldHotHdrIndx = -1;
                lv.mMouseOnHdr = false;
                
            break;

            case HDM_LAYOUT :
                if (lv.mChangeHdrHeight) {
                    LPHDLAYOUT pHl = cast(LPHDLAYOUT) lParam;
                    LRESULT res = DefSubclassProc(hWnd, message, wParam, lParam);
                    WINDOWPOS* wp = pHl.pwpos;
                    wp.cy = lv.mHdrHeight;
                    return res;
                }
            break;

            default : return DefSubclassProc(hWnd, message, wParam, lParam) ;break;
        }

    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

struct tagNMLVCUSTOMDRAW {
  NMCUSTOMDRAW nmcd;
  COLORREF     clrText;
  COLORREF     clrTextBk;
  int          iSubItem;
  DWORD        dwItemType;
  COLORREF     clrFace;
  int          iIconEffect;
  int          iIconPhase;
  int          iPartId;
  int          iStateId;
  RECT         rcText;
  UINT         uAlign;
}

/** This code is keeping for future use.
    This was wrote for using in custom draw notification.
    But I realized that owner draw is better in my case.
    So I commented out this code block.

        void headerCustomDraw(NMCUSTOMDRAW* nmcd) {
            //this.mActiveHeaderRect = nmcd.rc;
            auto col = this.mColumns[nmcd.dwItemSpec];
            SetBkMode(nmcd.hdc, TRANSPARENT);
            int rctAdj1, rctAdj2;
            if (nmcd.uItemState & CDIS_SELECTED) {
                // User clicked on this header. Draw colors for a clicked header.

                rctAdj1 = -2;
                rctAdj2 = -1 ;
            } else {
                // draw default colors
                if (col.mIsHotItem == 1) {
                    this.mHdrBkBrushTop = this.mHdrColors.lightColorBrushTop;
                    this.mHdrBkBrushBot = this.mHdrColors.lightColorBrushBot;

                } else {
                    this.mHdrBkBrushTop = this.mHdrColors.backColorBrushTop;
                    this.mHdrBkBrushBot = this.mHdrColors.backColorBrushBot;
                }
                rctAdj1 = 0;
                rctAdj2 = 0 ;
            }
            auto rct = adjustRect(nmcd.rc, rctAdj1, rctAdj2);
            auto topRect = makeHalfSizeRect(rct, true) ;
            auto botRect = makeHalfSizeRect(rct, false) ;

            FillRect(nmcd.hdc, &topRect,  this.mHdrBkBrushTop );
            FillRect(nmcd.hdc, &botRect,  this.mHdrBkBrushBot );
            if (this.mHdrDrawFont)  SelectObject(nmcd.hdc, this.mHdrFont.handle);
            SetTextColor(nmcd.hdc, this.mHdrColors.foreColorRef);
            DrawText(nmcd.hdc, col.text.toUTF16z, -1, &nmcd.rc, mTxtFlag ) ;
        }


*/

void printNmLV(NMITEMACTIVATE * nm) {
    import std.stdio;
    writefln("iItem : %s", nm.iItem);
    writefln("iSubItem : %s", nm.iSubItem);
    writefln("uNewState : %s", nm.uNewState);
    writefln("uOldState : %s", nm.uOldState);
    writefln("uChanged : %s", nm.uChanged);
    writefln("ptAction : %s", nm.ptAction);
    writefln("lParam : %s", nm.lParam);
    writefln("uKeyFlags : %s", nm.uKeyFlags);

}

void printNmLV(NMLISTVIEW * nm) {
    import std.stdio;
    writefln("iItem : %s", nm.iItem);
    writefln("iSubItem : %s", nm.iSubItem);
    writefln("uNewState : %s", nm.uNewState);
    writefln("uOldState : %s", nm.uOldState);
    writefln("uChanged : %s", nm.uChanged);
    writefln("ptAction : %s", nm.ptAction);
    writefln("lParam : %s", nm.lParam);
    //writefln("uKeyFlags : %s", nm.uKeyFlags);

}