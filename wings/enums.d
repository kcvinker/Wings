module wings.enums;


enum FontWeight {
    light = 300,
    normal = 400,
    medium = 500,
    semiBold = 600,
    bold = 700,
    extraBold = 800,
    ultraBold = 900
}

/// Describe window positions
enum FormPos {
    topLeft, topMid, topRight,
    midLeft, center, midRight,
    bottomLeft, bottomMid, bottomRight, manual
}

/// display style
enum FormStyle {fixedSingle, fixed3D, fixedDialog, normalWin, fixedTool, sizableTool, hidden }
enum ButtonStyle {normal, flat, gradient} // For Button
package enum BtnDrawMode {normal, textOnly, bkgOnly, textBkg, gradient, gradientText} // For Button
enum ViewMode {month, year, decade, centuary}  // for calander
enum DtpFormat {longDate = 1, shortDate, timeOnly = 4, custom = 8 } // For DateTimePicker

/// display state
enum FormState { normal, maximized, minimized }

enum FormBkMode {normal, singleColor, gradient}

enum GradientStyle {topToBottom, leftToRight} // For window & button

/// Private Enum for Mouse Button state
enum MouseButton {
    none = 0,
    right = 20_97_152,
    middle = 41_94_304,
    left = 10_48_576,
    xButton1 = 83_88_608,
    xButton2 = 167_77_216
}

// Used for Mouse related messages
enum MouseButtonState {released, pressed }

/// Public enum for describing control types
enum ControlType {
    none, window, button, contextMenu, calendar, checkBox, comboBox, dateTimePicker, groupBox,
    label, listBox, listView, numberPicker, panel, pictureBox, progressBar, radioButton, textBox, treeView,
    trackBar, upDown
}

// Used for WM_SIZE and WM_SIZING message handlers
enum SizedPosition {
    LeftEdge = 1,
    RightEdge,
    TopEdge,
    TopLeftCorner,
    TopRightCorner,
    BottomEdge,
    BottomLeftCorner,
    BottomRightCorner
}

enum DropDownStyle {textCombo, labelCombo} // For combo box
enum LabelBorder {noBorder, singleLine, sunkenBorder} // For label
enum TextAlignment {    // For label & ...
    topLeft, topCenter, topRight, midLeft,
    center, midRight, bottomLeft, bottomCenter, bottomRight}

enum Alignment {left, right, center} // For ListView, textbox
enum TextType {normal, numberOnly, passwordChar} // For textbox
enum TextCase {normal, lowerCase, upperCase} // For textbox
enum ListViewStyle {largeIcon, report, smallIcon, list, tile}
enum TicPosition {downSide, upSide, leftSide, rightSide, bothSide} // For trackBar.
enum ChannelStyle {classic, outline} // For Trackbar
enum TrackChange {none, arrowLow, arrowHigh, pageLow, pageHigh, mouseClick, mouseDrag} // For TrackBar
enum NodeOps {addNode, insertNode, addChild, insertChild} // For TreeView




enum ColorOptions { // For ImageList
    defaultColor,
    color4 = 4,
    color8 = 8,
    color16 = 16,
    color24 = 24,
    color32 = 32,
    colorDDB = 0x000000FE
}

enum ImageType {normalImage, smallImage, stateImage} // For ImageList
enum ImageOptions {
    none,
    maskImage = 1,
    mirrorImage = 8192,
    maskMirror = 8193,
    stateImage = 32_768,
    maskState = 32_769,
    mirrorState = 40_960,
    useAll = 40_961
} // For ImageList

enum NumPickOp { none, opAdd, opSub}
enum HeaderColorStatus { bcOnly, fcOnly, bothColors } // for list view header color drawing
enum HotKeyId { hotSnapWindow = -2, hotSnapDeskTop = -1} // For using in wm_hotkey message handler
enum ModifierKeys { altKey = 1, ctrlKey = 2, shiftKey = 4, winKey = 8 } // ,,

enum MenuType { baseMenu, normalMenu, popumMenu, separator }

enum TrayMenuTrigger : ubyte {none, leftClick, leftDoubleClick, rightClick = 4, anyClick = 7}
enum BalloonIcon {none, info, warning, error, custom}


enum Key {
    modifier = -65_536,
    none = 0,
    lButton, rButton, cancel, mButton, xButtonOne, xButtonTwo,
    backSpace = 8,
    tab, lineFeed,
    clear = 12,
    enter,
    shift = 16,
    ctrl, alt, pause, capsLock,
    escape = 27,
    space = 32,
    pageUp, pageDown, end, home, leftArrow, upArrow, rightArrow, downArrow,
    select, print, execute, printScreen, insert, del, help,
    d0, d1, d2, d3, d4, d5, d6, d7, d8, d9,
    a = 65,
    b, c, d, e, f, g, h, i, j, k, l, m, n,
    o, p, q, r, s, t, u, v, w, x, y, z,
    leftWin, rightWin, apps,
    sleep = 95,
    numPad0, numPad1, numPad2, numPad3, numPad4, numPad5, numPad6, numPad7, numPad8, numPad9,
    multiply, add, seperator, subtract, decimal, divide,
    f1, f2, f3, f4, f5, f6, f7, f8, f9, f10,
    f11, f12, f13, f14, f15, f16, f17, f18, f19, f20,
    f21, f22, f23, f24,
    numLock = 144,
    scroll,
    leftShift = 160,
    rightShift, leftCtrl, rightCtrl, leftMenu, rightmenu,
    browserBack, browserForward, browerRefresh, browserStop, browserSearch, browserFavorites, browserHome,
    volumeMute, volumeDown, volumeUp,
    mediaNextTrack, mediaPrevTrack, mediaStop, mediaPlayPause, launchMail, selectMedia,
    launchApp1, launchApp2,
    oem1 = 186,
    oemPlus, oemComma, oemMinus, oemPeriod, oemQuestion, oemTilde,
    oemOpenBracket = 219,
    oemPipe, oemCloseBracket, oemQuotes, oem8,
    oemBackSlash = 226,
    process = 229,
    packet = 231,
    attn = 246,
    crSel, exSel, eraseEof, play, zoom, noName, pa1, oemClear,  // start from 400
    keyCode = 65_535,
    shiftModifier = 65_536,
    ctrlModifier = 131_072,
    altModifier = 262_144
}




