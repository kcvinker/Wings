module wings.treeview; // Created on 27-July-2022 02:25 PM

import wings.d_essentials;
import wings.wings_essentials;

private int tvNumber = 1 ;
private DWORD tvStyle = WS_BORDER | WS_CHILD | WS_VISIBLE | TVS_HASLINES | TVS_HASBUTTONS |
                        TVS_LINESATROOT | TVS_DISABLEDRAGDROP;

class TreeView : Control {

    this (Window parent, int x, int y, int w, int h)
    {
        mixin(repeatingCode);
        mControlType = ControlType.treeView ;
        mStyle = tvStyle ;
        mExStyle = 0;// | WS_EX_LEFT ;
        mBackColor(0xFFFFFF) ;
        mForeColor(defForeColor);
        mLineClr(defForeColor);
        mClsName = "SysTreeView32" ;
        this.mName = format("%s_%d", "TreeView_", tvNumber);
        ++tvNumber;
    }

    this (Window parent, int x, int y) {this(parent, x, y, 250, 200);}
   // this (Window parent, int x, int y) {this(parent, x, y, 250, 200);}

    void create() {
    	this.setTvStyle();
    	this.createHandle();
    	if (this.mHandle) {
            this.setSubClass(&tvWndProc) ;
            if (this.mBackColor.value != 0xFFFFFF) this.sendMsg(TVM_SETBKCOLOR, 0, this.mBackColor.reff);
            if (this.mForeColor.value != defForeColor) this.sendMsg(TVM_SETTEXTCOLOR, 0, this.mForeColor.reff);
            if (this.mLineClr.value != defForeColor) this.sendMsg(TVM_SETLINECOLOR, 0, this.mLineClr.reff);
        }
    }


    private:
        bool mNoLine;
        bool mNoButton;
        bool mHasCheckBox;
        bool mFullRowSel;
        bool mEditable;
        bool mShowSel;
        bool mHotTrack;
        Color mLineClr;

        TreeNode mSelNode;
        TreeNode[] mNodes;

        void setTvStyle() {
            if (this.mNoLine) this.mStyle ^= TVS_HASLINES;
            if (this.mNoButton) this.mStyle ^= TVS_HASBUTTONS;
            if (this.mHasCheckBox) this.mStyle |= TVS_CHECKBOXES;
            if (this.mFullRowSel) this.mStyle |= TVS_FULLROWSELECT;
            if (this.mEditable) this.mStyle |= TVS_EDITLABELS;
            if (this.mShowSel) this.mStyle |= TVS_SHOWSELALWAYS;
            if (this.mHotTrack) this.mStyle |= TVS_TRACKSELECT;
            if (this.mNoButton && this.mNoLine) this.mStyle ^= TVS_LINESATROOT;
        }


} // End of TreeView class

class TreeNode {

    this () {

    }

    private {
        HTREEITEM mHandle;
        TreeNode* mParentNode;
        TreeNode[] mNodes;
        int mImgIndx;
        int mSelImgIndx;
        int mChildCount;
        Color mForClr;
        Color mBackClr;
        bool mChecked;
        string mTxt;
    }




} // End of TreeNode Class

mixin template msdown(alias ctl) {
    mixin(ctl, `.lDownHappened = true ;`);
    mixin(`if (`, ctl, `.onMouseDown) {`);
        mixin(`auto mea = new MouseEventArgs(message, wParam, lParam);`);
        mixin(ctl, `.onMouseDown(`, ctl, `mea) ;`);
        mixin(`return 0 ;`);
    mixin(`}`);
}



extern(Windows)
private LRESULT tvWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData) {

    try {
        TreeView tv = getControl!TreeView(refData)  ;
        switch (message) {
            case WM_DESTROY :
                //tv.finalize ;
                tv.remSubClass(scID);
            break ;

            case WM_PAINT : tv.paintHandler(); break;
            case WM_SETFOCUS : tv.setFocusHandler(); break;
            case WM_KILLFOCUS : tv.killFocusHandler(); break;
            case WM_LBUTTONDOWN : tv.mouseDownHandler(message, wParam, lParam); break ;
            case WM_LBUTTONUP : tv.mouseUpHandler(message, wParam, lParam); break ;
            case CM_LEFTCLICK : tv.mouseClickHandler(); break;
            case WM_RBUTTONDOWN : tv.mouseRDownHandler(message, wParam, lParam); break;
            case WM_RBUTTONUP : tv.mouseRUpHandler(message, wParam, lParam); break;
            case CM_RIGHTCLICK : tv.mouseRClickHandler(); break;
            case WM_MOUSEWHEEL : tv.mouseWheelHandler(message, wParam, lParam); break;
            case WM_MOUSEMOVE : tv.mouseMoveHandler(message, wParam, lParam); break;
            case WM_MOUSELEAVE : tv.mouseLeaveHandler(); break;

            default : return DefSubclassProc(hWnd, message, wParam, lParam) ;
        }

    }
    catch (Exception e) {}
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

