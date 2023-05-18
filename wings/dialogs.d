// dialogs module - Created on 18-May-2023 23:22
module wings.dialogs;

import core.sys.windows.windows;
import core.sys.windows.shlobj;

import std.stdio;
import std.utf;
import std.conv;
import std.string;
import wings.controls: finalProperty;

pragma(lib, "Comdlg32.lib");
pragma(lib, "Shell32.lib");
pragma(lib, "Ole32.lib");

enum OFN_FORCESHOWHIDDEN = 0x10000000;
enum BIF_NONEWFOLDERBUTTON = 0x00000200;
enum defFilter = "All Files" ~ '\0' ~ "*.*" ~ '\0';


class DialogBase {

    this(string title, string initDir, string filter = null) {
        this.mTitle = title;
        this.mInitDir = initDir;
        this.mFilter = filter;
    }

    mixin finalProperty!("title", this.mTitle);
    mixin finalProperty!("initialFolder", this.mInitDir);
    mixin finalProperty!("filter", this.mFilter);
    mixin finalProperty!("selectedPath", this.mSelPath);
    mixin finalProperty!("fileNameStartPos", this.mNameStart);
    mixin finalProperty!("extensionStartPos", this.mExtStart);

    private:
    string mTitle;
    string mInitDir;
    string mFilter;
    string mSelPath;
    int mNameStart;
    int mExtStart;
}

class FileOpenDialog : DialogBase {
    this(string title = "Open File", string initDir = "", string filter = "All files\0*.*\0") {
        super(title, initDir, filter);
    }

    mixin finalProperty!("multiSelection", this.mMultiSel);
    mixin finalProperty!("showHiddenFiles", this.mShowHidden);

    final bool showDialog(HWND hwnd = null) {
        writeln("in dialog ");
        this.mInitDir = "C:\\Users\\kcvin\\OneDrive\\Programming\\C3\\CForms\\cforms";
        return showDialogHelper(this, true, hwnd);
    }

    private:
    bool mMultiSel;
    bool mShowHidden;
}

class FileSaveDialog : DialogBase {
    this(string title = "Save File", string initDir = "", string filter = "All files\0*.*\0") {
        super(title, initDir, filter);
    }

    mixin finalProperty!("defaultExtension", this.mDefExt);

    final bool showDialog(HWND hwnd = null) {
        this.mInitDir = "C:\\Users\\kcvin\\OneDrive\\Programming\\C3\\CForms\\cforms";
        return showDialogHelper(this, false, hwnd);
    }

    private:
    string mDefExt;
}

class FolderBrowserDialog : DialogBase {
    this(string title = "Select folder", string initialFolder = "") {
        super(title, initialFolder);
    }

    mixin finalProperty!("newFolderButton", this.mNewFolBtn);
    mixin finalProperty!("showFiles", this.mShowFiles);

    final bool showDialog(HWND hwnd = null) {
        wchar[] buffer = new wchar[](MAX_PATH);
        BROWSEINFOW bi;
        bi.hwndOwner = hwnd;
        bi.lpszTitle = this.mTitle.toUTF16z;
        bi.ulFlags = BIF_RETURNONLYFSDIRS | BIF_NEWDIALOGSTYLE;
        if (this.mNewFolBtn) bi.ulFlags |= BIF_NONEWFOLDERBUTTON;
        if (this.mShowFiles) bi.ulFlags |= BIF_BROWSEINCLUDEFILES;
        ITEMIDLIST* pidl = SHBrowseForFolderW(&bi);
        if (pidl) {
            if (SHGetPathFromIDListW(pidl, buffer.ptr)) {
                CoTaskMemFree(pidl);
                this.selectedPath = fromStringz(buffer.ptr).to!string;
                return true;
            }
            CoTaskMemFree(pidl);
        }
        return false;
    }

    private:
    bool mNewFolBtn;
    bool mShowFiles;

}

bool showDialogHelper(T)(T obj, bool isOpen, HWND hwnd) {
    wchar[] buffer = new wchar[](MAX_PATH);
    wchar[] ttlBuff = new wchar[](MAX_PATH);
    ttlBuff[0] = '\u0000';
    buffer[0] = '\u0000';
    OPENFILENAMEW ofn;
    ofn.hwndOwner = hwnd;
    ofn.lpstrFile = cast(wchar*) buffer.ptr;
    ofn.lpstrInitialDir = obj.mInitDir != "" ? obj.mInitDir.toUTF16z : null;
    ofn.lpstrTitle = obj.mTitle.toUTF16z;
    ofn.lpstrFilter =  obj.mFilter.toUTF16z;
    ofn.lpstrFileTitle = cast(wchar*) ttlBuff;
    ofn.nMaxFile = MAX_PATH;
    ofn.nMaxFileTitle = MAX_PATH;
    ofn.lpstrDefExt = toUTF16z("\0"); // Without this, we won't get any extension.
    BOOL ret = -1;
    if (isOpen) {
        ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;
        auto me = cast(FileOpenDialog) obj;
        if (me.multiSelection) ofn.Flags |= OFN_ALLOWMULTISELECT;
        if (me.showHiddenFiles) ofn.Flags |= OFN_FORCESHOWHIDDEN;
        ret = GetOpenFileNameW(&ofn);
    } else {
        ofn.Flags = OFN_PATHMUSTEXIST | OFN_OVERWRITEPROMPT;
        ret = GetSaveFileNameW(&ofn);
    }
    if (ret) {
        obj.mNameStart = ofn.nFileOffset;
        obj.mExtStart = ofn.nFileExtension;
        obj.mSelPath = fromStringz(buffer.ptr).to!string;
        return true;
    }
    return false;
}



