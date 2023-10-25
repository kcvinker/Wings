#!rdmd
import std.stdio;
import wings;
//import core.sys.windows.windows;
import std.stdio : log = writeln;
import std.format;
import std.conv;
import std.string;
import wings.imagelist;

//dmd -i -run app.d

Window frm;
Button btn, btnor, b3;
CheckBox cb;
ComboBox cmb;
DateTimePicker dtp;
Calendar cal;
Label lbl;
//ListBox lbx;
ListView lv;
NumberPicker np;
RadioButton rb, rb2;
TextBox tb;
TrackBar tk;
TreeView tv;
GroupBox gb;
ProgressBar pb;
MenuBar mb;


void main() {
	// auto sw = StopWatch(AutoStart.no);
    // sw.start();
	frm = new Window("Wing window in D Lang", 850, 400);
	frm.enablePrintPoint;
	// frm.onMouseClick = (c,e) => pb.stopMarquee();
	// frm.backColor = 0xAABBCC;
	//frm.style = WindowStyle.sizable;
	frm.createHandle();

	mb = new MenuBar(frm);
	mb.addMenus("File", "Edit", "Format");
	mb.menus["File"].addMenus("New Work", "Exit");
	auto mnuEdit = mb.menus["Edit"];
	mnuEdit.addMenu("Copy");
	mnuEdit.addSeperator();
	mnuEdit.addMenu("Paste");
	auto mnuExit = mb.menus["File"].menus["Exit"];
	mnuExit.onClick = (c, e) => print(c.text);
	mb.create();

	cmb = new ComboBox(frm, 20, 65, 150, 30);
	cmb.addRange("Window", "Button", "Calendar", "CheckBox", "DateTimePicker", "GroupBox", 4500);

	//cmb.dropDownStyle = DropDownStyle.;
	cmb.backColor = 0xff80bf;
	// cmb.onMouseMove = (c, e) => print("mouse moved");
//  cmb.create;


	tb = new TextBox(frm, 20, 195);
	tb.foreColor = 0xff0000;
	// tb.createHandle();

	btn = new Button(frm, "Gradient" );
	btn.width = 120;
	btn.setGradientColors(0xeeef20, 0x70e000);
	// btn.foreColor = 0xf94144;
	//btn.onMouseLeave = (c,e) => log(cal.value);
	btn.onMouseClick = &btnClick;
	// btn.create();
	//---------------
	b3 = new Button(frm, "Sample", 185, 175 );
	b3.backColor = 0xdddf00;
	// b3.foreColor = 0xfb5607;
	b3.onMouseClick = &onb3Click;
	// b3.setGradientColors(0xdc2f02, 0xfaa307);
	// b3.focusFactor = 0.4;
	// b3.create();

	lbl = new Label(frm, "My Label", 20, 105);
	//lbl.backColor = 0xccff66;
	lbl.foreColor = 0xff0000;
	//lbl.autoSize = false;
	//lbl.text = "next text";
	// lbl.create;

    tk = new TrackBar(frm, 20, 145, 150, 40);
    //tk.vertical = true;
	// tk.backColor = 0xff80bf;
	tk.customDraw = true;
    // tk.createHandle();

    tv = new TreeView(frm, 185, 20, 150, 100, true);
	tv.backColor = 0xddddbb;
    // tv.createHandle();

	auto n1 = new TreeNode("Root One");
	auto n2 = new TreeNode("Root Two");
	auto n3 = new TreeNode("Root Three");
	tv.addNodes(n1, n2, n3);
	auto cn1 = new TreeNode("Child1 of Root One");
	auto cn2 = new TreeNode("Child2 of Root One");
	auto cn3 = new TreeNode("Child1 of Root Three");
	auto cn4 = new TreeNode("Child2 of Root Three");
	tv.addChildNodes(n1, cn1, cn2);
	tv.addChildNodes(n3, cn3, cn4);

	auto cn5 = new TreeNode("Child3 of Root One");
	tv.insertChildNode(n1, cn5, 1);


    gb = new GroupBox(frm, "Group Box Improved", 350, 20, 300, 100);
	// gb.backColor = 0xddddbb;
	gb.font = new Font("Calibri", 14);
	gb.foreColor = 0x0015ff;
    // gb.create();

	pb = new ProgressBar(frm, 140, 235);
	pb.step = 10;
	pb.showPercentage = true;
	// pb.create();

	cb = new CheckBox(frm, "CheckBox 1", 185, 140);
	cb.foreColor = 0x006400;
	// cb.create();

	np = new NumberPicker(frm, 20, 235); // 81
    np.backColor = 0xccff66;
    // np.create;

	auto np2 = new NumberPicker(frm, 20, 270); // 81
    // np2.backColor = 0xccff66;
    // np2.create;

	auto np3 = new NumberPicker(frm, 20, 305); // 81
    np3.backColor = 0xf9c74f;
    // np3.create;

	lv = new ListView(frm, 350, 135, 300, 180, true,
						 ["Windows", "Linux", "MacOS"], [80, 120, 100] );

	lv.addRow("XP", "Mountain Lion", "RedHat");
    lv.addRow("Vista", "Mavericks", "Mint");
    lv.addRow("Win7", "Mavericks", "Ubuntu");
    lv.addRow("Win8", "Catalina", "Debian");
    lv.addRow("Win10", " Big Sur", "Kali");

	auto cm = new ContextMenu();
	cm.addMenus("Add Work", "Give Work", "Finish Work");
	lv.contextMenu = cm;

	frm.show();

}


void onb3Click(Control c, EventArgs e) {tk.backColor = 0xfb5607;}


void onClick(Control s, EventArgs e) 	 // @suppress(dscanner.style.undocumented_declaration)
{
	//frm.setGradientBackColor( 0x551ccb, 0xffDD60);
	//frm.backColor = 0xff0000;
	// import std.digest: toHexString;
	// RgbColor rr = RgbColor(0xff0000);
	// // rr.printRgb();
	// rr.lighter(0.65);
	// rr.printRgb();
	// frm.backColor = rr.getUint;

}

void frmLoad(Control s, EventArgs e) 	{ // @suppress(dscanner.style.undocumented_declaration)
	log("form loaded");
}

void frmKeyDown(Control s, KeyEventArgs e) {
	log("Success with - ", e.keyCode);
}

void frmSize(Control c, SizeEventArgs e) {
	log("sized on - ", e.sizedOn);
	writeln("window rect - ", e.windowRect);
}

void btnClick(Control c, EventArgs e) {	//Gradient btn
	auto fod = new FileOpenDialog();
	// auto fod = new FileSaveDialog();
	// auto fod = new FolderBrowserDialog();
	fod.multiSelection = true;
	fod.showDialog(frm.handle);
	writefln("Path: %s", fod.selectedPath);
	foreach (file; fod.fileNames) {writeln(file);}
}
