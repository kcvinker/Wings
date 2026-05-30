module wings.ctl_static_data;

import core.sys.windows.windows;
import core.sys.windows.commctrl;
import wings.enums: BackColorMode;

// import std.stdio, std.traits;

alias ImmutWcharArr = immutable(wchar)[];

immutable ImmutWcharArr WCNFORM        = "Wings_Window_Class\0";
immutable ImmutWcharArr WCNMSGONLYWIN  = "Wings_MsgForm_Class\0";
immutable ImmutWcharArr WCNBUTTON      = "Button\0";
immutable ImmutWcharArr WCNCALENDAR    = "SysMonthCal32\0";
immutable ImmutWcharArr WCNCOMBO       = "ComboBox\0";
immutable ImmutWcharArr WCNDTP         = "SysDateTimePick32\0";
immutable ImmutWcharArr WCNSTATIC      = "Static\0";
immutable ImmutWcharArr WCNLISTBOX     = "ListBox\0";
immutable ImmutWcharArr WCNLISTVIEW    = "SysListView32\0";
immutable ImmutWcharArr WCNNUMPICK     = "msctls_updown32\0";
immutable ImmutWcharArr WCNPICTUREBOX  = "Wings_PictureBox\0";
immutable ImmutWcharArr WCNPROGRESSBAR = "msctls_progress32\0";
immutable ImmutWcharArr WCNEDIT        = "Edit\0";
immutable ImmutWcharArr WCNTRACKBAR    = "msctls_trackbar32\0";
immutable ImmutWcharArr WCNTREEVIEW    = "SysTreeView32\0";

// Common styles for all controls. These styles are used in CreateWindowExW function when creating controls.
    immutable UINT COMM_CTRL_STYLES = WS_CHILD | WS_VISIBLE | WS_TABSTOP;

    immutable UINT WSTYLE_BUTTON    = COMM_CTRL_STYLES | BS_NOTIFY;
    immutable UINT WSTYLE_CALENDAR  = COMM_CTRL_STYLES;

    immutable UINT WSTYLE_CHECK_BOX  = COMM_CTRL_STYLES | BS_AUTOCHECKBOX;
    immutable UINT WXSTYLE_CHECK_BOX = WS_EX_LTRREADING | WS_EX_LEFT;

    immutable UINT WSTYLE_COMBO_BOX  = COMM_CTRL_STYLES | CBS_DROPDOWN;
    immutable UINT WXSTYLE_COMBO_BOX = WS_EX_CLIENTEDGE;

    immutable UINT WSTYLE_DTP       = 0x52000004;
    immutable UINT WXSTYLE_DTP      = WS_EX_LEFT;

    immutable UINT WSTYLE_GB        = WS_CHILD
                                    | WS_VISIBLE
                                    | BS_GROUPBOX
                                    | BS_NOTIFY
                                    | BS_TOP
                                    | WS_CLIPCHILDREN
                                    | WS_CLIPSIBLINGS;

    immutable UINT WSTYLE_LABEL     = COMM_CTRL_STYLES | SS_NOTIFY;

    immutable UINT WSTYLE_LIST_BOX  = COMM_CTRL_STYLES
                                | LBS_HASSTRINGS
                                | WS_VSCROLL
                                | WS_BORDER
                                | LBS_NOTIFY;

    immutable UINT WSTYLE_LIST_VIEW = COMM_CTRL_STYLES
                                | LVS_REPORT
                                | WS_BORDER
                                | LVS_ALIGNLEFT
                                | LVS_SINGLESEL;

    immutable UINT WSTYLE_NUM_PICK  = COMM_CTRL_STYLES
                                | UDS_ALIGNRIGHT
                                | UDS_ARROWKEYS
                                | UDS_HOTTRACK
                                | WS_CLIPSIBLINGS;

    immutable UINT WSTYLE_PGB       = COMM_CTRL_STYLES | PBS_SMOOTH;
    immutable UINT WXSTYLE_PGB      = WS_EX_STATICEDGE;

    immutable UINT WSTYLE_RADIO     = COMM_CTRL_STYLES | BS_AUTORADIOBUTTON;

    immutable UINT WSTYLE_TB        = COMM_CTRL_STYLES
                                | ES_LEFT
                                | ES_AUTOHSCROLL
                                | WS_OVERLAPPED;

    immutable UINT WXSTYLE_TB       = WS_EX_LEFT
                                | WS_EX_LTRREADING
                                | WS_EX_CLIENTEDGE;

    immutable UINT WSTYLE_TKBAR     = COMM_CTRL_STYLES | TBS_AUTOTICKS;

    immutable UINT WSTYLE_TV        = COMM_CTRL_STYLES
                                | WS_BORDER
                                | TVS_HASLINES
                                | TVS_HASBUTTONS
                                | TVS_LINESATROOT
                                | TVS_DISABLEDRAGDROP;
