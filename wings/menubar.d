 // Created on 30-July-2022 06:56 PM
/*==============================================Menu Docs=====================================
    (1) MenuBase:
            Abstract class. A base class for menubar and menuitem & contextmenu
    
    (2) MenuBar:
            Constructor:
                this (Form parent)
                this(Form parent, string[] menuNames ...)

            Properties:
                menus   : MenuItem[]
            
            Functions:
                addItem
                addItems
                createHandle

    (3) MenuItem:
            Constructor:
                this (string txt, MenuType mtyp, HMENU parentmenuHandle, int indexNum)
            
            Properties:
                text        : string
                menus       : MenuItem[]

            Methods:
                addItem
                addItems
                createHandle
            
            Events:                
                MenuEventHandler - void delegate(MenuItem, EventArgs)
                    onClick
                    onPopup
                    onCloseup
                    onFocus       
=============================================================================================*/

module wings.menubar;
import wings.d_essentials;
import wings.wings_essentials;
import std.stdio;

class MenuBase 
{
    HMENU mHandle;
	MenuItem[] mMenus;
	Font mFont;
	HWND mWinHwnd;
	uint mMenuCount;
}

enum ParentKind {mainMenu, contextMenu}

class MenuBar : MenuBase 
{
    this (Form parent)
    {
        this.mHandle = CreateMenu();
        this.mWindow = parent;
        this.mFont = new Font("Tahoma", 11);
        this.mMenuCount = 0;
        this.mMenuGrayBrush = makeHBRUSH(0xced4da);
        this.mMenuGrayCref = getClrRef(0x979dac);
        parent.mMenubar = this;
    }

    this(Form parent, string[] menuNames ...)
    {
        this(parent);
        this.addItems(menuNames);
    }

    // this (Form parent) {
    //     this.mParent = parent;
    //     this.mFont = parent.font;
    //     this.mMenuHandle = CreateMenu();
    // }

    final void addItem(string txt)
    {
        MenuType mtyp = txt == "|" ? MenuType.separator : MenuType.baseMenu;
        auto mi = new MenuItem(txt, mtyp, this.mHandle, this.mMenuCount);
        mi.mParentKind = ParentKind.mainMenu;
        mi.mBar = this;
        this.mMenuCount += 1;
        this.mMenus ~= mi;
        this.mWindow.mMenuItemDict[mi.mId] = mi;

    }

    final void addItems(string[] menuNames...)
    {
        foreach (name; menuNames) {
            MenuType mtyp = name == "|" ? MenuType.separator : MenuType.baseMenu;
            auto mi = new MenuItem(name, mtyp, this.mHandle, this.mMenuCount);
            mi.mParentKind = ParentKind.mainMenu;
            mi.mBar = this;
            this.mMenuCount += 1;
            this.mMenus ~= mi;
            this.mWindow.mMenuItemDict[mi.mId] = mi;
        }
    }

    final void createHandle() {
        this.mMenuDefBgBrush = makeHBRUSH(0xe9ecef);
        this.mMenuHotBgBrush = makeHBRUSH(0x90e0ef);
        this.mMenuFrameBrush = makeHBRUSH(0x0077b6);
        if (this.mFont.mHandle == null) this.mFont.createFontHandle();
        if (this.mMenus.length > 0) {
            foreach (menu; this.mMenus) menu.createHandle();
        }
        SetMenu(this.mWindow.mHandle, this.mHandle);
        this.mWindow.mMenubarCreated = true;
        this.mIsCreated = true;
    }

    final MenuItem[] menus() {return this.mMenus;}

    MenuItem opIndex(string name) 
    { 
        if (this.mMenus.length > 0) {
            foreach (menu; this.mMenus) {
                if (menu.mText == name) return menu;
            }
        }
        return null;
    }
    

    package:
        bool mIsCreated;
        HBRUSH mMenuDefBgBrush;
        HBRUSH mMenuHotBgBrush;
        HBRUSH mMenuFrameBrush;
        HBRUSH mMenuGrayBrush;
        COLORREF mMenuGrayCref;


    private:
        Form mWindow;
        HWND mWinHwnd;


        // MenuItemList _menuList;

} // End of MenuBar class

// bool isPopupMenu(MenuType mtp) { return mtp == MenuType.baseMenu || mtp == MenuType.popumMenu;}

class MenuItem : MenuBase 
{
    this (string txt, MenuType mtyp, HMENU parentmenuHandle, int indexNum)
    {
        this.mPopup = mtyp == MenuType.baseMenu || mtyp == MenuType.popumMenu;
        this.mHandle = this.mPopup ? CreatePopupMenu() : CreateMenu();
        this.mIndex = indexNum;
        if (txt == "|") txt = format("sep_%d", this.mIndex);
        this.mId = staticIdNum;
        this.mText = txt;
        this.mWideText = this.mText.toUTF16z();
        this.mType = mtyp;
        this.mParentHandle = parentmenuHandle;
        this.mBgColor = Color(0xe9ecef);
        this.mFgColor = Color(0x000000);
        this.mEnabled = true;
        staticIdNum += 1;
    }

