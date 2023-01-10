import std.stdio;
import wings ;
//import core.sys.windows.windows;
import std.stdio : log = writeln;
import std.format ;
import std.conv ;
import std.string ;
import wings.imagelist;
import std.datetime.stopwatch;

//dmd -i -run app.d

Window frm ;
Button btn, btnor ;
CheckBox cb ;
ComboBox cmb ;
DateTimePicker dtp;
Calendar cal;
Label lbl;
//ListBox lbx;
ListView lv ;
NumberPicker np;
RadioButton rb, rb2;
TextBox tb;
TrackBar tk;



void main() {
	auto sw = StopWatch(AutoStart.no);
    sw.start();
	frm = new Window("Wing window in D Lang", 750, 400) ;
	frm.onMouseDown = (s, e) => frm.printPoint(e) ;
	frm.create() ;

	 cmb = new ComboBox(frm, 20, 100, 150, 30);
	 cmb.addRange("Window", "Button", "Calendar", "CheckBox", "DateTimePicker", "GroupBox");
	 //cmb.dropDownStyle = DropDownStyle.;
	 cmb.backColor = 0xff80bf;
	 //cmb.onMouseMove = (c, e) => print("mouse moved");
     cmb.create;

	lv = new ListView(frm, 297, 39, 360, 300);
	//lv.addColumn(new ListViewColumn("Check", 50));
	lv.addColumn(new ListViewColumn("No.", 50));
	lv.addColumn(new ListViewColumn("Work Name", 200));
	lv.addColumn(new ListViewColumn("Part No.", 100));
	//lv.hasCheckBox = true;
	lv.onItemClicked = (c, e) => log("item clicked");
	lv.onSelectionChanged = (c, e) => log("Selection changed");

	//lv.checkBoxColumnLast();
	lv.create;
	lv.addItems("1", "Translator", "200");
	lv.addItems("2", "Dtp Operator", "400");
	lv.addItems("3", "Cashier", "50");

	//lv.addItems( "", "1", "Discovery", "5");
	//lv.addItems( "", "2", "DTP Work", "3");
	tb = new TextBox(frm, 34, 245);
	tb.foreColor = 0xff0000;
	tb.create();

	btn = new Button(frm );
	btn.width = 120;
	btn.setGradientColors(0xace600, 0xcccc00);
	//btn.onMouseLeave = (c,e) => log(cal.value);

	btn.create();

	lbl = new Label(frm, "My Label", 212, 91);
	//lbl.backColor = 0xccff66;
	lbl.foreColor = 0xff0000;
	//lbl.autoSize = false;
	//lbl.text = "next text";
	lbl.create;

	//cal = new Calendar(frm, 20, 140);
	//cal.create;
	btn.onMouseDown = &btnClick;
	sw.stop();
    print("full create speed in milli secs ", sw.peek.total!"msecs");
    print("mouse over flag ", 0b1000000);

    //cal.printNotifs();

    np = new NumberPicker(frm, 25, 315); // 81
    //np.onMouseLeave = (c,e) => np.log("mouse leave");
    //np.onMouseEnter = (c,e) => np.log("mouse enter");
    //np.buttonOnLeft = true;
    np.backColor = 0xccff66;
    np.create;

    tk = new TrackBar(frm, 20, 170, 150, 40);
    //tk.vertical = true;
	// tk.backColor = 0xff80bf;
	tk.customDraw = true;
    tk.create();

    //auto tk1 = new TrackBar(frm, 410, 81, 150, 40 );
    //tk1.customDraw = true;
	//// tk1.channelStyle = ChannelStyle.outline;
	//tk1.showSelection = true;
	//// tk1.reverse = true;
	//tk1.toolTip = true;

    //tk1.create();

    //lv = new ListView(frm, 297, 39);
    //lv.create();



	frm.show();

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

void frmLoad(Control s, EventArgs e) 	{ // @suppress(dscanner.style.undocumented_declaration)
	log("form loaded") ;
}

void frmKeyDown(Control s, KeyEventArgs e) {
	log("Success with - ", e.keyCode);
}

void frmSize(Control c, SizeEventArgs e) {
	log("sized on - ", e.sizedOn);
	writeln("window rect - ", e.windowRect);
}

void btnClick(Control c, MouseEventArgs e) {	//Gradient btn
	log(cal.value);
}
