module wings.menubar; // Created on 30-July-2022 06:56 PM

import wings.d_essentials;
import wings.wings_essentials;

class MenuBar {

    this (Window parent, Font menuFont = null) {
        this.mHmenubar = CreateMenu();
        this.mParent = parent;
        this.mFont = menuFont is null ? parent.mFont : menuFont;
        this.mType = MenuType.baseMenu;
        this.mMenuCount = 0;
        parent.mMenuGrayBrush = makeHBRUSH(0xced4da);
        parent.mMenuGrayCref = getClrRef(0x979dac);
    }

    // this (Window parent) {
    //     this.mParent = parent;
    //     this.mFont = parent.font;
    //     this.mMenuHandle = CreateMenu();
    // }

    // final void addMenu(string txt) {
    //     auto mi = new MenuItem(&this.mParent, txt, null, MenuType.baseMenu);
    //     this.mMenus ~= mi;
    // }

    final void addMenus(string[] menuNames ...) {
        foreach (name; menuNames) {
            auto mi = new MenuItem(name, this.mHmenubar, MenuType.baseMenu, this.mMenuCount);
            mi.mWinHwnd = this.mParent.mHandle;
            mi.mBarmenu = true;
            this.mMenuCount += 1;
            this.mMenus[name] = mi;
            this.mParent.mMenuItemDict[mi.mId] = mi;
        }
    }

    // final void addMenu(string mnu, wstring[] subMenus) {
    //     auto m = new MenuItem(&this.mParent, mnu, null, MenuType.baseMenu);
    //     m.addMenu(subMenus);
    //     this.mMenus ~= m;
    // }

    // final void addMenu(MenuItem mi) { this.mMenus ~= mi;}

    final MenuItem addMenu(string txt, uint txtColor = 0x000000) {
        auto result = new MenuItem(txt, this.mHmenubar, MenuType.baseMenu, this.mMenuCount);
        result.mWinHwnd = this.mParent.mHandle;
        result.mFgColor = Color(txtColor);
        result.mBarmenu = true;
        this.mMenuCount += 1;
        this.mMenus[txt] = result;
        this.mParent.mMenuItemDict[result.mId] = result;
        return result;
    }

    final void create() {
        this.mParent.mMenuDefBgBrush = makeHBRUSH(0xe9ecef);
        this.mParent.mMenuHotBgBrush = makeHBRUSH(0x90e0ef);
        this.mParent.mMenuFrameBrush = makeHBRUSH(0x0077b6);
        this.mParent.mMenuFont = this.mFont;
        if (this.mMenus.length > 0) {
            foreach (string key; this.mMenus.byKey) this.mMenus[key].create();
        }
        SetMenu(this.mParent.mHandle, this.mHmenubar);
    }

    // final MenuItem[] menuItems() {return this.mMenus;}
    // final ref MenuItem item(string value) {
    //     foreach (ref menu; this.mMenus) {if (menu.text == value) return menu;}
    //     throw new Exception("Can't find menu item");
    // }

    final MenuItem[string] menus() {return this.mMenus;}


    private:
        HMENU mHmenubar;
        Window mParent;
        Font mFont;
        MenuType mType;
        int mMenuCount;
        MenuItem[string] mMenus;

} // End of MenuBar class

// bool isPopupMenu(MenuType mtp) { return mtp == MenuType.baseMenu || mtp == MenuType.popumMenu;}

class MenuItem {

    this (string txt, HMENU parentmenuHandle, MenuType mtyp, int indexNum) {
        this.mPopup = mtyp == MenuType.baseMenu || mtyp == MenuType.popumMenu;
        this.mHmenu = this.mPopup ? CreatePopupMenu() : CreateMenu();
        this.mIndex = indexNum;
        if (txt == "_") txt = format("sep_%d", this.mIndex);
        this.mId = staticIdNum;
        this.mText = txt;
        this.mWideText = this.mText.toUTF16z();
        this.mType = mtyp;
        this.mParentHmenu = parentmenuHandle;
        this.mBgColor = Color(0xe9ecef);
        this.mFgColor = Color(0x000000);
        this.mEnabled = true;
        staticIdNum += 1;
    }

    final MenuItem addMenu(string txt, uint txtColor = 0x000000) {
        if (this.mType == MenuType.menuItem) {
            this.mHmenu = CreatePopupMenu();
            this.mPopup = true;
        }
        auto result = new MenuItem(txt, this.mHmenu, MenuType.menuItem, this.mChildCount);
        result.mFgColor = Color(txtColor);
        result.mWinHwnd = this.mWinHwnd;
        result.mBarmenu = this.mBarmenu;
        if (this.mType != MenuType.baseMenu) this.mType = MenuType.popumMenu;
        this.mChildCount += 1;
        this.mMenus[txt] = result;
        if (result.mWinHwnd) SendMessageW(result.mWinHwnd, CM_MENU_ADDED, cast(WPARAM)result.mId, cast(LPARAM) &result);
        return result;
    }

