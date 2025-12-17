// dialogs module - Created on 18-May-2023 23:22
/*==============================================Common Dialogs Docs=====================================
    (1) DialogBase
            Abstract base class. 
            Properties:
                title               : string
                initialFolder       : string
                selectedPath        : string
                allowAllFiles       : bool
            Funcctions:
                setFilter
                setFilters

    (2) FileOpenDialog : DialogBase
            Constructor:
                this(string title = "Open File", string initDir = "", 
                     string typeFilter = "All files|*.*")
            Properties:
                multiSelection      : bool   
                showHiddenFiles     : bool
                fileNames           : string[], in case of multiSelection == true
            Functions:
                bool showDialog(HWND hwnd = null)
    
    (3) FileSaveDialog : DialogBase
            Constructor:
                this(string title = "Save File", string initDir = "", 
                     string typeFilter = "All files|*.*") 
            Properties:
                NA
            Functions:
                bool showDialog(HWND hwnd = null)

    (4) FolderBrowserDialog : DialogBase
            Constructor:
                this(string title = "Select folder", string initialFolder = "") 
            Properties:
                newFolderButton     : bool
                showFiles           : bool
            Functions:
                bool showDialog(HWND hwnd = null)     
=============================================================================================*/
module wings.dialogs;

import core.sys.windows.windows;
import core.sys.windows.shlobj;

import std.stdio;
import std.utf;
import std.conv;
import std.string;
import std.array;
import wings.controls: finalProperty;

pragma(lib, "Comdlg32.lib");
pragma(lib, "Shell32.lib");
pragma(lib, "Ole32.lib");

enum OFN_FORCESHOWHIDDEN = 0x10000000;
enum BIF_NONEWFOLDERBUTTON = 0x00000200;
enum MAX_PATH_NEW = 65_535;


class DialogBase {

    this(string title, string initDir, string typeFilter)
    {
        this.mTitle = title;
        this.mInitDir = initDir;
        if (typeFilter.length > 0) {
            this.mFilter = typeFilter.replace("|", "\0") ~ "\0\0";
        }         
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

    void setFilters(string typeFilter)
    {
        this.mFilter = typeFilter.replace("|", "\0") ~ "\0\0";        
    }

    // void allowAllFiles(bool value) {this.mAllowAllFiles = value;}

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

// Open File Dialog.
// NOTE: When using typeFilter, use pipe character('|')...
// ...to separate filter name and extension.
// You can use two types of typeFilter string:
// 1. Multiple descriptions and multiple extensions.
//      Like, "PDF files|*.pdf|Text Files|*.txt"
// 2. Single description and multiple extensions.
//      Like, "Document files|*.doc;*.docx"
class FileOpenDialog : DialogBase {
    this(string title = "Open File", string initDir = "", 
                    string typeFilter = "All files|*.*")
    {
        super(title, initDir, typeFilter);
    }

    mixin finalProperty!("multiSelection", this.mMultiSel);
    mixin finalProperty!("showHiddenFiles", this.mShowHidden);
    final string[] fileNames() {return this.mSelFiles;}

    /// Show the File Open Dialog. Use hwnd to make it modal to a window.
    final bool showDialog(HWND hwnd = null)
    {
        return showCommonDialog(this, hwnd);        
    }

    private:
    bool mMultiSel;
    bool mShowHidden;
    string[] mSelFiles;

    // If user selects multi selection property, we will get all the
    // selected files in buffer with null character separated.
    // We need to loop throughi it and extract the file names.
    void extractFileNames(wchar[] buff, int startPos) 
    {
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

// Save File Dialog. 
// For more info on typeFilter, see FileOpenDialog.
class FileSaveDialog : DialogBase 
{
    this(string title = "Save File", 
         string initDir = "",
         string typeFilter = "All files|*.*") 
    {
        super(title, initDir, typeFilter);
    }

    // mixin finalProperty!("defaultExtension", this.mDefExt);

    /// Show the File Save Dialog. Use hwnd to make it modal to a window.
    final bool showDialog(HWND hwnd = null) 
    {
        return showCommonDialog(this, hwnd);        
    }

    private:
    string mDefExt;
}

class FolderBrowserDialog : DialogBase {
    this(string title = "Select folder", string initialFolder = "") 
    {
        super(title, initialFolder, "");
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
                this.selectedPath = fromStringz(buffer.ptr).toUTF8;
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

// Common function to show Open/Save file dialog
private bool showCommonDialog(T)(T dialog, HWND hwnd)
{
    OPENFILENAMEW ofn;
    wchar[] buffer;
    wchar[] ttlBuff = new wchar[](MAX_PATH);

    ttlBuff[0] = '\0';

    // Decide buffer size
    static if (is(T == FileOpenDialog)) {
        if (dialog.multiSelection)
            buffer = new wchar[](MAX_PATH_NEW);
        else
            buffer = new wchar[](MAX_PATH);
    } else {
        buffer = new wchar[](MAX_PATH);
    }

    buffer[0] = '\0';

    // Common fields
    ofn.hwndOwner = hwnd;
    ofn.lpstrFile = buffer.ptr;
    ofn.lpstrInitialDir = dialog.mInitDir != "" ? dialog.mInitDir.toUTF16z : null;
    ofn.lpstrTitle = dialog.mTitle.toUTF16z;
    ofn.lpstrFilter = dialog.mFilter.toUTF16z;
    ofn.lpstrFileTitle = ttlBuff.ptr;
    ofn.nMaxFile = cast(uint)buffer.length;
    ofn.nMaxFileTitle = MAX_PATH;
    ofn.lpstrDefExt = toUTF16z("\0");

    // Flags
    static if (is(T == FileOpenDialog)) {
        ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;

        if (dialog.multiSelection)
            ofn.Flags |= OFN_ALLOWMULTISELECT | OFN_EXPLORER;

        if (dialog.showHiddenFiles)
            ofn.Flags |= OFN_FORCESHOWHIDDEN;
    } else {
        ofn.Flags = OFN_PATHMUSTEXIST | OFN_OVERWRITEPROMPT;
    }

    // Call correct WinAPI
    bool ret;
    static if (is(T == FileOpenDialog))
        ret = cast(bool)GetOpenFileNameW(&ofn);
    else
        ret = cast(bool)GetSaveFileNameW(&ofn);

    if (!ret) return false;

    // Results
    dialog.mNameStart = ofn.nFileOffset;
    dialog.mExtStart  = ofn.nFileExtension;

    static if (is(T == FileOpenDialog)) {
        if (dialog.mMultiSel) {
            dialog.extractFileNames(buffer, ofn.nFileOffset);
        } else {
            dialog.mSelPath = buffer.ptr.fromStringz.toUTF8;
        }
    } else {
        dialog.mSelPath = buffer.ptr.fromStringz.toUTF8;
    }

    return true;
}


