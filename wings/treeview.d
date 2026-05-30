module wings.treeview; // Created on 27-July-2022 02:25 PM
/*==============================================TreeView Docs=====================================
    TreeView Class
        Constructor:
            this (Control parent, int x, int y)
            this (Control parent, int x, int y, int w, int h)

        Properties:
            TreeView inheriting all Control class properties	
            noLine              : bool
            noButton            : bool
            hasCheckBox         : bool
            fullRowSelect       : bool
            editableLabel       : bool
            showSelection       : bool
            lineColor           : Color
            selectedNode        : TreeNode
            nodes               : TreeNode[]
                
        Methods:
            createHandle  
            addNode
            addNodes
            insertNode
            addChildNode
            addChildNodes
            insertChildNode      
            
        Events:
            All public events inherited from Control class. (See controls.d)
            EventHandler - void delegate(Control, EventArgs)
    ------------------------------------------------------------------------------------
    TreeNode Class
        Constructor:
            this (string txt)
        Properties:
            text                : string
            imageIndex          : int
            selectedImageIndex  : int
            childCount          : int
            backColor           : Color
            foreColor           : Color
        Functions:
            NA
        Events:
            NA                   
=============================================================================================*/

import wings.d_essentials;
import wings.wings_essentials;

enum DWORD tvStyle = WS_BORDER | WS_CHILD | WS_VISIBLE | TVS_HASLINES | TVS_HASBUTTONS |
                        TVS_LINESATROOT | TVS_DISABLEDRAGDROP;

alias TreeNodeNotifyHandler = void delegate(TreeNode node, string prop, void* data);
private wchar[] mClassName = ['S','y','s','T','r','e','e','V','i','e','w','3','2', 0];

class TreeView: Control
{

    this (Control parent, int x, int y, int w, int h)
    {
        this.mControlType = ControlType.treeView;
        this.initControl(parent, x, y, w, h, &tvNumber);
        this.mLineClr = Color(defForeColor);
    }

    this (Control parent, int x, int y) {this(parent, x, y, 250, 200);}
   // this (Control parent, int x, int y) {this(parent, x, y, 250, 200);}

    override void createHandle()
    {
    	this.setTvStyle();
    	this.createHandleInternal();
    	if (this.mHandle) {
            this.setSubClass(&tvWndProc);
            if (this.mBackColor.value != 0xFFFFFF) this.sendMsg(TVM_SETBKCOLOR, 0, this.mBackColor.cref);
            if (this.mForeColor.value != defForeColor) this.sendMsg(TVM_SETTEXTCOLOR, 0, this.mForeColor.cref);
            if (this.mLineClr.value != defForeColor) this.sendMsg(TVM_SETLINECOLOR, 0, this.mLineClr.cref);
            if (this.mNodes.length > 0) {
                foreach (node; this.mNodes) {
                    this.insertAllNodes(node);
                }
            }   
        }
    }

    void addNode(T)(T node) { 
        auto tnode = this.getNode(node);
        this.insertNodeGeneric(this, tnode, 0, NodeOps.addNode);        
    }

    void addNodeWithChildren(T, U...)(T node, U children)
    {
        auto tnode = this.getNode(node);
        this.insertNodeGeneric(this, tnode, 0, NodeOps.addNode);
        if (children.length > 0) {
            foreach (child; children) {
                auto cnode = this.getNode(child);
                this.insertNodeGeneric(tnode, cnode, 0, NodeOps.addChild);
            }
        }
    }

    void addNodes(T...)(T[] nodes)
    {
        foreach (node; nodes) {
            auto tnode = this.getNode(node);
            this.insertNodeGeneric(this, tnode, 0, NodeOps.addNode); 
        }
    }


    void insertNode(T)(T node, int index) 
    { 
        auto tnode = this.getNode(node);
        this.insertNodeGeneric(this, tnode, index, NodeOps.insertNode);        
    }

    void addChildNode(T, U)(T parent, U node) 
    { 
        auto pnode = this.getNode(parent);
        auto cnode = this.getNode(node);
        if (pnode && cnode) {
            this.insertNodeGeneric(pnode, cnode, 0, NodeOps.addChild);
        }         
    }


    void addChildNodes(T, U)(T parent, U nodes...)
    {
        auto pnode = this.getNode(parent);
        if (pnode) {
            foreach (item; nodes) { 
                auto cnode = this.getNode(item);
                this.insertNodeGeneric(pnode, cnode, 0, NodeOps.addChild);
            }
        }
        
    }

