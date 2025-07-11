// Created on: 01-Jun-22 11:26:46 AM

/*==============================================ListView Docs=====================================
    Constructor:
        this(Form parent)
        this(Form parent, int x, int y)
        this(Form parent, int x, int y, int w, int h, string[] colnames = null, int[] widths = null)

	Properties:
		ListView inheriting all Control class properties	
        checked                     : bool    
        headerBackColor             : Color
        headerForeColor             : Color
        headerFont                  : Font
        checkBoxColumnLast          : bool
        enableHeaderVisualStyle     : bool
        headerHeight                : int
        hasCheckBox                 : bool
        selectedIndex               : int
        alignItemTop                : bool
        hideSelection               : bool
        multiSelection              : bool
        fullRowSelection            : bool
        hasCheckBox                 : bool
        showGridLines               : bool
        oneClickActivate            : bool
        hotTrackSelection           : bool
        editLabel                   : bool
        noHeaders                   : bool
        viewStyle                   : ListViewStyle
        headerHeight                : int
        columns                     : ListViewColumn[]
        items                       : ListViewItem[]
			
    Methods:
        createHandle
        addColumn
        addColumns
        addRow
        addItems
        addItem
        addSubItems
        addSubItem
        deleteItem
        setImageList
        setColumnOrder
        
    Events:
        All public events inherited from Control class. (See controls.d)
        EventHandler - void delegate(Control, EventArgs)
            onSelectionChanged
            onCheckedChanged
            onItemClicked
            onItemDblClicked
            onItemHover       
=============================================================================================*/


module wings.listview;

import std.stdio;
import std.conv;
import std.algorithm;
import wings.d_essentials;
import wings.wings_essentials;
import wings.imagelist;
import core.vararg;

//----------------------------------------------------

int bottomClrAdj = 11;
private wchar[] mClassName = ['S','y','s','L','i','s','t','V','i','e','w','3','2', 0];
enum DWORD lvStyle = WS_VISIBLE|WS_CHILD|WS_CLIPCHILDREN|WS_CLIPSIBLINGS|LVS_REPORT|WS_BORDER|LVS_ALIGNLEFT|LVS_SINGLESEL;
enum DWORD HDN_FILTERCHANGE = HDN_FIRST - 12;
enum DWORD HDI_STATE =  0x0200;
enum DWORD mTxtFlag = DT_SINGLELINE | DT_VCENTER | DT_CENTER | DT_NOPREFIX;
enum DWORD txtFlag = DT_SINGLELINE | DT_VCENTER | DT_NOPREFIX;
bool lvCreated = false;


class ListView: Control
{
    this(Form parent, int x, int y, int w, int h, string[] colnames = null, int[] widths = null)
    {
        if (!lvCreated) {
            lvCreated = true;
            appData.iccEx.dwICC = ICC_LISTVIEW_CLASSES;
            InitCommonControlsEx(&appData.iccEx);
        }
        mixin(repeatingCode);
        ++lvNumber;
        mControlType = ControlType.listView;
        this.mFont = new Font(parent.font);
        mLvStyle = ListViewStyle.report;
        mShowGridLines = true;
        mFullRowSel = true;
        mStyle = lvStyle;
        mExStyle = 0;
        mBackColor(0xFFFFFF);
        mForeColor(defForeColor);
        mHdrBackColor(0xb3cccc);
        mHdrForeColor(0x000000);
        mHdrFont = parent.font;
        this.mName = format("%s_%d", "ListView_", lvNumber);
        this.mParent.mControls ~= this;
        this.mCtlId = Control.stCtlId;
        ++Control.stCtlId;
        if (parent.mAutoCreate) this.createHandle();
        if ((colnames != null && widths != null) && (colnames.length == widths.length)) {
           foreach (i, name; colnames) {
                auto col = new ListViewColumn(name, widths[i]);
                this.addColumnInternal(col);
            }
        }
    }

    this(Form parent) { this(parent, 20, 20, 250, 200); }
    this(Form parent, int x, int y) { this(parent, x, y, 250, 200);}


