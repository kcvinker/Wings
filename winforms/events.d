module winglib.events;


private import core.sys.windows.winuser;
private import core.sys.windows.windef;

private import winglib.enums;
private import winglib.key_enums;

private import winglib.commons;
private import winglib.controls;

import std.stdio;

/// This module is for events

immutable uint um_single_Click = WM_USER + 1 ;
//immutable uint um_right_click = WM_USER + 2;



alias EventHandler = void function(Control sender, EventArgs e) ;
alias KeyEventHandler = void function(Control sender, KeyEventArgs e) ;
alias KeyPressEventHandler = void function(Control sender, KeyPressEventArgs e) ;
alias MouseEventHandler = void function(Control sender, MouseEventArgs e) ;


WORD getKeyStateWparam(WPARAM wp) {return cast(WORD) LOWORD(wp) ;}

/// A base class for all events
class EventArgs { bool handled ; }

/// Special events for mouse related messages
class MouseEventArgs : EventArgs {

    MouseButtons button ;
    int clicks ;
    int delta ;
    MouseButtonState shiftKey ;
    MouseButtonState crtlKey ;
    POINT location ;
    int x ;
    int y ;

    this(UINT msg, WPARAM wp, LPARAM lp) {
        const auto fwKeys = getKeyStateWparam(wp) ;
       // writeln("fw_keys ", fwKeys) ;
        this.delta = GET_WHEEL_DELTA_WPARAM(wp) ;
        
        switch (fwKeys) {   // IMPORTANT*********** Work here --> change 4 to 5, 8 to 9 etc
            case 4 :
                this.shiftKey = MouseButtonState.pressed ;
                break ;
            case 8 :
                this.crtlKey = MouseButtonState.pressed ;
                break ;
            case 16 :
                this.button = MouseButtons.middle ;
                break ;
            case 32 :
                this.button = MouseButtons.xButton1 ;
                break ;
            default : break ;
        }

        switch (msg) {
            case WM_MOUSEWHEEL, WM_MOUSEMOVE, WM_MOUSEHOVER, WM_NCHITTEST :
                this.x = getXFromLp(lp) ;
                this.y = getYFromLp(lp) ;
                break ;
            case WM_LBUTTONDOWN, WM_LBUTTONUP : 
                this.button = MouseButtons.left ;
                this.x = getXFromLp(lp) ;
                this.y = getYFromLp(lp) ;
                break ;
            case WM_RBUTTONDOWN, WM_RBUTTONUP : 
                this.button = MouseButtons.right ;
                this.x = getXFromLp(lp) ;
                this.y = getYFromLp(lp) ;
                break ;
            default : break ;
        }
    }
}


class KeyEventArgs : EventArgs {

    bool alt ;
    bool control ;        
    Key keyCode ;      
    int keyValue ;
    Key modifiers ;
    bool shift ;
    bool suppressKeyPress ;

    this(WPARAM wp) {
        this.keyCode = cast(Key) wp ;
        switch (this.keyCode) {
        	case Key.shift :
        		this.shift = true ;
        		this.modifiers = Key.shiftModifier ;
        		break ;
        	case Key.ctrl :
        		this.control = true ;
        		this.modifiers = Key.ctrlModifier ;
        		break ;
        	case Key.alt : 
            	this.alt = true ;
            	this.modifiers = Key.altModifier ;
            	break ;
            default : break ;
        }
        this.keyValue = this.keyCode ;        
    }
}


class KeyPressEventArgs : EventArgs {
	char keyChar ;
	this(WPARAM wp) {this.keyChar = cast(char) wp ;}
}



// struct ClickData
// {
//     int downTime;
//     int upTime;
//     int rightDownTime;
//     int rightUpTime;
//     bool downFlag;
// }