    final MenuItem addItem(string txt, uint txtColor = 0x000000)
    {
        MenuType mtyp = txt == "|" ? MenuType.separator : MenuType.baseMenu;
        if (this.mType == MenuType.normalMenu) {
            this.mHandle = CreatePopupMenu();
            this.mPopup = true;
        }
        auto mi = new MenuItem(txt, mtyp, this.mHandle, this.mMenuCount);
        mi.mFgColor = Color(txtColor);
        mi.mParentKind = this.mParentKind;
        if (this.mType != MenuType.baseMenu) this.mType = MenuType.popumMenu;
        this.mMenuCount += 1;
        this.mMenus ~= mi;
        if (this.mParentKind == ParentKind.mainMenu) {
            mi.mBar = this.mBar;
            this.mBar.mWindow.mMenuItemDict[mi.mId] = mi;
        }
        return mi;
    }

    final void addItems(string[] menuNames ...) 
    {
        if (this.mType == MenuType.normalMenu) {
            this.mHandle = CreatePopupMenu();
            this.mPopup = true;
        }
        if (this.mType != MenuType.baseMenu) this.mType = MenuType.popumMenu;

        foreach (name; menuNames) {
            MenuType mtyp = name == "|" ? MenuType.separator : MenuType.normalMenu;
            auto mi = new MenuItem(name, mtyp, this.mHandle, this.mMenuCount);
            mi.mParentKind = this.mParentKind;
            this.mMenuCount += 1;
            this.mMenus ~= mi;
            if (this.mParentKind == ParentKind.mainMenu) {
                mi.mBar = this.mBar;
                this.mBar.mWindow.mMenuItemDict[mi.mId] = mi;
            }
        }
    }


    // final void addSeperator() {
    //     auto mi = new MenuItem("_", this.mHmenu, MenuType.separator, this.mChildCount);
    //     this.mChildCount += 1;
    //     this.mMenus[mi.mText] = mi;
    // }

    final void createHandle()
    {
        switch (this.mType) {
            case MenuType.baseMenu, MenuType.popumMenu:
                if (this.mMenus.length > 0) {
                    foreach (menu; this.mMenus) {
                        // writefln("parent: %s, menu: %s, type: %s", this.mText, this.mMenus[key].mText, this.mMenus[key].mType);
                        menu.createHandle();
                    }
                }
                this.insertMenuInternal(this.mParentHandle);
            break;
            case MenuType.normalMenu: this.insertMenuInternal(this.mParentHandle); break;
            case MenuType.separator: AppendMenuW(this.mParentHandle, MF_SEPARATOR, 0, null); break;
            default: break;
        }
    }

    final MenuItem[] menus() {return this.mMenus;}


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
        MenuBar mBar;
        string mText;
        LPCWSTR mWideText;
        MenuType mType;
        Color mFgColor;
        bool mEnabled;
        uint mId;
        ParentKind mParentKind;


        // Using to insert menu items in a MenuBar
        void insertMenuInternal(HMENU parentHmenu)
        {
            MENUITEMINFOW mii;
            mii.cbSize = cast(UINT)MENUITEMINFOW.sizeof;
            mii.fMask = MIIM_ID | MIIM_TYPE | MIIM_DATA | MIIM_SUBMENU | MIIM_STATE;
            mii.fType = MF_OWNERDRAW;
            mii.dwTypeData = cast(wchar*) this.mWideText;
            mii.cch = cast(UINT) this.mText.length;
            mii.dwItemData = cast(ULONG_PTR)(cast(void*)this);
            mii.wID = this.mId;
            mii.hSubMenu = this.mPopup ? this.mHandle : null;
            InsertMenuItemW(parentHmenu, this.mIndex, 1, &mii);
            this.mCreated = true;
        }

        MenuItem getChildFromIndex(int index) {
            foreach (menu; this.mMenus) {if (menu.mIndex == index) return menu;}
            return null;
        }

        // Using to insert menu items in a Context menu. 
        void insertCmenuInternal()
        {
            if (this.mMenus.length > 0) {
                foreach (menu; this.mMenus) menu.insertCmenuInternal();
            }
            if (this.mType == MenuType.normalMenu) {
                this.insertMenuInternal(this.mParentHandle);
            } else if (this.mType == MenuType.separator) {
                AppendMenuW(this.mParentHandle, MF_SEPARATOR, 0, null);
            }
        }

        void finalize() 
        {
            if (this.mMenus.length > 0) {
                foreach (menu; this.mMenus) menu.finalize();
            }
            DestroyMenu(this.mHandle);
            print("MenuItem %s destroyed", this.mText);
        }

    private:
        HMENU mParentHandle;
        uint mIndex;
        bool mByPos;
        bool mChecked;
        bool mCreated;
        bool mPopup;
        Color mBgColor;
        uint mFlag;
        static uint staticIdNum = 100;

}

MenuItem getMenuItem(ULONG_PTR refData){ return cast(MenuItem) (cast(void*) refData);}

