module wings.numberpicker; // Created on : 10-Jun-22 05:24:04 PM

import wings.d_essentials;
import wings.wings_essentials;
import std.conv;



int npNumber = 1;
Wstring wcNpClass;
bool isNpCreated;
DWORD npStyle = WS_VISIBLE | WS_CHILD | UDS_ALIGNRIGHT | UDS_ARROWKEYS | 
                 UDS_AUTOBUDDY | UDS_HOTTRACK ;// | WS_BORDER;


class NumberPicker : Control {
    this(Window parent, int x, int y, int w, int h) {   
        if (!isNpCreated) {
            isNpCreated = true;
            wcNpClass = toUTF16z("msctls_updown32");
            appData.iccEx.dwICC = ICC_UPDOWN_CLASS ;
            InitCommonControlsEx(&appData.iccEx);
        }
        mWidth = w ;
        mHeight = h ;
        mXpos = x ;
        mYpos = y ;
        mParent = parent ;
        mFont = parent.font ;        
        mControlType = ControlType.numberPicker ;
        mMaxRange = 100;
        mMinRange = 0;   
        mDeciPrec = 0;
        mStep = 1;    
        mStyle = npStyle  ;
        mExStyle = 0 ;//WS_EX_LTRREADING | WS_EX_RTLREADING | WS_EX_CLIENTEDGE ;   ES_LEFT := 0x0  
        mBuddyStyle = WS_CHILD | WS_VISIBLE | ES_NUMBER | WS_TABSTOP | WS_CLIPCHILDREN  ;//| WS_BORDER ;
        mBuddyExStyle = WS_EX_STATICEDGE | WS_EX_LEFT ;//WS_EX_LTRREADING | WS_EX_RTLREADING | WS_EX_LEFT ;//| WS_EX_CLIENTEDGE;  
        mBackColor = defBackColor ;
        mForeColor = defForeColor;
        mBClrRef = getClrRef(defBackColor) ;
        mFClrRef = getClrRef(this.mForeColor) ;
        mClsName = wcNpClass ; 
        mFmtStr = "%.02f" ;
        mValue = mMinRange;
        ++npNumber;                   
    }

    this(Window parent) {this(parent, 10, 10, 100, 27);}
    this(Window parent, int x, int y) {this(parent, x, y, 100, 27);}

    final void create() {
    	this.adjustNpStyles() ;        
        this.createHandle();    
        if (this.mHandle) {     // Creating buddy edit control.
            this.mBuddyHandle = CreateWindowEx( this.mBuddyExStyle, 
                                                toUTF16z("Edit"), 
                                                null, 
                                                this.mBuddyStyle, 
                                                this.mXpos, 
                                                this.mYpos,
                                                this.mWidth,
                                                this.mHeight, 
                                                this.mParent.handle, 
                                                cast(HMENU) this.mCtlId, 
                                                appData.hInstance, 
                                                null);
            if (this.mBuddyHandle) {
                this.mBuddySubClsID = Control.mSubClassId;
                this.mBuddySubClsProc = &buddyWndProc;
                ++Control.mSubClassId;
                SendMessageW(this.mBuddyHandle, WM_SETFONT, cast(WPARAM) this.mFont.handle, cast(LPARAM) 1) ;                 
                this.sendMsg(UDM_SETBUDDY, this.mBuddyHandle, 0) ;
                this.setSubClass(&npWndProc) ;
                SetWindowSubclass(this.mBuddyHandle, &buddyWndProc, UINT_PTR(Control.mSubClassId), this.toDwPtr());
                this.sendMsg(UDM_SETRANGE32, cast(WPARAM) this.mMinRange, cast(LPARAM) this.mMaxRange); 
                this.displayValue;
                this.setMouseLeaveInfo;
                //this.sendMsg(UDM_SETPOS32, 0, this.mMinRange);               
                
            }               
                        
                      
           
                           
        }        
    }

    final void minRange(double value) {
        this.mMinRange = value;
        if (this.mIsCreated) {
            this.sendMsg(UDM_SETRANGE32, this.mMinRange, this.mMaxRange);
        }
    }
    final double minRange() {return this.mMinRange;}

    final void maxRange(double value) {
        this.mMaxRange = value;
        if (this.mIsCreated) {
            this.sendMsg(UDM_SETRANGE32, this.mMinRange, this.mMaxRange);
        }
    }
    final double maxRange() {return this.mMaxRange;}

