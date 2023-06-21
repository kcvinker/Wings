module wings.treeview; // Created on 27-July-2022 02:25 PM

import wings.d_essentials;
import wings.wings_essentials;

private int tvNumber = 1 ;
private DWORD tvStyle = WS_BORDER | WS_CHILD | WS_VISIBLE | TVS_HASLINES | TVS_HASBUTTONS |
                        TVS_LINESATROOT | TVS_DISABLEDRAGDROP;

alias TreeNodeNotifyHandler = void delegate(TreeNode node, string prop, void* data);
private wchar[] mClassName = ['S','y','s','T','r','e','e','V','i','e','w','3','2', 0];

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
        this.mName = format("%s_%d", "TreeView_", tvNumber);
        this.mParent.mControls ~= this;
        this.mCtlId = Control.stCtlId;
        ++Control.stCtlId;
        ++tvNumber;
    }

    this (Window parent, int x, int y) {this(parent, x, y, 250, 200);}
   // this (Window parent, int x, int y) {this(parent, x, y, 250, 200);}

    override void createHandle() {
    	this.setTvStyle();
    	this.createHandleInternal(mClassName.ptr);
    	if (this.mHandle) {
            this.setSubClass(&tvWndProc) ;
            if (this.mBackColor.value != 0xFFFFFF) this.sendMsg(TVM_SETBKCOLOR, 0, this.mBackColor.cref);
            if (this.mForeColor.value != defForeColor) this.sendMsg(TVM_SETTEXTCOLOR, 0, this.mForeColor.cref);
            if (this.mLineClr.value != defForeColor) this.sendMsg(TVM_SETLINECOLOR, 0, this.mLineClr.cref);
        }
    }

    final void addNode(TreeNode node) { this.addNodeInternal(NodeOps.addNode, node); }

    final void addNodes(TreeNode[] nodes...) {
        foreach (node; nodes) {this.addNodeInternal(NodeOps.addNode, node); }
    }

    final void insertNode(TreeNode node, int index) { this.addNodeInternal(NodeOps.insertNode, node, null, index); }

    final void addChildNode(TreeNode parent, TreeNode node) { this.addNodeInternal(NodeOps.addChild, node, parent); }

    final void addChildNodes(TreeNode parent, TreeNode[] nodes...) {
        foreach (node; nodes) { this.addNodeInternal(NodeOps.addChild, node, parent);}
    }

    final void insertChildNode(TreeNode parent, TreeNode node, int index) {
        // foreach (nod; parent.mNodes) {print("child ", nod.text);}
        this.addNodeInternal(NodeOps.insertChild, node, parent, index);
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
        int mNodeCount;
        int mUniqNodeID;

        void setTvStyle() {
            if (this.mNoLine) this.mStyle ^= TVS_HASLINES;
            if (this.mNoButton) this.mStyle ^= TVS_HASBUTTONS;
            if (this.mHasCheckBox) this.mStyle |= TVS_CHECKBOXES;
            if (this.mFullRowSel) this.mStyle |= TVS_FULLROWSELECT;
            if (this.mEditable) this.mStyle |= TVS_EDITLABELS;
            if (this.mShowSel) this.mStyle |= TVS_SHOWSELALWAYS;
            if (this.mHotTrack) this.mStyle |= TVS_TRACKSELECT;
            if (this.mNoButton && this.mNoLine) this.mStyle ^= TVS_LINESATROOT;
            // this.log(ULONG_PTR.sizeof, "  Size of ULONG_PTR");
            // this.log(LONG.sizeof, "  Size of ULONG");
        }

        TVITEMEXW makeTVitem(TreeNode node) {
            auto tvi = TVITEMEXW();
            tvi.mask = TVIF_TEXT | TVIF_PARAM;
            tvi.pszText = cast(LPWSTR) node.text.toUTF16z();
            tvi.cchTextMax = node.text.length;
            tvi.iImage = node.imageIndex;
            tvi.iSelectedImage = node.selectedImageIndex;
            tvi.stateMask = TVIS_USERMASK;
            if (node.imageIndex > -1) tvi.mask |= TVIF_IMAGE;
            if (node.selectedImageIndex > -1) tvi.mask |= TVIF_SELECTEDIMAGE;
            // if (node.foreColor.value != 0x000000) self._node_clr_change = True;
            return tvi;
        }

        void addNodeInternal(NodeOps nop, TreeNode node, TreeNode pnode = null, int pos = -1) {
            if (!this.mIsCreated) new Exception("TreeView's handle is not created");
            node.mIsCreated = true;
            node.mNotifyHandler = &(this.nodeNotifyHandler);
            node.mTreeHwnd = this.mHandle;
            node.mIndex = this.mNodeCount;
            node.mNodeID = this.mUniqNodeID; // We can identify any node with this

            auto tvi = this.makeTVitem(node);
            auto tis = TVINSERTSTRUCT();
            tis.itemex = tvi;
            tis.itemex.lParam = cast(LPARAM)(cast(void*) node);
            bool isRootNode = false;
            string errMsg = "Can't Add";

            switch(nop) {
            case NodeOps.addNode:
                tis.hParent = TVI_ROOT;
                tis.hInsertAfter = this.mNodeCount > 0 ? this.mNodes[this.mNodeCount - 1].mHandle : TVI_FIRST;
                isRootNode = true;
            break;

            case NodeOps.insertNode:
                tis.hParent = TVI_ROOT;
                tis.hInsertAfter = pos == 0 ? TVI_FIRST : this.mNodes[pos - 1].mHandle;
                isRootNode = true;
                errMsg = "Can't Insert";
            break;
            case NodeOps.addChild:
                tis.hInsertAfter = TVI_LAST;
                tis.hParent = pnode.mHandle;
                node.mParentNode = &pnode;
                errMsg = "Can't Add Child";
            break;
            case NodeOps.insertChild:
                tis.hParent = pnode.mHandle;
                tis.hInsertAfter = pos == 0 ? TVI_FIRST : pnode.mNodes[pos - 1].mHandle;
                node.mParentNode = &pnode;
                errMsg = "Can't Insert Child";
            break;
            default: break;
            }

            auto hItem =  cast(HTREEITEM) this.sendMsg(TVM_INSERTITEMW, 0, &tis);
            if (hItem) {
                node.mHandle = hItem;
                this.mUniqNodeID += 1;
                if (isRootNode) {
                    this.mNodes ~= node;
                    this.mNodeCount += 1;
                } else {
                    pnode.mNodes ~= node;
                    pnode.mNodeCount += 1;
                }
            } else {
                new Exception(format("%s node!, Error - %d", errMsg, GetLastError()));
            }


        }

        void nodeNotifyHandler(TreeNode node, string prop, void* data ) {
            print("Not implemented");
        }

} // End of TreeView class

