// messagebox.d - Created on 15-Aug-2024 04:32

module wings.messagebox;

import core.sys.windows.windows;
//import std.stdio;
import std.utf;
enum MsgBoxResult {
    okay = 1, cancel, abort, retry, ignore, yes, no, tryAgain, continue_,
}
enum MsgBoxButton {
    okOnly, okCancel, abortRetryIgnore, yesNocancel, yesNo, retrycancel,
    cancelRetryContinue, 
}
enum MsgBoxIcon {
    error = 0x00000010, 
    question = 0x00000020, 
    warning = 0x00000030, 
    info = 0x00000040
}
enum WCHAR[] defTitle = ['W', 'i', 'n', 'g', 's', ' ', 'M', 'e', 's', 's', 'a', 'e', 0];

void msgBox(string msg) {
	MessageBoxW(null, msg.toUTF16z, defTitle.ptr, 0 );
}

void msgBox(HWND hw, string msg) {
	MessageBoxW(hw, msg.toUTF16z, defTitle.ptr, 0 );
}

void msgBox(string msg, string title) {
	MessageBoxW(null, msg.toUTF16z, title.toUTF16z, 0 );
}

void msgBox(HWND hw, string msg, string title) {
	MessageBoxW(hw, msg.toUTF16z, title.toUTF16z, 0 );
}

MsgBoxResult msgBox(string msg, string title, MsgBoxButton mbutton = MsgBoxButton.okOnly) {
	UINT msgtyp = cast(UINT)mbutton;
	int x = MessageBoxW(null, msg.toUTF16z, title.toUTF16z, msgtyp );
	return cast(MsgBoxResult)x;
}

MsgBoxResult msgBox(HWND hw, string msg, string title, MsgBoxButton mbutton = MsgBoxButton.okOnly) {
	UINT msgtyp = cast(UINT)mbutton;
	int x = MessageBoxW(hw, msg.toUTF16z, title.toUTF16z, msgtyp );
	return cast(MsgBoxResult)x;
}

MsgBoxResult msgBox(string msg, string title, MsgBoxButton mbutton, MsgBoxIcon micon = MsgBoxIcon.info )
{
    UINT msgtyp = cast(UINT)mbutton | cast(UINT)micon;
    int x = MessageBoxW(null, msg.toUTF16z, title.toUTF16z, msgtyp );
    return cast(MsgBoxResult)x;
}

MsgBoxResult msgBox(HWND hw, string msg, string title, MsgBoxButton mbutton, MsgBoxIcon micon = MsgBoxIcon.info )
{
    UINT msgtyp = cast(UINT)mbutton | cast(UINT)micon;
    int x = MessageBoxW(hw, msg.toUTF16z, title.toUTF16z, msgtyp );
    return cast(MsgBoxResult)x;
}