    final bool hideSelection() {return this.mHideSel;}
    final void hideSelection(bool value) {
        this.mHideSel = value;
        if (this.mIsCreated) {
            SendMessage(this.mBuddyHandle, EM_SETSEL, cast(WPARAM) -1, 0 );
        }
    }

    final bool buttonOnLeft() {return this.mBtnLeft;}
    final void buttonOnLeft(bool value) {
        this.mBtnLeft = value;
        if (this.mIsCreated) {
            // TODO - change window style using SetWindowLong function.
        }
        
    }

    final TextPosition textPosition() {return this.mTxtPos;}
    final void textPosition(TextPosition value) {
        this.mTxtPos = value;
        if (this.mIsCreated) {
            // TODO - change window style using SetWindowLong function.
        }
        
    }

    final bool hasSeperator() {return this.mHasSep;}
    final void hasSeperator(bool value) {
        this.mHasSep = value;
        if (this.mIsCreated) {
            // TODO - change window style using SetWindowLong function.
        }
    }

    final bool rotateValue() {return this.mAutoRotate;}
    final void rotateValue(bool value) {
        this.mAutoRotate = value;
        if (this.mIsCreated) {
            // TODO - change window style using SetWindowLong function.
        }
    }

    final double value() {return this.mValue;}
    final void value(double value) {
        this.mValue = value;
        if (this.mIsCreated) this.displayValue();
    }

    final double step() {return this.mStep;}
    final void step(double value) {
        this.mStep = value;
        if (this.mIsCreated) {
            // TODO - change window style using SetWindowLong function.
        }
    }

    final string formatString() {return this.mFmtStr;}
    final void formatString(string value) {
        this.mFmtStr = value;
        if (this.mIsCreated) {
            // TODO - change window style using SetWindowLong function.
        }
    }

    final int decimalPrecision() {return this.mDeciPrec;}
    final void decimalPrecision(int value) {
        this.mDeciPrec = value;
        if (this.mIsCreated) {
            // TODO - change window style using SetWindowLong function.
        }
    }

    final void onMouseEnter(EventHandler value) {
        this.mOnMouseEnter = value;
        this.mTrackMouseLeave = true;
    }
    final void onMouseLeave(EventHandler value) {
        this.mOnMouseLeave = value;
        this.mTrackMouseLeave = true;
    }
    final void onMouseMove(MouseEventHandler value) {
        this.mOnMouseMove = value;
        this.mTrackMouseLeave = true;
    }

    EventHandler onValueChanged ;
    PaintEventHandler onTextPaint; 
    //alias uintptr = UINT_PTR;
    package :
        bool mEditStarted;
        bool mEditFinished;
        bool mHideSel;
        bool mTrackMouseLeave;
        string mEditedText;
        RECT mUDRect;
        RECT mTBRect;
        EventHandler mOnMouseLeave;
        EventHandler mOnMouseEnter;
        MouseEventHandler mOnMouseMove;
        

        final void finalize(UINT_PTR subClsId) { // Package
            if (this.mBkBrush) DeleteObject(this.mBkBrush);
            this.remSubClass(subClsId );        
        }

        final void finalizeBuddy(UINT_PTR subClsId) { // Package
            RemoveWindowSubclass(this.mBuddyHandle, this.mBuddySubClsProc, subClsId );
        }

        final void checkEditedValue() {
            // Sometimes user wants to directly type text into edit box.
            // In such situations, we need to take special care in processing the text.
            // Here, we are collecting users input from WM_KEYDOWN message and keep it...
            // in "mEditedValue" variable.
            //print("checkEditedValue started with ", this.mEditedText);
            auto newValue = to!double(this.mEditedText);           
            if (newValue > this.mMaxRange) {
                newValue = this.mMaxRange;
            } else if (newValue < this.mMinRange) {
                newValue = this.mMinRange;
            } 
            //print("checkEditedValue else condition");
            this.mValue = newValue;
            auto newStr = format(this.mFmtStr, this.mValue);
            SetWindowTextW(this.mBuddyHandle, newStr.toUTF16z);            
        }