    void insertChildNode(T, U)(T parent, U node, int index)
    {
        auto pnode = this.getNode(parent);
        auto cnode = this.getNode(node);
        if (pnode && cnode) {
            this.insertNodeGeneric(pnode, cnode, index, NodeOps.insertChild);
        }
    }

    // Properties============================= 
        mixin finalProperty!("noLine", this.mNoLine);
        mixin finalProperty!("noButton", this.mNoButton);
        mixin finalProperty!("hasCheckBox", this.mHasCheckBox);
        mixin finalProperty!("fullRowSelect", this.mFullRowSel);
        mixin finalProperty!("editableLabel", this.mEditable);
        mixin finalProperty!("showSelection", this.mShowSel);
        mixin finalProperty!("lineColor", this.mLineClr);
        
        TreeNode selectedNode() {
            if (!this.mIsCreated) return null;
            auto hSelItem = cast(HTREEITEM) this.sendMsg(TVM_GETNEXTITEM, TVGN_CARET, 0);
            if (hSelItem) {
                auto tvi = TVITEMEXW();
                tvi.hItem = hSelItem;
                tvi.mask = TVIF_PARAM;
                if (this.sendMsg(TVM_GETITEMW, 0, &tvi)) {
                    this.mSelNode = cast(TreeNode) cast(void*) tvi.lParam;
                    return this.mSelNode;
                }
            }
            return null;
        }

        void selectedNode(TreeNode node)
        {
            if (!this.mIsCreated) return;

            // If passing null, clear the selection entirely
            if (node is null) {
                this.sendMsg(TVM_SELECTITEM, TVGN_CARET, cast(LPARAM)null);
                return;
            }
            if (node && node.mHandle) {
                this.sendMsg(TVM_SELECTITEM, TVGN_CARET, cast(LPARAM) node.mHandle);
                this.mSelNode = node;
            }
        }

        TreeNode[] nodes() {return this.mNodes;}        
    // End of Properties================================
    

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
        static int tvNumber;

        void setTvStyle()
        {
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

        TreeNode getNode(T)(T obj)
        {
            TreeNode result = null;
            static if (is(T == TreeNode)) {
                result = obj;
            } else static if (is(T == string)) {
                result = new TreeNode(obj);
            } else {
                result = new TreeNode(to!string(obj));
            }
            return result;
        }

        // void tryAddNode(TreeNode node)
        // {
        //     node.mNodeOp = NodeOps.addNode;
        //     node.mInsAfter = TVI_LAST;
        //     node.mIndex = this.mNodeCount;
        //     node.mIsRoot = true;
        //     this.mNodeCount += 1;
        //     this.mNodes ~= node;
        //     node.mInList = true;
        //     if (this.handle) this.addNodeInternal(node);
        // }

        /* Use this function to add/insert root nodes and child nodes.
         * If it is insert operation, pos is valid, otherwise pos has no significance.
         * You can pass any value as pos if it is an add operation*/
        void insertNodeGeneric(T)(T container, TreeNode node, int pos, NodeOps nop)
        {
            // If insertion is the task, we need to check the pos carefully.
            if (nop == NodeOps.insertNode || nop == NodeOps.insertChild) {
                if (pos < 0 || pos >= container.mNodes.length) {
                    new Exception("Index is out of range!");
                } 
            }
            
            static if (is(T == TreeView)) {
                node.mIndex = this.mNodeCount;
                this.mNodeCount += 1;

            } else static if (is(T == TreeNode)) {
                node.mIndex = container.mChildCount;
                container.mChildCount += 1;

            } else {
                static assert(false, "Invalid type for container!");
            }
      
            node.mNodeOp = nop;
            if (nop == NodeOps.insertNode || nop == NodeOps.insertChild) {
                node.mInsAfter = pos == 0 ? TVI_FIRST : container.mNodes[pos - 1].mHandle;
            } else {
                node.mInsAfter = TVI_LAST;
            }            

            // Update counts and append to the specific container    
            container.mNodes ~= node;
            node.mInList = true;

            // Finalize the underlying Win32/internal tree structure
            if (this.mIsCreated) {
                static if (is(T == TreeView)) {
                    this.addNodeInternal(node);
                } else {
                    this.addNodeInternal(node, container);
                }
            }
        }


        void insertAllNodes(TreeNode node, TreeNode pnode = null) 
        {
            this.addNodeInternal(node, pnode);
            if (node.mNodes.length > 0) {
                foreach (tn; node.mNodes) {
                    this.insertAllNodes(tn, node);
                }
            }
        }
    


        void addNodeInternal(TreeNode node, TreeNode pnode = null)
        {
            node.mIsCreated = true;
            node.mNotifyHandler = &(this.nodeNotifyHandler);
            node.mTreeHwnd = this.mHandle;
            node.mNodeID = this.mUniqNodeID; // We can identify any node with this

            auto tvi = TVITEMEXW();
            tvi.mask = TVIF_TEXT | TVIF_PARAM;
            tvi.pszText = node.wtext;
            tvi.cchTextMax = 0;
            tvi.iImage = node.mImgIndx;
            tvi.iSelectedImage = node.mSelImgIndx;
            tvi.stateMask = TVIS_USERMASK;
            if (node.mImgIndx > -1) tvi.mask |= TVIF_IMAGE;
            if (node.mSelImgIndx > -1) tvi.mask |= TVIF_SELECTEDIMAGE;

            auto tis = TVINSERTSTRUCT();
            tis.itemex = tvi;
            tis.itemex.lParam = cast(LPARAM)(cast(void*) node);
            tis.hInsertAfter = node.mInsAfter;
            bool isRootNode = false;
            string errMsg = "Can't Add";

            switch(node.mNodeOp) {
                case NodeOps.addNode:
                    tis.hParent = TVI_ROOT;                    
                break;
                case NodeOps.insertNode:
                    tis.hParent = TVI_ROOT;
                    errMsg = "Can't Insert";
                break;
                case NodeOps.addChild:
                    tis.hParent = pnode.mHandle;
                    node.mParentNode = pnode;
                    errMsg = "Can't Add Child";
                break;
                case NodeOps.insertChild:
                    tis.hParent = pnode.mHandle;
                    node.mParentNode = pnode;
                    errMsg = "Can't Insert Child";
                break;
                default: break;
            }

            auto hItem =  cast(HTREEITEM) this.sendMsg(TVM_INSERTITEMW, 0, &tis);
            if (hItem) {
                node.mHandle = hItem;
                this.mUniqNodeID += 1;
            } else {
                new Exception(format("%s node!, Error - %d", errMsg, GetLastError()));
            }
        }

        void nodeNotifyHandler(TreeNode node, string prop, void* data )
        {
            print("Not implemented");
        }

} // End of TreeView class

class TreeNode
{