    override void createHandle()  
    {
        this.adjustLVStyles();
        this.createHandleInternal(mClassName.ptr);
        if (this.mHandle) {
            this.setSubClass(&lvWndProc);
            this.setLvExStyles();
            if (this.mLvStyle == ListViewStyle.tile) this.sendMsg(LVM_SETVIEW, 0x0004, 0);

            /*  Chances are there to user adds columns before LV is created.
                In such cases, we need to add those columns right after creation. */
            if (this.mColumns.length > 0) {
                foreach (ci; this.mColumns) {
                    this.sendMsg(LVM_INSERTCOLUMNW, ci.index, &ci.pLvc);
                }
            }

            this.hwHeader = ListView_GetHeader(this.mHandle);
            SetWindowSubclass(this.hwHeader, &hdrWndProc, UINT_PTR(Control.mSubClassId), this.toDwPtr());
            ++Control.mSubClassId;

            if (this.mBackColor.value != defBackColor) ListView_SetBkColor(this.mHandle, this.mBackColor.cref);
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

        final void addColumn(string text)
        {
            auto lvc = new ListViewColumn(text);
            this.addColumnInternal(lvc);
        }

        final void addColumn(string text, int width)
        {
            auto lvc = new ListViewColumn(text, width);
            this.addColumnInternal(lvc);
        }

        final void addColumn(string text, int width, int imgIndx ) 
        {
            auto lvc = new ListViewColumn(text, width, imgIndx);
            this.addColumnInternal(lvc);
        }

        final void addColumns(string[] names... ) 
        {
            foreach (name; names) {
                auto lvc = new ListViewColumn(name);
                this.addColumnInternal(lvc);
            }
        }

        final void addColumns(string[] names, int[] widths ) 
        {
            if (names.length != widths.length) return;
            foreach (i, name; names) {
                auto lvc = new ListViewColumn(name, widths[i]);
                this.addColumnInternal(lvc);
            }
        }

        void addColumns(T ...)(T args )
        {
            if (args.length > 0) {
                string[] colnames;
                int[] widths;
                foreach (arg; args) {
                    auto cres = getIntOrString(arg);
                    if (cres.isString) {
                        colnames ~= cres.svalue;
                    } else {
                        widths ~= cres.ivalue;
                    }
                }
                if ((colnames.length > 0 && widths.length > 0) && (colnames.length == widths.length)) {
                    foreach (i, name; colnames) {
                        auto col = new ListViewColumn(name, widths[i]);
                        this.addColumnInternal(col);
                    }
                }
            }
        }


        /// Set the back color for header. Use headerCurve for adjust the curvy look.
        final void headerBackColor(uint value)
        {
            this.mHdrBackColor(value);
            this.checkRedrawNeeded();
        }

        /// Set fore color for header
        final void headerForeColor(uint value)
        {
            this.mHdrForeColor(value);
            this.checkRedrawNeeded();
        }

        /// Set header font.
        final void headerFont(Font value)
        {
            this.mHdrFont = value;
            this.mHdrDrawFont = true;
            if (value.handle == null) this.mHdrFont.createFontHandle();
            this.checkRedrawNeeded();
        }

        /// Adds a row of items to listview. Only for Report view.
        void addRow(string[] items...)
        {
            if (this.mLvStyle != ListViewStyle.report || !this.mIsCreated) return;
            auto iLen = items.length;
            auto lvItem = new ListViewItem(items[0]);
            this.addItemInternal(lvItem);
            for (int i = 1; i < iLen; ++i) {
                this.addSubItemInternal(items[i], lvItem.index, i);
            }
        }

        /// Add bulk of items to listiview.
        void addItems(string[] items...)
        {
            if (this.mLvStyle != ListViewStyle.report || !this.mIsCreated) return;
            auto iLen = items.length;
            auto lvItem = new ListViewItem(items[0]);
            this.addItemInternal(lvItem);
            for (int i = 1; i < iLen; ++i) {
                this.addSubItemInternal(items[i], lvItem.index, i);
            }
        }

        /// Adds an item to list view.
        void addItem(T)(T item, int imgIndx = -1)
        {
            if (this.mIsCreated) {
                auto lvItem = new ListViewItem(item.toString, imgIndx);
                this.addItemInternal(lvItem);
            }
        }

        /// Adds an item to list view.
        void addItem(ListViewItem item)
        {
            if (this.mIsCreated) this.addItemInternal(item);
        }

        /// Add sub items to an item at given index. Works only report view.
        void addSubItems(T...)(int itemIndex, T subItems)
        {
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
        void addSubItem(T)(T subItem, int itemIndex, int subIndx, int imgIndx = -1)
        {
            if (this.mIsCreated && this.mLvStyle == ListViewStyle.report) {
                this.addSubItemInternal(subItem.toString, itemIndex, subIndx, imgIndx );
            }
        }

        final void deleteItem(int index)
        {
            if (this.mIsCreated && this.mItems.length > 0) {
                this.sendMsg(LVM_DELETEITEM, index, 0);
                // TODO delete from mItems
            }
        }

        /// Set the image list for list view.
        final void setImageList(ImageList img, ImageType imgTyp = ImageType.smallImage)
        {
            if (this.mIsCreated) this.sendMsg(LVM_SETIMAGELIST, imgTyp, img.handle);
        }

        /// Sets the left to right order of columns
        final void setColumnOrder(int[] ordList...)
        {
            if (this.mIsCreated) {
                this.sendMsg(LVM_SETCOLUMNORDERARRAY, ordList.length, ordList.ptr);
            }
        }

        final void checkBoxColumnLast()
        {
            if (!this.mHasCheckBox) this.mHasCheckBox = true;
            if (mColumns.length > 0 )  {// There are some columns
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
        final void enableHeaderVisualStyle()
        {
            if (this.mColumns.length > 0 ) {
                MyHdItem hdi;
                foreach (col; this.mColumns) {
                    hdi.mask = HDI_FORMAT;
                    hdi.fmt = HDF_OWNERDRAW;
                    SendMessage(hwHeader, HDM_SETITEM, WPARAM(col.index), cast(LPARAM) &hdi);
                }
            }
        }

        /// Set the height of header.
        final void headerHeight(int value)
        {
            this.mChangeHdrHeight = true;
            this.mHdrHeight = value;
            this.checkRedrawNeeded();
        }

        final bool hasCheckBox() {return this.mHasCheckBox;}
        final void hasCheckBox(bool value)
        {
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

        final override void backColor(uint value)
        {
            this.mBackColor(value);
            if (this.mIsCreated) ListView_SetBkColor(this.mHandle,this.mBackColor.cref );
        }
        final override uint backColor() {return this.mBackColor.value;}

        /// Get or set selected index of listview item
        mixin finalProperty!("selectedIndex", this.mSelIndex);

        /// Get listview columns collection
        final ListViewColumn[] columns() {return this.mColumns;}

        /// Get or set align item top property
        mixin finalProperty!("alignItemTop", this.mitemTopAlign);

        /// Get or set hide selection
        mixin finalProperty!("hideSelection", this.mHideSel);

        /// Get or set multi selection property
        mixin finalProperty!("multiSelection", this.mMultiSel);

        /// Get or set full row selecttion
        mixin finalProperty!("fullRowSelection", this.mFullRowSel);

        /// Get or set if this list view has a check box.
        mixin finalProperty!("hasCheckBox", this.mHasCheckBox);

        /// Get or set show grid lines property. Default is true
        mixin finalProperty!("showGridLines", this.mShowGridLines);

        /// Get or set one click activate feature.
        mixin finalProperty!("oneClickActivate", this.mOneClickAct);

        /// Get or set hot track selection. Means, if mouse is over an item, it will be selected
        mixin finalProperty!("hotTrackSelection", this.mHotTrackSel);

        /// Get or set edit label property.
        mixin finalProperty!("editLabel", this.mEditLabel);

        /// Get or set no headers property
        mixin finalProperty!("noHeaders", this.mNoHeader);

        /// Get or set view style. Report view is default
        mixin finalProperty!("viewStyle", this.mLvStyle);

        final int headerHeight() {return this.mHdrHeight;}

    // Event section
    LVSelChangeEventHandler onSelectionChanged;
    LVCheckChangeEventHandler onItemCheckChanged;
    LVItemClickEventHandler onItemClicked, onItemDoubleClicked, onItemHover;

    package:
        int mSelIndex = -1;
        ListViewItem mSelItem;
        ListViewItem[] mSelItems;
        bool mEditLabel;
        bool mDrawHeader; // Need this to check in WM_NOTIFY msg // TODO - Rename this.
        HWND hwLabel;
        HWND hwHeader;

    private:
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
            HBRUSH mHdrDefBkBrush;
            HBRUSH mHdrHotBkBrush;
            HPEN mHdrPen;
            Alignment mColAlign;
            ListViewStyle mLvStyle;
            ListViewColumn[] mColumns;
            ListViewItem[] mItems;
            ColAndIndex[] mCIList;
            int mColIndex;
            int mOldHotHdrIndx = -1;// useless
            int mHotHdr = -1;
            int mHdrHeight;
            int mSelItemIndx;
            int mSelSubIndx;
            int stColIndex;
            static int lvNumber;
            Color mHdrBackColor;
            Color mHdrForeColor;
            ImageList mImgList;
            POINT mHdrMousePoint;
        // End of Variables.


        int[] changeColumnOrder()
        {
            int[] indices;
            foreach (lc; this.mColumns) {if (lc.index > 0) indices ~= lc.index;}
            indices ~= 0;
            return indices;
        }

        void addColumnInternal(ListViewColumn lvCol)  // Private
        {
            lvCol.setIndex(this.stColIndex);
            LVCOLUMNW lvc;
            lvc.mask = LVCF_FMT | LVCF_TEXT  | LVCF_WIDTH  | LVCF_SUBITEM;//| LVCF_ORDER;
            lvc.fmt = lvCol.alignment;
            lvc.cx = lvCol.width;
            lvc.pszText = cast(wchar*) lvCol.text.toUTF16z;

            if (lvCol.hasImage) {
                lvc.mask |= LVCF_IMAGE;
                lvc.fmt |= LVCFMT_COL_HAS_IMAGES | LVCFMT_IMAGE;
                lvc.iImage = lvCol.imageIndex;
                if (lvCol.imageOnRight) lvc.fmt |= LVCFMT_BITMAP_ON_RIGHT;
            }

            lvCol.pLvc = lvc;

            if (this.mIsCreated) {
                this.sendMsg(LVM_INSERTCOLUMNW, lvCol.index, &lvc);
                // We need this to do the painting in wm notify.
               // if (!this.mDrawColumns && lvCol.mDrawNeeded) this.mDrawColumns = true;
            } //else {
                // We need to collect this info in mCIList.
                // This list contains LVCOLUMNW struct and index of the column.
                // We can insert these items right after we create the lv handle.
                //this.mCIList ~= ColAndIndex(lvCol.index, lvc);

            this.mColumns ~= lvCol;
            this.stColIndex += 1;
        }

        void addItemInternal(ListViewItem item)  // Private
        {
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

        void addSubItemInternal(string sItem, int itemIndx, int subIndx, int imgIndx = -1)
        {
            LVITEMW lw;
            lw.iSubItem = subIndx;
            auto x = sItem.toUTF16z;
            lw.pszText = cast(LPWSTR) x;
            lw.iImage = imgIndx;
            this.sendMsg(LVM_SETITEMTEXT, itemIndx, &lw);
            this.mItems[itemIndx].addSubItem(sItem);
        }

        void adjustLVStyles() // Private
        {
            switch (this.mLvStyle) {
                case ListViewStyle.largeIcon:
                    this.mStyle |= LVS_ICON;
                break;
                case ListViewStyle.report:
                    this.mStyle |= LVS_REPORT;
                break;
                case ListViewStyle.smallIcon:
                    this.mStyle |= LVS_SMALLICON;
                break;
                case ListViewStyle.list:
                    this.mStyle |= LVS_LIST;
                break;
                default: break;
            }

            // Set some more styles...
            if (this.mEditLabel) this.mStyle |= LVS_EDITLABELS;
            if (this.mHideSel) this.mStyle |= LVS_SHOWSELALWAYS;
            if (this.mNoHeader) this.mStyle |= LVS_NOCOLUMNHEADER;
            if (this.mMultiSel) this.mStyle ^= LVS_SINGLESEL;

            // Set some brushes for coloring.
            this.mHdrDefBkBrush = CreateSolidBrush(this.mHdrBackColor.cref);
            this.mHdrHotBkBrush = this.mHdrBackColor.getHotBrushEx(20);
            this.mHdrPen = CreatePen(PS_SOLID, 1, 0x00FFFFFF);
        }

        // Set some EX styles...
        void setLvExStyles()  // Private
        {
            DWORD lvExStyle;
            if (this.mShowGridLines) lvExStyle |= LVS_EX_GRIDLINES;
            if (this.mHasCheckBox) lvExStyle |= LVS_EX_CHECKBOXES;
            if (this.mFullRowSel && !this.mEditLabel) lvExStyle |= LVS_EX_FULLROWSELECT;
            if (this.mOneClickAct) lvExStyle |= LVS_EX_ONECLICKACTIVATE;
            if (this.mHotTrackSel) lvExStyle |= LVS_EX_TRACKSELECT;
            this.sendMsg(LVM_SETEXTENDEDLISTVIEWSTYLE, 0, lvExStyle);
        }

        DWORD headerCustomDraw(NMCUSTOMDRAW* nmcd)
        {
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
                    if (nmcd.dwItemSpec == this.mHotHdr) {
                        // Mouse pointer is on header. So we will change the back color.
                        FillRect(nmcd.hdc, &nmcd.rc, this.mHdrHotBkBrush);
                    } else {
                        FillRect(nmcd.hdc, &nmcd.rc, this.mHdrDefBkBrush);
                    }
                }

                if (nmcd.uItemState & CDIS_SELECTED) {
                    /*----------------------------------------------- 
                    Here we are mimicing dot net's same technique.
                    We will change the rect's left and top a 
                    little bit when header got clicked.
                    So user will feel the header is pressed. 
                    -------------------------------------------------*/
                    nmcd.rc.left += 2;
                    nmcd.rc.top += 2;
                }
            } else {
                FillRect(nmcd.hdc, &nmcd.rc, this.mHdrDefBkBrush);
            }

            // Draw a white line on ther right side of the hdr
            SelectObject(nmcd.hdc, this.mHdrPen);
            MoveToEx(nmcd.hdc, nmcd.rc.right, nmcd.rc.top, NULL);
            LineTo(nmcd.hdc, nmcd.rc.right, nmcd.rc.bottom);
            SelectObject(nmcd.hdc, this.mHdrFont.handle);
            SetTextColor(nmcd.hdc, this.mHdrForeColor.cref);
            DrawText(nmcd.hdc, col.mWideText, -1, &nmcd.rc, col.mHdrTxtFlag );
            return CDRF_SKIPDEFAULT;
        }

        LRESULT wmNotifyHandler(LPARAM lpm) 
        {
            auto nmhdr = cast(NMHDR*)lpm;
            switch (nmhdr.code) {
                case NM_CUSTOMDRAW:
                    auto nmLvCd = cast(NMLVCUSTOMDRAW*)lpm;
                    switch (nmLvCd.nmcd.dwDrawStage) {
                        case CDDS_PREPAINT: return CDRF_NOTIFYITEMDRAW; break;
                        case CDDS_ITEMPREPAINT:
                            nmLvCd.clrTextBk = this.mBackColor.cref;
                            nmLvCd.clrText = this.mForeColor.cref;
                            return CDRF_NEWFONT | CDRF_DODEFAULT;
                        break;
                        default: break;
                    }
                break;
                case LVN_ITEMCHANGING:
                break;
                case LVN_ITEMCHANGED:
                    auto nmlv = cast(NMLISTVIEW*) lpm;
                    if (nmlv.uNewState & LVIF_STATE) {
                        int nowSelected = (nmlv.uNewState & LVIS_SELECTED);
                        int wasSelected = (nmlv.uOldState & LVIS_SELECTED);
                        if (nowSelected && !wasSelected) {
                            auto sitem = this.mItems[nmlv.iItem];
                            if (this.mMultiSel) {
                                this.mSelItems ~= sitem;
                            } else {
                                this.mSelItem = sitem;
                            }
                            if (this.onSelectionChanged) {
                                auto lsea = new LVSelChangeEventArgs(sitem, nmlv.iItem, nowSelected);
                                this.onSelectionChanged(this, lsea);
                            }
                        } else if (!nowSelected && wasSelected) {
                            auto sitem = this.mItems[nmlv.iItem];
                            if (this.mMultiSel) {
                                this.mSelItems ~= sitem;                                
                                if (this.onSelectionChanged) {
                                    auto lsea = new LVSelChangeEventArgs(sitem, nmlv.iItem, nowSelected);
                                    this.onSelectionChanged(this, lsea);
                                }
                            }
                        }
                        // ✅ Check for checkbox state change
                        auto state_index = (nmlv.uNewState & LVIS_STATEIMAGEMASK) >> 12;
                        auto old_state_index = (nmlv.uOldState & LVIS_STATEIMAGEMASK) >> 12;
                        if (state_index != old_state_index) {
                            auto is_checked = (state_index == 2);
                            if (this.mItems.length) {
                                auto sitem = this.mItems[nmlv.iItem];                                
                                sitem.mChecked = is_checked;
                                if (this.onItemCheckChanged) {
                                    auto licea = new LVCheckChangeEventArgs(sitem, nmlv.iItem, is_checked);
                                    this.onItemCheckChanged(this, licea);
                                }
                            } 
                        }
                    }
                break;
                case NM_DBLCLK:
                    goto case;
                case NM_CLICK:                    
                    auto nmia = cast(NMITEMACTIVATE *)lpm;
                    auto lviea = new LVItemEventArgs(this.mItems[nmia.iItem],
                                                     nmia.iItem);
                    if (this.onItemClicked) this.onItemClicked(this, lviea);
                    if (this.onItemDoubleClicked) this.onItemDoubleClicked(this, lviea);
                break;
                // case NM_HOVER:
                //     // print("hover test");
                //     if (this.onItemHover) this.onItemHover(this, GEA);
                // break;
                //case LVN_HOTTRACK: print("lvn hot track", 1); break;
                case NM_RELEASEDCAPTURE:
                //    print("LVN_ITEMCHANGED", 12); break;
                //case NM_CLICK:
                    // this.mSelIndex = this.sendMsg(LVM_GETNEXTITEM, -1, LVNI_SELECTED);
                    // this.mSelItem = this.mItems[this.mSelIndex];
                    // if (this.onSelectionChanged) {
                    //     auto ea = new EventArgs();
                    //     this.onSelectionChanged(this, ea);
                    // }
                break;
                case LVN_BEGINLABELEDITW:
                    this.hwLabel = ListView_GetEditControl(this.mHandle);
                    //return cast(LRESULT) false;
                break;

                case LVN_COLUMNCLICK:
                    // Implement column click event here.
                break;
                case LVN_ENDLABELEDITW:
                    if (this.mEditLabel) {
                        // print("label edit ok");
                    }
                    return trueLresult;
                break;
                default: break;
                }
            return CDRF_DODEFAULT;
        }

        void setHdrMouseLeave() 
        {
            foreach (col1; mColumns) col1.mIsHotItem = false;
        }

         void finalize(UINT_PTR scid)
        {
            if (this.mHdrHotBkBrush != null) DeleteObject(this.mHdrHotBkBrush);
            if (this.mHdrDefBkBrush != null) DeleteObject(this.mHdrDefBkBrush);
            if (this.mHdrPen != null) DeleteObject(this.mHdrPen);
            RemoveWindowSubclass(this.mHandle, &lvWndProc, scid);
        }

} // End of class ListView

class ListViewColumn
{
    this(string colTxt, int width, int img = -1, bool imgRight = false)
    {
        this.mText  = colTxt;
        this.mWidth = width;
        this.mColAlign = Alignment.left;
        this.mWideText = colTxt.toUTF16z;
        //this.mIndex = mIndexNum;
        this.mImgIndex = img;
        this.mImgOnRight = imgRight;
        this.mHdrTxtAlign = Alignment.left;
        this.mHdrTxtFlag = DT_SINGLELINE | DT_VCENTER | DT_CENTER | DT_NOPREFIX;
        //++mIndexNum;
    }

    this() {}

    this(string header) {this(header, 100);}

    mixin finalProperty!("text", this.mText);
    mixin finalProperty!("width", this.mWidth);
    mixin finalProperty!("imageIndex", this.mImgIndex);
    mixin finalProperty!("alignment", this.mColAlign);
    mixin finalProperty!("imageOnRight", this.mImgOnRight);

    final Alignment headerAlign() {return this.mHdrTxtAlign;}
    final void headerAlign(Alignment value)
    {
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

    final int index() {return this.mIndex;}
    final bool hasImage() {return (this.mImgIndex > -1) ? true: false;}

    package:
        bool mDrawNeeded;
        bool mIsHotItem;

    private:
        string mText;
        int mWidth;
        int mIndex = -1;
        int mImgIndex = -1;
        int mOrder;
        Color mBackColor;
        Color mForeColor;
        bool mImgOnRight;
        LPCWSTR mWideText;
        Alignment mColAlign;
        Alignment mHdrTxtAlign;
        DWORD mHdrTxtFlag;
        LVCOLUMN pLvc;
    
        void setIndex(int index) 
        {
            this.mIndex = index; 
        }

} // End of ListViewColumn class


class ListViewItem
{
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

    private:
        int mIndex;
        int mImgIndex;
        bool mChecked;
        Color mBkClr;
        Color mFrClr;
        Font mFont;
        string mText;
        string[] mSubItems;
        static int mStIndex;

} // ListViewItem class



struct MyHdItem
{
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

struct HeaderRects
{
    RECT rct;
    int headerIndex;
}

// class ListViewSubItem {
//     string mText;
//     Font mFont;
//     uint mBkClr;
//     uint mFrClr;

// }

struct ColAndIndex
{
    int index;
    LVCOLUMNW lvc;
}

enum LVN_HOTTRACK = LVN_FIRST - 21;
extern(Windows)
private LRESULT lvWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                                UINT_PTR scID, DWORD_PTR refData)
{
    try {
        switch (message) {
            case WM_DESTROY: 
                ListView lv = getControl!ListView(refData);
                lv.finalize(scID); 
            break;
            case WM_PAINT: 
                ListView lv = getControl!ListView(refData);
                lv.paintHandler(); 
            break;
            case WM_SETFOCUS: 
                ListView lv = getControl!ListView(refData);
                lv.setFocusHandler(); 
            break;
            case WM_KILLFOCUS: 
                ListView lv = getControl!ListView(refData);
                lv.killFocusHandler(); 
            break;
            case WM_LBUTTONDOWN: 
                ListView lv = getControl!ListView(refData);
                lv.mouseDownHandler(message, wParam, lParam); 
            break;
            case WM_LBUTTONUP: 
                ListView lv = getControl!ListView(refData);
                lv.mouseUpHandler(message, wParam, lParam); 
            break;
            case WM_RBUTTONDOWN: 
                ListView lv = getControl!ListView(refData);
                lv.mouseRDownHandler(message, wParam, lParam); 
            break;
            case WM_RBUTTONUP: 
                ListView lv = getControl!ListView(refData);
                lv.mouseRUpHandler(message, wParam, lParam); 
            break;
            case WM_MOUSEWHEEL: 
                ListView lv = getControl!ListView(refData);
                lv.mouseWheelHandler(message, wParam, lParam); 
            break;
            case WM_MOUSEMOVE: 
                ListView lv = getControl!ListView(refData);
                lv.mouseMoveHandler(message, wParam, lParam); 
            break;
            case WM_MOUSELEAVE: 
                ListView lv = getControl!ListView(refData);
                lv.mouseLeaveHandler(); 
            break;
            case WM_CONTEXTMENU: 
                ListView lv = getControl!ListView(refData);
                if (lv.mCmenu) lv.mCmenu.showMenu(lParam); 
            break;

            case CM_NOTIFY:
                // Windows will send this msg to parent window and parent window transfer this to here.
                ListView lv = getControl!ListView(refData);
                return lv.wmNotifyHandler(lParam);
            break;

            case WM_NOTIFY: // This msg is coming from Header control.
                ListView lv = getControl!ListView(refData);
                auto nmh= cast(NMHDR*) lParam;
                switch (nmh.code) {
                    case NM_CUSTOMDRAW:  // Let's draw header back & fore colors
                        auto nmcd = cast(NMCUSTOMDRAW*) lParam;
                        if (!lv.mDrawHeader) {
                            switch (nmcd.dwDrawStage)  {// NM_CUSTOMDRAW is always -12 when item painting
                                case CDDS_PREPAINT:
                                    /*-------------------------------------------------------------- 
                                    When drawing started, system will send a NM_CUSTOMDRAW 
                                    notification to parent of the control. Here, parent of 
                                    header control is list view. So we get the notification 
                                    with WM_NOTIFY message. We returns the CDRF_NOTIFYITEMDRAW
                                    value so that system will notify us when the pre paint stage 
                                    begins for each item.
                                    ---------------------------------------------------------------------*/
                                    return CDRF_NOTIFYITEMDRAW; 
                                break;
                                case CDDS_ITEMPREPAINT:
                                    /*------------------------------------------------------------------- 
                                    So we get the notification at the pre paint statge. We can draw the 
                                    header colors, text and tell the system to not to draw anything on 
                                    this header. So system will skip the default drawing jobs. 
                                    --------------------------------------------------------------------*/
                                    return lv.headerCustomDraw(nmcd);
                                break;
                                //case CDDS_ITEMPOSTPAINT:
                                //   // lv.headerCustomDraw(nmcd);
                                //    return CDRF_NEWFONT | CDRF_DODEFAULT;
                                //    break;
                                default: break;
                            }
                        }
                    break;
                    default: /*print("other code ", nmcd.hdr.code); */ break;
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

extern(Windows)
private LRESULT hdrWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                                    UINT_PTR scID, DWORD_PTR refData)
{
    try {       
       //printWinMsg(message);
        switch (message) {
            case WM_DESTROY: RemoveWindowSubclass(hWnd, &hdrWndProc, scID); break;
            case WM_MOUSEMOVE:
                /*-------------------------------------------------------------------
                We need to some extra job here. Because, there is no notification
                for a header control when mouse pointer passes upon it. So We collect
                the mouse pointer coordinates and send the HDM_HITTEST message to header
                control. The control will fill the iItem member of the struct. It contains
                the item index which is under the pointer. So we can set the drawing
                flag for that column. 
                --------------------------------------------------------------------------*/
                ListView lv = getControl!ListView(refData);
                HD_HITTESTINFO hinfo;
                hinfo.pt = getMousePos(lParam);
                lv.mHotHdr = cast(int) SendMessage(hWnd, HDM_HITTEST, 0, cast(LPARAM) &hinfo);
            break;
            case WM_MOUSELEAVE:
                /* When mouse leaves the header, we need to set flag to false and repaint */
                ListView lv = getControl!ListView(refData);
                lv.mHotHdr = -1;
            break;
            case HDM_LAYOUT:
                /* Set the window pos structures fields, so that windows will adjust our header & lv */
                ListView lv = getControl!ListView(refData);
                if (lv.mChangeHdrHeight) {
                    LPHDLAYOUT pHl = cast(LPHDLAYOUT) lParam;
                    pHl.pwpos.hwnd = hWnd;
                    pHl.pwpos.flags = SWP_FRAMECHANGED;
                    pHl.pwpos.x = pHl.prc.left;
                    pHl.pwpos.y = 0;
                    pHl.pwpos.cx = (pHl.prc.right - pHl.prc.left);
                    pHl.pwpos.cy = lv.mHdrHeight;
                    pHl.prc.top =lv.mHdrHeight;
                    return 1;
                }
            break;
            case WM_PAINT:
                /*---------------------------------------------------------------- 
                We need to paint the last part of the header control. Otherwise,
                it will look like a weird white color square and it's ugly unless,
                we are using white color for header. 
                -------------------------------------------------------------------*/
                // First, let the control to do it's necessary drawings.
                ListView lv = getControl!ListView(refData);
                DefSubclassProc(hWnd, message, wParam, lParam);

                // Now, we can draw the last part of the header.
                RECT hrc;
                SendMessage(hWnd, HDM_GETITEMRECT, lv.mColumns.length - 1, cast(LPARAM) &hrc);
                auto rc = RECT(hrc.right + 1, hrc.top, lv.width, hrc.bottom);
                HDC hdc = GetDC(hWnd);
                FillRect(hdc, &rc, lv.mHdrDefBkBrush);
                ReleaseDC(hWnd, hdc);
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

struct tagNMLVCUSTOMDRAW
{
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
                rctAdj2 = -1;
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
                rctAdj2 = 0;
            }
            auto rct = adjustRect(nmcd.rc, rctAdj1, rctAdj2);
            auto topRect = makeHalfSizeRect(rct, true);
            auto botRect = makeHalfSizeRect(rct, false);

            FillRect(nmcd.hdc, &topRect,  this.mHdrBkBrushTop );
            FillRect(nmcd.hdc, &botRect,  this.mHdrBkBrushBot );
            if (this.mHdrDrawFont)  SelectObject(nmcd.hdc, this.mHdrFont.handle);
            SetTextColor(nmcd.hdc, this.mHdrColors.foreColorRef);
            DrawText(nmcd.hdc, col.text.toUTF16z, -1, &nmcd.rc, mTxtFlag );
        }


*/

void printNmLV(NMITEMACTIVATE * nm)
{
    import std.stdio;
    writefln("iItem: %s", nm.iItem);
    writefln("iSubItem: %s", nm.iSubItem);
    writefln("uNewState: %s", nm.uNewState);
    writefln("uOldState: %s", nm.uOldState);
    writefln("uChanged: %s", nm.uChanged);
    writefln("ptAction: %s", nm.ptAction);
    writefln("lParam: %s", nm.lParam);
    writefln("uKeyFlags: %s", nm.uKeyFlags);

}

void printNmLV(NMLISTVIEW * nm)
{
    import std.stdio;
    writefln("iItem: %s", nm.iItem);
    writefln("iSubItem: %s", nm.iSubItem);
    writefln("uNewState: %s", nm.uNewState);
    writefln("uOldState: %s", nm.uOldState);
    writefln("uChanged: %s", nm.uChanged);
    writefln("ptAction: %s", nm.ptAction);
    writefln("lParam: %s", nm.lParam);
    //writefln("uKeyFlags: %s", nm.uKeyFlags);

}
