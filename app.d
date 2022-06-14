import std.stdio;
import wings ;
//import core.sys.windows.windows;
import std.stdio : log = writeln;
import std.format ;
import std.conv ;
import std.string ;
import wings.imagelist;


//dmd -i -run app.d

Window frm ;
Button btn, btnor ;
CheckBox cb ;
ComboBox cmb ;
DateTimePicker dtp;
Label lbl;
//ListBox lbx;
ListView lv ;
NumberPicker np;



void main() { 	 

	frm = new Window("Wing Gui Library D Lang") ;	 
	//frm.text = "Learning D by writting D";
	//frm.onClosed = (s, e) => log("Window is going to close"); 
	 
	frm.onMouseDown = (s, e) => frm.printPoint(e) ;
	//frm.setGradientColors(0x009245, 0xFCEE21) ;
	
	frm.create() ;

	btn = new Button(frm) ;
	btn.font = new Font("Calibri", 14) ;	
	btn.text = "Gradient" ;
	//btn.foreColor = 0x008000 ;
	//btn.backColor = 0xFF8000 ;	 
	
	btn.setGradientColors(0x009245, 0xFCEE21) ;
	//btn.onClick = (s, e) => msgBox(to!string(frm.backColor));
	btn.onMouseClick = &btnClick;
	btn.create() ; 

	auto b2 = new Button(frm, "Flat", btn.xPos, btn.yPos + 50 ) ;
	b2.backColor = 	Colors.icterine ; // change feature - when adjusting btn bgc, make dark or light.
	b2.create ;	

	btnor = new Button(frm, "Normal", btn.xPos, 130) ; 
	btnor.create;

	cb = new CheckBox(frm, "Check Me", 150, 20) ;
	//cb.backColor = 0x85C2C2 ;
	cb.foreColor = Colors.cadmiumGreen ;

	//log("clr ref in app - ", cb.cref(frm.backColor)) ;
	
	cb.create ;

	cmb = new ComboBox(frm, cb.xPos, cb.yPos + 40) ;
	cmb.addRange(["Edwidge Danticat", "Herodotus", "Franz Kafka", "Fannie Flagg"]);
	cmb.addItem(1982) ;
	cmb.selectedIndex = 1 ;
	//cmb.onKeyDown = (s, e) => log(e.keyCode) ;
	cmb.dropDownStyle = DropDownStyle.labelCombo;
	cmb.foreColor = 0x0000FFu ;
	cmb.backColor = 0xFFA54Au ;
	cmb.create ;
	//print("combo hwnd", cmb.handle);

	dtp = new DateTimePicker(frm, 317, 62);
	//dtp.formatString = "MM'-'dddd'-'YY";
	//dtp.format = DTPFormat.shortDate;
	//dtp.format = DtpFormat.timeOnly;
	dtp.onTextChanged = (s, e) => log("Hi vinod") ;	
	dtp.create ;

	lbl = new Label(frm, "My Label", 365, 17);
	lbl.text = "Learning D";
	lbl.font = new Font("Calibri", 17);
	lbl.foreColor = Colors.mahogany;

	lbl.create();

	//lbx = new ListBox(frm, 160, 106);
	
	lv = new ListView(frm, 160, 106, 320, 150);	
	lv.font = new Font("Inconsolata Medium", 16);
	lv.create;
	
	auto imL = new ImageList(12, 12);
	//imL.experiment(r"C:\Users\AcerLap\Pictures\Saved Pictures" ); //"C:\Users\AcerLap\Pictures\Saved Pictures");
	// imL.addSolidColorImage(lv.handle, Colors.kenyanCopper, 16, 16);
	// imL.addSolidColorImage(lv.handle, Colors.kuCrimson, 16, 16);
	// imL.addSolidColorImage(lv.handle, Colors.maize, 16, 16);	
	imL.addIcons(r"C:\Users\AcerLap\Pictures\Icons");
	lv.setImageList(imL);

	lv.addColumn("Names", 100) ;
	lv.addColumn("Job", 100) ;
	lv.addColumn("Salary", 100) ;

	lv.addItem("Vinod", 1);
	lv.addItem("Vinayak", 2);

	lv.addSubItems(0, "Translator", 40_000);
	lv.addSubItems(1, "DTP op", 20_000);


	np = new NumberPicker(frm, 23, 181);
	np.font = new Font("Inconsolata Black", 20);
	np.step = 0.5;
	np.textPosition = TextPosition.center;
	np.hideSelection = true;
	np.onMouseEnter = (s, e) => print("Mouse entered");
	np.create;



	
	

	
	
	
	
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

void frmSize(Control c, SizeEventArgs e) {
	log("sized on - ", e.sizedOn);
	writeln("window rect - ", e.windowRect);
}

void btnClick(Control c, EventArgs e) {	//Gradient btn
	//lbx.addRange("Vinod Chandran", "Vinayak");
}