        final void setValueInternal(NumPickOp op) { // Package
            double newValue;            
            switch (op) {
                case NumPickOp.opAdd :
                    newValue = this.mValue + this.mStep;                    
                    if (this.mAutoRotate) {
                        this.mValue = (newValue > this.mMaxRange) ? this.mMinRange : newValue;                        
                    } else {
                        this.mValue = (newValue > this.mMaxRange) ? this.mMaxRange : newValue; 
                    } break;
                case NumPickOp.opSub :
                    newValue = this.mValue - this.mStep;
                    if (this.mAutoRotate) {
                        this.mValue = (newValue < this.mMinRange) ? this.mMaxRange : newValue;                        
                    } else {
                        this.mValue = (newValue < this.mMinRange) ? this.mMinRange : newValue; 
                    } break;   
                case NumPickOp.none :
                    if (this.mValue > this.mMaxRange) this.mValue = this.mMaxRange;
                    if (this.mValue < this.mMinRange) this.mValue = this.mMinRange;
                    break;

                default : break;
            }
            this.displayValue;
        }

        final void displayValue() { // Package
            auto newStr = format(this.mFmtStr, this.mValue);
            SetWindowTextW(this.mBuddyHandle, newStr.toUTF16z);
        }

        final bool checkMousePosUD(HWND hw) {
            POINT pt ;
            GetCursorPos(&pt);
            ScreenToClient(hw, &pt);
            bool xFlag = (pt.x == (this.mUDRect.left + 1) ) ? true : false;
            bool yFlag = (pt.y > this.mUDRect.top && pt.y < this.mUDRect.bottom) ? true : false;
            return (xFlag == false && yFlag == false) ? true : false;
        }

        final bool checkMousePosTB(HWND hw) {
            POINT pt ;
            GetCursorPos(&pt);
            ScreenToClient(hw, &pt);
            bool xFlag = (pt.x == this.mTBRect.right) ? true : false;
            bool yFlag = (pt.y > this.mTBRect.top && pt.y < this.mTBRect.bottom) ? true : false;
            return (xFlag == false && yFlag == false) ? true : false;
        }

        
     
    private :
        bool mBtnLeft;
        TextPosition mTxtPos;
        bool mHasSep;
        bool mAutoRotate;
        
        double mMinRange;
        double mMaxRange;
        double mValue;
        double mStep ;
        string mFmtStr;
        int mDeciPrec;
        DWORD mBuddyStyle;
        DWORD mBuddyExStyle;
        HWND mBuddyHandle;
        uint mBuddySubClsID;
        SUBCLASSPROC mBuddySubClsProc;
        double mEditedValue;
        
        HBRUSH mBkBrush;

        void adjustNpStyles() { // Private
            if (this.mBtnLeft) {
                this.mStyle ^= UDS_ALIGNRIGHT;
                this.mStyle |= UDS_ALIGNLEFT;
            }
            if (!this.mHasSep) this.mStyle |= UDS_NOTHOUSANDS;
            
            switch (this.mTxtPos) {
                case TextPosition.left : this.mBuddyStyle |= ES_LEFT; break;  
                case TextPosition.center : this.mBuddyStyle |= ES_CENTER; break;
                case TextPosition.right : this.mBuddyStyle |= ES_RIGHT; break;
                default : break;
            }

        }

        void setMouseLeaveInfo() { // Private
            /* Since we are subclassing the buddy control( Edit control), the mouse leave event...
            is a big problem. We need to track the mouse position on mouse leave in both WndProc.
            These rect structs will save the edit control's bounds. So we can check this...
            in mouse leave events. */
            GetClientRect(this.mHandle, &this.mUDRect);
            GetClientRect(this.mBuddyHandle, &this.mTBRect);
            // print("own rect", this.mUDRect);
            // print("buddy rect", this.mTBRect);
        }

        

        


} // End of NumberPicker class

