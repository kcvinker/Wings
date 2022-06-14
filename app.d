import std.stdio;
import winglib ;
//import core.sys.windows.windows;
import std.stdio : log = writeln;
import std.format ;
import std.conv ;

//dmd -i -run app.d

Window frm ;
Button btn ;



void main() { 	 

	frm = new Window() ;	 
	frm.text = "Learning D by writting D";
	frm.onClosed = (s, e) => log("Window is going to close"); 
	frm.onMouseLeave = (s, e) => log("Mouse leaved okl") ;
	frm.onLoad = &frmLoad ;
	//frm.onKeyDown =  (s, e) => log("Success "); 
	frm.onMouseDown = (s, e) => log("event ococcurred");
	frm.create() ;

	btn = new Button(frm) ;
	btn.font.name = "Manjari" ;
	btn.text = "bull" ;
	btn.font.size = 14 ;
	btn.onClick = (s, e) => log("Vinod, you came back coding in D !!") ;
	btn.create() ; 							

	frm.show() ;
		
}



void onClick(Control s, EventArgs e) 	 // @suppress(dscanner.style.undocumented_declaration)
{ 
	//frm.setGradientBackColor( 0x551ccb, 0xffDD60) ;	 
	//frm.backColor = 0xff0000 ;
	import std.digest: toHexString;
	RgbColor rr = RgbColor(0xff0000) ;
	// rr.printRgb() ;
	rr.lighter(0.65) ;
	rr.printRgb() ;
	frm.backColor = rr.getUint ;

}

void frmLoad(Control s, EventArgs e) 	 // @suppress(dscanner.style.undocumented_declaration)
{ 
	  
	log("form loaded") ;
}

void frmKeyDown(Control s, KeyEventArgs e) {
	log("Success with - ", e.keyCode);
}