    this (string txt)
    {
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
    final LPWSTR wtext() {return this.mTxt.toLPWSTR();}
    // final Color is() {return this.mForClr;}

    package:
        int mImgIndx;
        int mSelImgIndx;
        int mChildCount;
        int mIndex;
        int mNodeID;
        int mNodeCount;
        int mInsertPos;
        HTREEITEM mHandle;
        HTREEITEM mInsAfter;
        HWND mTreeHwnd;
        TreeNode mParentNode;
        TreeNode[] mNodes;
        Color mForClr;
        Color mBackClr;
        bool mChecked;
        bool mIsCreated;
        bool mInList;
        bool mIsRoot;
        string mTxt;
        int mNodeId;
        NodeOps mNodeOp;

    private:           

        TreeNodeNotifyHandler mNotifyHandler;
    

} // End of TreeNode Class



mixin template msdown(alias ctl)
{
    mixin(ctl, `.lDownHappened = true;`);
    mixin(`if (`, ctl, `.onMouseDown) {`);
        mixin(`auto mea = new MouseEventArgs(message, wParam, lParam);`);
        mixin(ctl, `.onMouseDown(`, ctl, `mea);`);
        mixin(`return 0;`);
    mixin(`}`);
}



extern(Windows)
private LRESULT tvWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam,
                                                UINT_PTR scID, DWORD_PTR refData)
{
    try {
        TreeView self = getControl!TreeView(refData);
        auto res = self.commonMsgHandler(hWnd, message, wParam, lParam);
        if (res == MsgHandlerResult.callDefProc) {
            return DefSubclassProc(hWnd, message, wParam, lParam);
        } else if (res == MsgHandlerResult.returnZero || res == MsgHandlerResult.returnOne) {
            return cast(LRESULT) res;
        }
        switch (message) {
            case WM_DESTROY: 
                RemoveWindowSubclass(hWnd, &tvWndProc, scID); 
            break;
            case WM_PAINT: 
                self.paintHandler(); 
            break;
            default: return DefSubclassProc(hWnd, message, wParam, lParam);
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