extern(Windows)
private LRESULT npWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData)  {
    try {   
        
        NumberPicker np = getControl!NumberPicker(refData)  ;
        //printWinMsg(message);
        switch (message) {
            case WM_DESTROY :
                np.finalize(scID) ;
                np.remSubClass(scID);
                break ;

            case WM_PAINT :
                if (np.onPaint) {
                    PAINTSTRUCT  ps ;
                    BeginPaint(hWnd, &ps) ;
                    auto pea = new PaintEventArgs(&ps) ;
                    np.onPaint(np, pea) ;
                    EndPaint(hWnd, &ps) ;
                    return 0 ;
                }  break ;

            case CM_NOTIFY :
                auto nm = cast(NMUPDOWN*) lParam;
                if (nm.hdr.code == UDN_DELTAPOS) {
                    if (np.mEditStarted) {                        
                        np.mEditStarted = false;
                        np.mEditFinished = true;                        
                        //np.mEditedText = np.getControlText(np.mBuddyHandle);                        
                        np.mValue = parse!double(np.mEditedText);                       
                    }
                    if (nm.iDelta == 1) {                        
                        np.setValueInternal(NumPickOp.opAdd);
                    } else {
                        np.setValueInternal(NumPickOp.opSub);
                    }
                }                     
                if (np.onValueChanged) {
                    auto ea = new EventArgs();
                    np.onValueChanged(np, ea);                    
                }                
                break ;

            case WM_MOUSEMOVE :
                if (np.isMouseEntered) {
                    if (np.mOnMouseMove) {
                        auto mea = new MouseEventArgs(message, wParam, lParam) ;
                        np.mOnMouseMove(np, mea) ;
                    }
                } else {
                    np.isMouseEntered = true ;
                    if (np.mOnMouseEnter) {
                        auto ea = new EventArgs() ;
                        np.mOnMouseEnter(np, ea) ;
                    }
                } break ;

            case WM_MOUSELEAVE :
                if (np.mTrackMouseLeave) {
                    if (np.checkMousePosUD(hWnd)) {
                        np.isMouseEntered = false;
                        if (np.mOnMouseLeave) {
                            auto ea = new EventArgs() ;
                            np.mOnMouseLeave(np, ea) ;
                        } 
                    }
                } break;
            
            case WM_LBUTTONDOWN : 
                np.lDownHappened = true ;  
                if (np.onMouseDown) {
                   auto mea = new MouseEventArgs(message, wParam, lParam);
                   np.onMouseDown(np, mea) ;
                   return 0 ;
                } break ;            

            case WM_LBUTTONUP :
                if (np.onMouseUp) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    np.onMouseUp(np, mea) ;                    
                }
                if (np.lDownHappened) {
                    np.lDownHappened = false ;
                    sendMsg(np.handle, CM_LEFTCLICK, 0, 0) ;                    
                } break ;

            case CM_LEFTCLICK :
                if (np.onMouseClick) {
                    auto ea = new EventArgs() ;
                    np.onMouseClick(np, ea) ;
                } break ;

            case WM_RBUTTONDOWN :
                np.rDownHappened = true ;
                if (np.onRightMouseDown) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    np.onRightMouseDown(np, mea) ; 
                    return 0 ;
                } break ;

            case WM_RBUTTONUP :
                if (np.onRightMouseUp) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    np.onRightMouseUp(np, mea) ;                     
                } 
                if (np.rDownHappened) {
                    np.rDownHappened = false ;
                    sendMsg(np.handle, CM_RIGHTCLICK, 0, 0) ;                    
                } break ;

            case CM_RIGHTCLICK :
                if (np.onRightClick) {
                    auto ea = new EventArgs() ;
                    np.onRightClick(np, ea) ;
                } break ;
            
            

                
                
            
            
            
            default : return DefSubclassProc(hWnd, message, wParam, lParam) ;
        }
    }
    catch (Exception e) {}     
    return DefSubclassProc(hWnd, message, wParam, lParam);
}