class TreeNode {

    this (string txt) {
        mImgIndx = -1;
        mSelImgIndx = -1;
        mForClr = Color(0x000000);
        mBackClr = Color(0xFFFFFF);
        mTxt = txt;
    }

    final string text() {return this.mTxt;}
    final int imageIndex() {return this.mImgIndx;}
    final int selectedImageIndex() {return this.mSelImgIndx;}
    final int childCount() {return this.mChildCount;}
    final Color backColor() {return this.mBackClr;}
    final Color foreColor() {return this.mForClr;}
    // final Color is() {return this.mForClr;}

    private {
        HTREEITEM mHandle;
        HWND mTreeHwnd;
        TreeNode* mParentNode;
        TreeNode[] mNodes;
        int mImgIndx;
        int mSelImgIndx;
        int mChildCount;
        int mIndex;
        int mNodeID;
        int mNodeCount;
        Color mForClr;
        Color mBackClr;
        bool mChecked;
        bool mIsCreated;
        string mTxt;
        int mNodeId;
        TreeNodeNotifyHandler mNotifyHandler;
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
            case WM_DESTROY : RemoveWindowSubclass(hWnd, &tvWndProc, scID); break;

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

/*
alias FuncPtrType = void function(Foo bar, void* data);
class A {
    FuncPtrType notifyB;
    ...
}

class B {
    void someMethod(A a) {
        a.notifyB = &this.NotifyHandler;
        this.list_of_A ~= a;
    }

    void notifyHandler(Foo bar, void* data) {...}
    private:
        A[] list_of_A;
}
*/