//============================================================
enum BLK_FGC = true;
enum TXTBLE = true;
enum FNTBLE = true;
enum NO_FGC = false;
enum NO_TXT = false;
enum NO_FNT = false;

struct ControlMetaData 
{
    string prefix;
    ImmutWcharArr className;
    UINT style;
    UINT exStyle;
    BackColorMode bcMode;
    bool isBlackFGC;
    bool isTextable;
    bool hasFont;

}

static immutable ControlMetaDataList = [
    ControlMetaData("Form_", WCNFORM, 0, 0, 
                    BackColorMode.none, NO_FGC, NO_TXT, NO_FNT),

    ControlMetaData("Button_", WCNBUTTON, WSTYLE_BUTTON, 0, 
                    BackColorMode.none, NO_FGC, TXTBLE, FNTBLE),

    ControlMetaData("Calendar_", WCNCALENDAR, WSTYLE_CALENDAR, 0, 
                    BackColorMode.none, NO_FGC, NO_TXT, NO_FNT),

    ControlMetaData("CheckBox_", WCNBUTTON, WSTYLE_CHECK_BOX, WXSTYLE_CHECK_BOX, 
                    BackColorMode.inherit, BLK_FGC, TXTBLE, FNTBLE),

    ControlMetaData("ComboBox_", WCNCOMBO, WSTYLE_COMBO_BOX, WXSTYLE_COMBO_BOX, 
                    BackColorMode.white, BLK_FGC, TXTBLE, FNTBLE),

    ControlMetaData("DateTimePicker_", WCNDTP, WSTYLE_DTP, WXSTYLE_DTP, 
                    BackColorMode.white, BLK_FGC, TXTBLE, FNTBLE),

    ControlMetaData("GroupBox_", WCNBUTTON, WSTYLE_GB, WS_EX_CONTROLPARENT, 
                    BackColorMode.inherit, BLK_FGC, TXTBLE, FNTBLE),

    ControlMetaData("Label_", WCNSTATIC, WSTYLE_LABEL, 0, 
                    BackColorMode.inherit, BLK_FGC, TXTBLE, FNTBLE),

    ControlMetaData("ListBox_", WCNLISTBOX, WSTYLE_LIST_BOX, 0, 
                    BackColorMode.white, BLK_FGC, NO_TXT, FNTBLE),

    ControlMetaData("ListView_", WCNLISTVIEW, WSTYLE_LIST_VIEW, 0, 
                    BackColorMode.white, BLK_FGC, NO_TXT, FNTBLE),

    ControlMetaData("NumberPicker_", WCNNUMPICK, WSTYLE_NUM_PICK, 0, 
                    BackColorMode.white, BLK_FGC, TXTBLE, FNTBLE),

    ControlMetaData("Panel_", WCNBUTTON, WSTYLE_LABEL, WS_EX_CONTROLPARENT, 
                    BackColorMode.inherit, NO_FGC, NO_TXT, NO_FNT),

    ControlMetaData("PictureBox_", WCNPICTUREBOX, WSTYLE_PGB, 0, 
                    BackColorMode.none, NO_FGC, NO_TXT, FNTBLE),

    ControlMetaData("ProgressBar_", WCNPROGRESSBAR, WSTYLE_PGB, WS_EX_STATICEDGE, 
                    BackColorMode.none, BLK_FGC, NO_TXT, FNTBLE),

    ControlMetaData("RadioButton_", WCNBUTTON, WSTYLE_RADIO, 0, 
                    BackColorMode.inherit, BLK_FGC, TXTBLE, FNTBLE),

    ControlMetaData("TextBox_", WCNEDIT,WSTYLE_TB, WXSTYLE_TB, 
                    BackColorMode.white, BLK_FGC, TXTBLE, FNTBLE),

    ControlMetaData("TrackBar_", WCNTRACKBAR, WSTYLE_TKBAR, 0, 
                    BackColorMode.inherit, NO_FGC, NO_TXT, FNTBLE),

    ControlMetaData("TreeView_", WCNTREEVIEW, WSTYLE_TV, 0, 
                    BackColorMode.white, BLK_FGC, TXTBLE, FNTBLE)
];