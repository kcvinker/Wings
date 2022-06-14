module winglib.enums;



/// Describe window positions
enum WindowPos {
    topLeft, topMid, topRight,
    midLeft, center, midRight,
    bottomLeft, bottomMid, bottomRight, manual
}

/// display style
enum WindowStyle {fixedSingle, fixed3D, fixedDialog, normalWin, fixedTool, sizableTool }

/// display state
enum DisplayState { normal, maximized, minimized }

enum WindowBkMode {normal, singleColor, gradient}

enum GradientStyle {topToBottom, leftToRight}

/// Private Enum for Mouse Button state
enum MouseButtons {
    none = 0,
    right = 20_97_152,
    middle = 41_94_304,
    left = 10_48_576,
    xButton1 = 83_88_608,
    xButton2 = 167_77_216
}

enum MouseButtonState {released, pressed }

/// Public enum for describing control types
enum ControlType {
    none = 0,
    button, calendar, checkBox, comboBox, dateTimePicker, groupBox, label, listBox, listView, panel,
    pictureBox, radioButton, textBox, treeView, trackBar, upDown 
}