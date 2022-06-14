// Documentation of Button
// Created on : 26-May-22 04:37:29 PM

class Button : Control 

// Properties
    // Set & Get fore color of Button
    final override void foreColor(uint value) 
    final override uint foreColor()

    // Set & get back color of button
    final override void backColor(uint value)
    final override uint backColor()   

    
// Ctors
    this(Window parent, string txt, int x, int y, int w, int h) 
    this(Window parent)
    this(Window parent, string txt)
    this(Window parent, string txt, int x, int y)
    this(Window parent, int x, int y, int w, int h)
// End of Ctors  

// Functions       
    final void create()    // Create the handle of Button

    /* Set gradient colors for this button
        Parameters 
            1. clr1 - Color one
            2. clr2 - Color two
            3. gStyle - enum {topToBottom, leftToRight}
    */
    final void setGradientColors(uint clr1, uint clr2, GradientStyle gStyle = GradientStyle.topToBottom)




