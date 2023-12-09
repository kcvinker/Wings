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
enum MAX_PATH_NEW = 32768 + 256 * 100 + 1;
enum defFilter = "All Files" ~ '\0' ~ "*.*" ~ '\0';


class DialogBase {

    this(string title, string initDir)
    {
        this.mTitle = title;
        this.mInitDir = initDir;
    }

    mixin finalProperty!("title", this.mTitle);
    mixin finalProperty!("initialFolder", this.mInitDir);
    // mixin finalProperty!("filter", this.mFilter); // Give a string like this - "All files\0*.*\0" or "Text Files\0*.txt\0"
    mixin finalProperty!("selectedPath", this.mSelPath);
    mixin finalProperty!("fileNameStartPos", this.mNameStart);
    mixin finalProperty!("extensionStartPos", this.mExtStart);

    void setFilter(string filterName, string ext)
    {
        if (this.mFilter.length > 0) {
            this.mFilter = format("%s%s\0*%s\0", this.mFilter, filterName, ext);
        } else {
            this.mFilter = format("%s\0*%s\0", filterName, ext);
        }
    }

    void setFilters(string description, string[] filterList)
    {
        this.mFilter = description ~ "\0";
        auto filCount = filterList.length - 1;
        foreach(i, filter; filterList) {
            this.mFilter ~= "*" ~ filter;
            if (i < filCount) this.mFilter ~= ";";
        }
        this.mFilter ~= "\0\0";
    }

    void allowAllFiles(bool value) {this.mAllowAllFiles = value;}

    // void setFilter(string filterName, string[] ext) {
    //     if (this.mFilter.length > 0) {
    //         this.mFilter = format("%s\0%s\0*%s\0", this.mFilter, filterName, ext);
    //     } else {
    //         this.mFilter = format("%s\0%s\0", filterName, ext);
    //     }
    // }

    private:
    string mTitle;
    string mInitDir;
    string mFilter;
    string mSelPath;
    int mNameStart;
    int mExtStart;
    bool mAllowAllFiles;
}

class FileOpenDialog : DialogBase {
    this(string title = "Open File", string initDir = "")
    {
        super(title, initDir);
    }

    mixin finalProperty!("multiSelection", this.mMultiSel);
    mixin finalProperty!("showHiddenFiles", this.mShowHidden);
    final string[] fileNames() {return this.mSelFiles;}

    final bool showDialog(HWND hwnd = null)
    {
        if (this.mFilter.length == 0) {
            this.mFilter = "All files\0*.*\0";
        } else {
            if (this.mAllowAllFiles) this.mFilter = "All files\0*.*\0\0";
        }
        wchar[] buffer = new wchar[](MAX_PATH_NEW);
        wchar[] ttlBuff = new wchar[](MAX_PATH);
        ttlBuff[0] = '\u0000';
        buffer[0] = '\u0000';
        OPENFILENAMEW ofn;
        ofn.hwndOwner = hwnd;
        ofn.lpstrFile = cast(wchar*) buffer.ptr;
        ofn.lpstrInitialDir = this.mInitDir != "" ? this.mInitDir.toUTF16z : null;
        ofn.lpstrTitle = this.mTitle.toUTF16z;
        ofn.lpstrFilter =  this.mFilter.toUTF16z;
        ofn.lpstrFileTitle = cast(wchar*) ttlBuff;
        ofn.nMaxFile = MAX_PATH_NEW;
        ofn.nMaxFileTitle = MAX_PATH;
        ofn.lpstrDefExt = toUTF16z("\0"); // Without this, we won't get any extension.

        ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;
        if (this.multiSelection) ofn.Flags |= OFN_ALLOWMULTISELECT | OFN_EXPLORER;
        if (this.showHiddenFiles) ofn.Flags |= OFN_FORCESHOWHIDDEN;
        auto ret = GetOpenFileNameW(&ofn);
        if (ret) {
            if (this.mMultiSel) {
                this.extractFileNames(buffer, ofn.nFileOffset);
                return true;
            } else {
                this.mSelPath = to!string(buffer[0..$ - 1]);
                this.mNameStart = ofn.nFileOffset;
                this.mExtStart = ofn.nFileExtension;
                return true;
            }
        }
        // if (ret) {
        //     obj.mNameStart = ofn.nFileOffset;
        //     obj.mExtStart = ofn.nFileExtension;
        //     obj.mSelPath = fromStringz(buffer.ptr).to!string;
        //     return true;
        // }
        return false;

    }

    private:
    bool mMultiSel;
    bool mShowHidden;
    string[] mSelFiles;

    // If user selects multi selection property, we will get all the
    // selected files in buffer with null character separated.
    // We need to loop throughi it and extract the file names.
    void extractFileNames(wchar[] buff, int startPos) {
        int offset = startPos;
        string dirPath = buff[0..startPos - 1].to!string;
        for (int i = startPos; i < MAX_PATH; i++) {
            wchar wc = buff[i];
            if (wc == '\u0000') {
                wchar[] slice = buff[offset..i];
                offset = i + 1;
                this.mSelFiles ~= format("%s\\%s", dirPath, slice.to!string);
                if (buff[offset] == '\u0000') break;
            }
        }
    }
}

class FileSaveDialog : DialogBase {
    this(string title = "Save File", string initDir = "") {
        super(title, initDir);
    }

    mixin finalProperty!("defaultExtension", this.mDefExt);

    final bool showDialog(HWND hwnd = null) {
        if (this.mFilter.length == 0) {
            this.mFilter = "All files\0*.*\0";
        } else {
            if (this.mAllowAllFiles) this.mFilter = format("%sAll files\0*.*\0", this.mFilter);
        }
        wchar[] buffer = new wchar[](MAX_PATH);
        wchar[] ttlBuff = new wchar[](MAX_PATH);
        ttlBuff[0] = '\u0000';
        buffer[0] = '\u0000';
        OPENFILENAMEW ofn;
        ofn.hwndOwner = hwnd;
        ofn.lpstrFile = cast(wchar*) buffer.ptr;
        ofn.lpstrInitialDir = this.mInitDir != "" ? this.mInitDir.toUTF16z : null;
        ofn.lpstrTitle = this.mTitle.toUTF16z;
        ofn.lpstrFilter =  this.mFilter.toUTF16z;
        ofn.lpstrFileTitle = cast(wchar*) ttlBuff;
        ofn.nMaxFile = MAX_PATH;
        ofn.nMaxFileTitle = MAX_PATH;
        ofn.lpstrDefExt = toUTF16z("\0"); // Without this, we won't get any extension.
        ofn.Flags = OFN_PATHMUSTEXIST | OFN_OVERWRITEPROMPT;
        auto ret = GetSaveFileNameW(&ofn);
        if (ret) {
            this.mNameStart = ofn.nFileOffset;
            this.mExtStart = ofn.nFileExtension;
            this.mSelPath = fromStringz(buffer.ptr).to!string;
            return true;
        }
        return false;
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