    final void addMenus(string[] mnuNames ...) {
        if (this.mType == MenuType.menuItem) {
            this.mHmenu = CreatePopupMenu();
            this.mPopup = true;
        }
        if (this.mType != MenuType.baseMenu) this.mType = MenuType.popumMenu;
        foreach (name; mnuNames) {
            if (name == "_") {
                this.addSeperator();
            } else {
                auto mi = new MenuItem(name, this.mHmenu, MenuType.menuItem, this.mChildCount);
                mi.mWinHwnd = this.mWinHwnd;
                mi.mBarmenu = this.mBarmenu;

                this.mChildCount += 1;
                this.mMenus[name] = mi;
                if (mi.mWinHwnd) SendMessageW(mi.mWinHwnd, CM_MENU_ADDED, cast(WPARAM) mi.mId, cast(LPARAM) &mi);
            }
        }
    }


    final void addSeperator() {
        auto mi = new MenuItem("_", this.mHmenu, MenuType.separator, this.mChildCount);
        this.mChildCount += 1;
        this.mMenus[mi.mText] = mi;
    }

    final void create() {
        switch (this.mType) {
            case MenuType.baseMenu, MenuType.popumMenu:
                if (this.mMenus.length > 0) {
                    foreach (string key; this.mMenus.byKey) this.mMenus[key].create();
                }
                this.insertMenuInternal(this.mParentHmenu);
            break;
            case MenuType.menuItem: this.insertMenuInternal(this.mParentHmenu); break;
            case MenuType.separator: AppendMenuW(this.mParentHmenu, MF_SEPARATOR, 0, null); break;
            default: break;
        }
    }

    final MenuItem[string] menus() {return this.mMenus;}


    final string text() {return this.mText;}
    // final uint uFlag() {return this.mFlag;}
    // final uint menuID() {return this.mId;}
    // final HMENU handle() {return this.mHandle;}
    // final HMENU parentHandle() {return this.mParentHandle;}

    // final ref MenuItem item(wstring value) {
    //     foreach (ref menu; this.mMenus) {if (menu.text == value) return menu;}
    //     throw new Exception("Can't find menu item");
    // }

    // final MenuItem[] menuItems() {return this.mMenus;}

    // final void onClick(MenuEventHandler value) {
    //     this.mClickHandler = value;
    //     this.mOwnerWindow.setMenuClickHandler(this);
    // }

    // Events
    MenuEventHandler onClick;
    MenuEventHandler onPopup;
    MenuEventHandler onCloseup;
    MenuEventHandler onFocus;


    // package final void clickHandler(EventArgs e) {this.mClickHandler(this, e);}
    package:
        string mText;
        LPCWSTR mWideText;
        MenuType mType;
        Color mFgColor;
        bool mEnabled;
        uint mId;
        HMENU mHmenu;

        void insertMenuInternal(HMENU parenthmenu) {
            MENUITEMINFOW mii;
            mii.cbSize = cast(UINT)MENUITEMINFOW.sizeof;
            mii.fMask = MIIM_ID | MIIM_TYPE | MIIM_DATA | MIIM_SUBMENU | MIIM_STATE;
            mii.fType = MF_OWNERDRAW;
            mii.dwTypeData = cast(wchar*) this.mText.toUTF16z;
            mii.cch = cast(UINT)this.mText.length;
            mii.dwItemData = cast(ULONG_PTR)(cast(void*)this);
            mii.wID = this.mId;
            mii.hSubMenu = this.mPopup ? this.mHmenu : null;
            InsertMenuItemW(parenthmenu, this.mIndex, 1, &mii);
            this.mCreated = true;
        }

        MenuItem getChildFromIndex(int index) {
            foreach (key, menu; this.mMenus) {if (menu.mIndex == index) return menu;}
            return null;
        }

    private:

        HMENU mParentHmenu;
        uint mChildCount;
        uint mIndex;
        bool mByPos;
        bool mChecked;
        bool mCreated;
        bool mPopup;
        bool mBarmenu;
        Font mFont;
        Color mBgColor;
        MenuItem[string] mMenus;
        uint mFlag;
        HWND mWinHwnd;
        static uint staticIdNum = 100;


}

MenuItem getMenuItem(ULONG_PTR refData){ return cast(MenuItem) (cast(void*) refData);}

