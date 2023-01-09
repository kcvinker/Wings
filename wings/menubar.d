module wings.menubar; // Created on 30-July-2022 06:56 PM

import wings.d_essentials;
import wings.wings_essentials;

class MenuBar : Control {

    this (Window parent, wstring[] items) {
        this.mParent = parent;
        this.mFont = parent.font;
        foreach (item; items) {
            auto mi = new MenuItem(&parent, item, null, MenuType.baseMenu, false);
            this.mMenus ~= mi;
        }
        this.mMenuHandle = CreateMenu();
    }

    this (Window parent) {
        this.mParent = parent;
        this.mFont = parent.font;
        this.mMenuHandle = CreateMenu();
    }

    final void addMenu(wstring txt) {
        auto mi = new MenuItem(&this.mParent, txt, null, MenuType.baseMenu);
        this.mMenus ~= mi;
    }

    final void addMenu(wstring[] menuNames ...) {
        foreach (name; menuNames) {
            auto mi = new MenuItem(&this.mParent, name, null, MenuType.baseMenu);
            this.mMenus ~= mi;
        }
    }

    final void addMenu(wstring mnu, wstring[] subMenus) {
        auto m = new MenuItem(&this.mParent, mnu, null, MenuType.baseMenu);
        m.addMenu(subMenus);
        this.mMenus ~= m;
    }

    final void addMenu(MenuItem mi) { this.mMenus ~= mi;}

    final void create() {
        if (this.mMenus.length > 0 ) {
            foreach (menu; this.mMenus) { menu.create();}
            foreach (menu; this.mMenus) {
                AppendMenuW(this.mMenuHandle, menu.uFlag, cast(UINT_PTR) menu.handle, menu.text.ptr);
            }
        }
        SetMenu(this.mParent.handle, this.mMenuHandle);
    }

    final MenuItem[] menuItems() {return this.mMenus;}
    final ref MenuItem item(wstring value) {
        foreach (ref menu; this.mMenus) {if (menu.text == value) return menu;}
        throw new Exception("Can't find menu item");
    }


    private:
        HMENU mMenuHandle;
        MenuItem[] mMenus;

} // End of MenuBar class


class MenuItem {

    this (Window* pWin, wstring txt, MenuItem parent, MenuType mtyp, bool isChecked = false) {
        this.mTxt = txt;
        this.mType = mtyp;
        this.mId = idNum;
        this.mByPos = true;
        this.mChecked = isChecked;
        this.mOwnerWindow = pWin;
        ++idNum;
        this.mHandle = CreateMenu();
        if (parent) {
            this.mParent = parent;
            this.mParentHandle = parent.handle;
        }
    }

    this (MenuItem parent) {
        this.mParent = parent;
        this.mParentHandle = parent.handle;
        this.mType = MenuType.seperatorItem;
        this.mId = idNum;
        this.mTxt = format("Sep%s"w, this.mId);
        ++idNum;
        //this.mHandle = CreateMenu();
    }

    final void addMenu(wstring txt, MenuType mtp, bool checked = false ) {
        if (mtp == MenuType.baseMenu || mtp == MenuType.seperatorItem) {
            throw new Exception("Wrong menu type!");
        }
        auto mi = new MenuItem(this.mOwnerWindow, txt, this, mtp, checked);
        this.mMenus ~= mi;
    }

    final void addMenu(MenuItem mi) { this.mMenus ~= mi; }

    final void addMenu(wstring[] mnuNames ...) {
        if (this.mType == MenuType.normalItem) this.mType = MenuType.dropDownItem;
        foreach (name; mnuNames) {
            auto mi = new MenuItem(this.mOwnerWindow, name, this, MenuType.normalItem);
            this.mMenus ~= mi;

        }

    }

    final void addMenu(wstring mnu, wstring[] subMenus) {
        auto m1 = new MenuItem(this.mOwnerWindow, mnu, this, MenuType.normalItem);
        foreach (name; subMenus) {
            auto mi = new MenuItem(this.mOwnerWindow, name, m1, MenuType.normalItem);
            m1.mMenus ~= mi;
        }
        this.mMenus ~= m1;
    }

    final void addSeperator() {
        if (this.mType == MenuType.dropDownItem || this.mType == MenuType.baseMenu) {
            auto mi = new MenuItem(this);
            this.mMenus ~= mi;
        } else {
            throw new Exception("Seperator is only allowed for base menu & drop down menu");
        }

    }

    final void create() {
        if (this.mChecked) this.mFlag |= MF_CHECKED;
        switch (this.mType) {
            case MenuType.baseMenu, MenuType.dropDownItem:
                this.mFlag = MF_POPUP;
                if (this.mMenus.length > 0) foreach (menu; this.mMenus) { menu.create();}
                if (this.mType == MenuType.dropDownItem) {
                    AppendMenuW(this.parentHandle, this.uFlag, cast(UINT_PTR) this.mHandle, this.mTxt.ptr);
                }
                //printf("Name - %s, type - %s", this.text, this.mType);
            break;
            case MenuType.normalItem:
                this.mFlag = MF_STRING;
                AppendMenuW(this.parentHandle, this.mFlag, this.mId, this.mTxt.ptr);
                //printf("Name - %s,  p handle - %s", this.text, this.parentHandle);
            break;
            case MenuType.seperatorItem:
                this.mFlag = MF_SEPARATOR;
                this.mId = 0;
                AppendMenuW(this.parentHandle, this.mFlag, this.mId, null);
            break;
            default: break;
        }

    }

    final void text(wstring value) {
        this.mTxt = value;
        if (this.mCreated) {

        }

    }

    final wstring text() {return this.mTxt;}
    final uint uFlag() {return this.mFlag;}
    final uint menuID() {return this.mId;}
    final HMENU handle() {return this.mHandle;}
    final HMENU parentHandle() {return this.mParentHandle;}

    final ref MenuItem item(wstring value) {
        foreach (ref menu; this.mMenus) {if (menu.text == value) return menu;}
        throw new Exception("Can't find menu item");
    }

    final MenuItem[] menuItems() {return this.mMenus;}

    final void onClick(MenuEventHandler value) {
        this.mClickHandler = value;
        this.mOwnerWindow.setMenuClickHandler(this);
    }

    package final void clickHandler(EventArgs e) {this.mClickHandler(this, e);}



    private:
        HMENU mHandle;
        HMENU mParentHandle;
        uint mId;
        bool mByPos;
        bool mChecked;
        bool mCreated;
        wstring mTxt;
        MenuType mType;
        MenuItem[] mMenus;
        MenuItem mParent;
        uint mFlag;
        MenuEventHandler mClickHandler;
        Window* mOwnerWindow;
        static uint idNum = 1;


}

enum MenuType {
    baseMenu,
    normalItem,
    dropDownItem,
    seperatorItem,


}