extern(Windows)
private LRESULT buddyWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR scID, DWORD_PTR refData)  {
    try {   
        NumberPicker np = getControl!NumberPicker(refData)  ;
        //printWinMsg(message);
        switch (message) {
            case WM_DESTROY :
                np.finalizeBuddy(scID);
                break ;

            case WM_PAINT :
                if (np.onPaint) {
                    PAINTSTRUCT ps ;
                    BeginPaint(hWnd, &ps) ;
                    auto pea = new PaintEventArgs(&ps) ;
                    np.onTextPaint(np, pea) ;
                    EndPaint(hWnd, &ps) ;
                    return 0 ;
                } break;            
            
            case EM_SETSEL :
                if (np.mHideSel) return 1;
                break;

            case CM_CTLCOLOR :                
                if (np.mForeColor != defForeColor || np.mBackColor != defBackColor) {
                    auto hdc = cast(HDC) wParam;
                    SetBkMode(hdc, TRANSPARENT);
                    if (np.mForeColor != defForeColor) SetTextColor(hdc, np.mFClrRef);
                    np.mBkBrush = CreateSolidBrush(np.mBClrRef);
                    return cast(LRESULT) np.mBkBrush;
                }
                break;

            case WM_KEYDOWN :
                auto kea = new KeyEventArgs(wParam);
                if (!np.mEditStarted) {
                    // If it's not an arrow key press...
                    if (kea.keyCode != Key.upArrow && kea.keyCode != Key.downArrow) {
                        np.mEditStarted = true;
                        np.mEditFinished = false;
                    }
                }
                if (np.onKeyDown) np.onKeyDown(np, kea);
                break;

            case WM_KEYUP :                
                auto kea = new KeyEventArgs(wParam);
                if (kea.keyCode == Key.enter || kea.keyCode == Key.tab) {                    
                    np.mEditFinished = true;
                    np.mEditStarted = false;
                    np.mValue = parse!double(np.mEditedText); 
                    np.setValueInternal(NumPickOp.none);
                    //np.mEditedText = np.getControlText(hWnd);

                }
                if (np.mEditFinished) np.checkEditedValue;
                if (np.onKeyUp) np.onKeyUp(np, kea);
                SendMessageW(hWnd, CM_TBTXTCHANGED, 0, 0);
                return 0;
                break;
            
            case WM_CHAR :
                if (np.onKeyPress) {
                    auto kea = new KeyEventArgs(wParam);
                    np.onKeyPress(np, kea);
                    return 0;
                } break;

            case CM_TBTXTCHANGED :
                if (np.onValueChanged) {
                    auto ea = new EventArgs();
                    np.onValueChanged(np, ea);
                } break;

            case WM_MOUSEMOVE :
                if (np.isMouseEntered) {
                    if (np.mOnMouseMove) {
                        auto mea = new MouseEventArgs(message, wParam, lParam);
                        np.mOnMouseMove(np, mea);
                    }
                } else {
                    np.isMouseEntered = true;
                    if (np.mOnMouseEnter) {
                        auto ea = new EventArgs();
                        np.mOnMouseEnter(np, ea);
                    }
                }
                break;
            
            case WM_MOUSELEAVE :
                if (np.mTrackMouseLeave) { 
                    if (np.checkMousePosTB(hWnd)) {                        
                        np.isMouseEntered = false;
                        if (np.mOnMouseLeave) {
                            auto ea = new EventArgs();
                            np.mOnMouseLeave(np, ea);
                        }
                    }
                } break;

            case WM_LBUTTONDOWN : 
                np.lDownHappened = true ;  
                if (np.onMouseDown) {
                   auto mea = new MouseEventArgs(message, wParam, lParam);
                   np.onMouseDown(np, mea) ;
                   return 0 ;
                } break ;            

            case WM_LBUTTONUP :
                if (np.onMouseUp) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    np.onMouseUp(np, mea) ;                    
                }
                if (np.lDownHappened) {
                    np.lDownHappened = false ;
                    sendMsg(np.handle, CM_LEFTCLICK, 0, 0) ;                    
                } break ;

            case CM_LEFTCLICK :
                if (np.onMouseClick) {
                    auto ea = new EventArgs() ;
                    np.onMouseClick(np, ea) ;
                } break ;

            case WM_RBUTTONDOWN :
                np.rDownHappened = true ;
                if (np.onRightMouseDown) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    np.onRightMouseDown(np, mea) ; 
                    return 0 ;
                } break ;

            case WM_RBUTTONUP :
                if (np.onRightMouseUp) {
                    auto mea = new MouseEventArgs(message, wParam, lParam) ;
                    np.onRightMouseUp(np, mea) ;                     
                } 
                if (np.rDownHappened) {
                    np.rDownHappened = false ;
                    sendMsg(np.handle, CM_RIGHTCLICK, 0, 0) ;                    
                } break ;

            case CM_RIGHTCLICK :
                if (np.onRightClick) {
                    auto ea = new EventArgs() ;
                    np.onRightClick(np, ea) ;
                } break ;

            case CM_CTLCOMMAND :
                auto nCode = HIWORD(wParam);
                if (nCode == EN_UPDATE) {
                    if (np.mEditStarted) np.mEditedText = np.getControlText(hWnd);
                } break;
            
            default : return DefSubclassProc(hWnd, message, wParam, lParam) ;
        }
    }
    catch (Exception e) {}     
    return DefSubclassProc(hWnd, message, wParam, lParam);
}
