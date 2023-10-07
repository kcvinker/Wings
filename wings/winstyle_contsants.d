module wings.winstyle_contsants;
private import core.sys.windows.windows;

DWORD fixedSingleExStyle =  WS_EX_LEFT |
                            WS_EX_LTRREADING |
                            WS_EX_RIGHTSCROLLBAR |
                            WS_EX_WINDOWEDGE |
                            WS_EX_CONTROLPARENT |
                            WS_EX_APPWINDOW;

DWORD fixedSingleStyle =    WS_OVERLAPPED |
                            WS_TABSTOP |
                            WS_MAXIMIZEBOX |
                            WS_MINIMIZEBOX |
                            WS_GROUP |
                            WS_SYSMENU |
                            WS_DLGFRAME |
                            WS_BORDER |
                            WS_CAPTION |
                            WS_CLIPCHILDREN |
                            WS_CLIPSIBLINGS;

DWORD fixed3DExStyle =      WS_EX_LEFT |
                            WS_EX_LTRREADING |
                            WS_EX_RIGHTSCROLLBAR |
                            WS_EX_WINDOWEDGE |
                            WS_EX_CLIENTEDGE |
                            WS_EX_CONTROLPARENT |
                            WS_EX_APPWINDOW |
                            WS_EX_OVERLAPPEDWINDOW;

DWORD fixed3DStyle =        WS_OVERLAPPED |
                            WS_TABSTOP |
                            WS_MAXIMIZEBOX |
                            WS_MINIMIZEBOX |
                            WS_GROUP |
                            WS_SYSMENU |
                            WS_DLGFRAME |
                            WS_BORDER |
                            WS_CAPTION |
                            WS_CLIPCHILDREN |
                            WS_CLIPSIBLINGS;

DWORD fixedDialogExStyle =  WS_EX_LEFT |
                            WS_EX_LTRREADING |
                            WS_EX_RIGHTSCROLLBAR |
                            WS_EX_DLGMODALFRAME |
                            WS_EX_WINDOWEDGE |
                            WS_EX_CONTROLPARENT |
                            WS_EX_APPWINDOW;

DWORD fixedDialogStyle =    WS_OVERLAPPED |
                            WS_TABSTOP |
                            WS_MAXIMIZEBOX |
                            WS_MINIMIZEBOX |
                            WS_GROUP |
                            WS_SYSMENU |
                            WS_DLGFRAME |
                            WS_BORDER |
                            WS_CAPTION |
                            WS_CLIPCHILDREN |
                            WS_CLIPSIBLINGS;

DWORD normalWinExStyle =    WS_EX_LEFT |
                            WS_EX_LTRREADING |
                            WS_EX_RIGHTSCROLLBAR |
                            WS_EX_WINDOWEDGE |
                            WS_EX_CONTROLPARENT |
                            WS_EX_APPWINDOW;

DWORD normalWinStyle =      WS_OVERLAPPEDWINDOW |
                            WS_TABSTOP | WS_BORDER |
                            WS_CLIPCHILDREN |
                            WS_CLIPSIBLINGS;

DWORD fixedToolExStyle =    WS_EX_LEFT |
                            WS_EX_LTRREADING |
                            WS_EX_RIGHTSCROLLBAR |
                            WS_EX_TOOLWINDOW |
                            WS_EX_WINDOWEDGE |
                            WS_EX_CONTROLPARENT |
                            WS_EX_APPWINDOW;

DWORD fixedToolStyle =      WS_OVERLAPPED |
                            WS_TABSTOP |
                            WS_MAXIMIZEBOX |
                            WS_MINIMIZEBOX |
                            WS_GROUP |
                            WS_SYSMENU |
                            WS_DLGFRAME |
                            WS_BORDER |
                            WS_CAPTION |
                            WS_CLIPCHILDREN |
                            WS_CLIPSIBLINGS;

DWORD sizableToolExStyle =  WS_EX_LEFT |
                            WS_EX_LTRREADING |
                            WS_EX_RIGHTSCROLLBAR |
                            WS_EX_TOOLWINDOW |
                            WS_EX_WINDOWEDGE |
                            WS_EX_CONTROLPARENT |
                            WS_EX_APPWINDOW;

DWORD sizableToolStyle =    WS_OVERLAPPED |
                            WS_TABSTOP |
                            WS_MAXIMIZEBOX |
                            WS_MINIMIZEBOX |
                            WS_GROUP |
                            WS_THICKFRAME |
                            WS_SYSMENU |
                            WS_DLGFRAME |
                            WS_BORDER |
                            WS_CAPTION |
                            WS_OVERLAPPEDWINDOW |
                            WS_CLIPCHILDREN |
                            WS_CLIPSIBLINGS;

