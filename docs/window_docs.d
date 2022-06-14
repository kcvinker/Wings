//Documentation - Window class - Created on : 24-May-22 11:28:02 PM

class Window : Control {    
    //Control[] controls; // A list to hold all childs.


    // properties
        final WindowPos startPos() {return this.mStartPos;}             
        final void startPos(WindowPos value ) {this.mStartPos = value;}
            /* Get and set the window position.
                WindowPos - enum {topLeft, topMid, topRight, midLeft, center, midRight, bottomLeft, bottomMid, bottomRight, manual}
            */

        final WindowStyle style() {return this.mWinStyle;}
        final void style(WindowStyle value ) {this.mWinStyle = value;}
            /* Get and set the window style
                WindowStyle - enum {fixedSingle, fixed3D, fixedDialog, normalWin, fixedTool, sizableTool}
            */

        final bool topMost() {return this.mTopMost;}
        final void topMost(bool value ) {this.mTopMost = value;}
            // Get and set the topmost state of window.

        final DisplayState windowState() {return this.mWinState;}
        final void windowState(DisplayState value ) {this.mWinState = value;}
            /* Get and set the window state of window
                DisplayState - enum {normal, maximized, minimized}
            */
       
        final override uint backColor() const {return this.mBackColor ;}
        final override void backColor(uint clr) {propBackColorSetter(clr) ;}
            /* Get and set the back color of window.
                Example - win.backColor = 0xF5F5F5
            */
              

    bool maximizeBox ;
    bool minimizeBox ;

    /* Events. (Since Window is inheriting from Control, it has some extra events provided by Control.)
         EventHandler type - signature [alias EventHandler = void function(Control sender, EventArgs e)]
            onMinimized - occurs when window is minimized
            onMaximized - occurs when window is maximized
            onRestored - occurs when window is restored
            onClosing - occurs when window is about to closing
            onClosed - occurs when window is closed
            onLoad - occurs when window is loading 
            onActivate - occurs when window is activated
            onDeActivate - occurs when window is de activated
            onMoving - occurs when window is moving
            onMoved - occurs when window is moved
        
        SizeEventHandler type - signature [alias SizeEventHandler = void function(Control sender, SizeEventArgs e) ;]
            onSized - occurs when window is about to change the size
            onSizing - occurs when window is canged the size 
        */

   
    //constructor of Window class    
    this () 
    this(string title) 
    this(string title, int w, int h) 
    this(string txt, int x, int y, int w, int h)

    // Functions
    final void create() // Create the window handle     
    final void show() // Show the window

    // set the gradient background color for window.
    final void setGradientColors(   uint c1, 
                                    uint c2, 
                                    GradientStyle gStyle = GradientStyle.topToBottom)     
    final void close() //  closes the window 
    
    //print the mouse points. Helper function to find the coordinates
    final void printPoint(MouseEventArgs e) 

    