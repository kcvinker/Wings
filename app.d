#!rdmd
import std.stdio;
import wings;

// Since, Wings use delegates for event handling and D is an OOP language...
// We can wrap up the entire app in a class. It's handy.
class App {

	this() 
	{
		this.createControls();
		this.setControlProps();		
	}

	void createControls()
	{
		// First of all, create the form aka window.
		frm = new Form("Wing window in D Lang", 920, 500);
		frm.createHandle();

		// Let's create a tray icon for this program.
		tic = new TrayIcon("Wings tray icon!", "wings_icon.ico");

		// Now, add a context menu to our tray. '|' is for separator.
		tic.addContextMenu(TrayMenuTrigger.rightClick, "Windows_ti", "Linux_ti", "|", "MacOS_ti");


		// If this set to true, all control handles will be
		// created right after the class ctor finished.
		frm.createChildHandles = true; 

		//Let's add a menu bar and some menu items
		mb = frm.addMenuBar("Windows", "Linux", "MacOS");
		
		// Add 3 buttons
		btn1 = new Button(frm, "Normal", 10, 10);
		btn2 = new Button(frm, "Color", btn1.right!10, 10);
		btn3 = new Button(frm, "Gradient", btn2.right!10, 10);

		cmb = new ComboBox(frm, btn3.right!10, 10, 150, 30);
		dtp = new DateTimePicker(frm, cmb.right!10, 10); 

		gb1 = new GroupBox(frm, "Compiler Options", 10, btn1.bottom!10, 200, 170);
		cb1 = new CheckBox(frm, "Profile", 15, btn1.bottom!40);
		cb2 = new CheckBox(frm, "Low Mem", 15, cb1.bottom!10);
		rb1 = new RadioButton(frm, "Console App", 15, cb2.bottom!10);
		rb2 = new RadioButton(frm, "Windowed App", 15, rb1.bottom!10);

		gb2 = new GroupBox(frm, "Project Data", 10, gb1.bottom!10, 220, 100);
		lb1 = new Label(frm, "Line Space", gb2.left!10, gb2.top!30);
		lb2 = new Label(frm, "Thread Count", gb2.left!10, lb1.bottom!10);

		// NumberPicker aka NumericUpdown in .NET
		np1 = new NumberPicker(frm, lb1.right!33, gb2.top!25);	
		np2 = new NumberPicker(frm, lb2.right!10, gb2.top!57, btnLeft: true);

		pgb = new ProgressBar(frm, 10, gb2.bottom!10, 204, 25, true);
		tb = new TextBox(frm, 10, pgb.bottom!10, pgb.width, 30);
		lbx = new ListBox(frm, gb1.right!10, btn1.bottom!15, 120, 160);

		// ListView ctor takes an array for items and another for col widths.
		lv = new ListView(frm, lbx.right!10, btn1.bottom!15, 300, 180, true,
 					 ["Windows", "Linux", "MacOS"], [80, 120, 100] );

		// Trackbar ctor takes a delegate for onValueChanged event.
		tkb1 = new TrackBar(frm, dtp.right!10, 10, 150, 40, true, true, &this.onTrackValueChanged);

		tv = new TreeView(frm, lv.right!10, lv.ypos, 200, 200, true);

		// Calendar aka MonthCalendar in .NET
		cal = new Calendar(frm, gb2.right!10, lv.bottom!15);

		// Another trackbar but this time, it's vertical.
		tkb2 = new TrackBar(frm, 500, 270, 60, 150, vertical: true, cdraw: true);

		// Add a timer with a delegate to handle the onTick event.
		tmr = frm.addTimer(800, &this.timerTickHandler);

	}

	void setControlProps()
	{	
		// Set some properties of our controls.
		btn1.onClick = &this.btn1OnClick;
		btn2.backColor = 0x83c5be;
		btn3.setGradientColors(0xeeef20, 0x70e000);
		btn3.onClick = &this.btn3Click;
		cmb.addRange("Form", "Button", "Calendar", "CheckBox", "ComboBox", "DateTimePicker", "GroupBox", 4500);
		cmb.dropDownStyle = DropDownStyle.labelCombo;
		cmb.selectedIndex = 4;
		gb1.foreColor = 0xd90429; // This only works for GroupBox text.
		np1.foreColor = 0x3f37c9;
		np1.step = 0.25; 
		np2.decimalPrecision = 0;
		np2.backColor = 0xcaffbf; 
		pgb.showPercentage = true;
		tb.foreColor = 0xff0000;    
		lbx.addRange("Windows", "Linux", "MacOS", "ReactOS");	
		lv.addRow("XP", "Mountain Lion", "RedHat");
		lv.addRow("Vista", "Mavericks", "Mint");
		lv.addRow("Win7", "Mavericks", "Ubuntu");
		lv.addRow("Win8", "Catalina", "Debian");
		lv.addRow("Win10", "Big Sur", "Kali");
		lv.addContextMenu("Windows", "Linux", "|", "MacOS");
		tv.backColor = 0xddddbb;
		auto n1 = new TreeNode("Windows");
		auto n2 = new TreeNode("Linux");
		auto n3 = new TreeNode("MacOS");
		auto n4 = new TreeNode("ReactOS");
		tv.addNodes(n1, n2, n3, n4);
		auto wn1 = new TreeNode("Win 11");
		auto wn2 = new TreeNode("Win 10");
		auto wn3 = new TreeNode("Win 8");	
		tv.addChildNodes(n1, wn1, wn2, wn3);
		auto ln1 = new TreeNode("Ubuntu");
		auto ln2 = new TreeNode("Debian");
		auto ln3 = new TreeNode("Fedora");
		tv.addChildNodes(n2, ln1, ln2, ln3);
		auto mn1 = new TreeNode("Monterey");
		auto mn2 = new TreeNode("Catalina");
		auto mn3 = new TreeNode("Mojave");
		tv.addChildNodes(n3, mn1, mn2, mn3);

		// Add menu items for our main menus.
		mb["Windows"].addItems("Windows 8", "|", "Windows 10",  "Windows 11");
		mb["Linux"].addItems("Ubuntu", "Debian", "Kali");
		mb["MacOS"].addItems("Mavericks", "Catalina", "Big Sur");

		// Add menu click event handler for tray icon context menu.
		tic.contextMenu["Windows_ti"].onClick = &this.onContextMenuClick;

		// Add handler for listview's context menu.
		lv.contextMenu["Linux"].onClick = &this.onLVContextMenuClick;
	}

	void display() {this.frm.show();}

	// When clicked on button, combo's drop down style will change. 
	void btn1OnClick(Control s, EventArgs e) {
		this.cmb.dropDownStyle = DropDownStyle.textCombo;
	}

	// Timer tick event handler
	void timerTickHandler(Control c, EventArgs e) {writeln("Timer ticked...");}

	// ProgressBar will show the track bar values.
	void onTrackValueChanged(Control c, EventArgs e) {
		pgb.value = tkb1.value;
	}

	void onContextMenuClick(MenuItem m, EventArgs e) {
		// delay(3000);
		writeln("Windows menu clicked");
	}

	void onLVContextMenuClick(MenuItem m, EventArgs e) {
		// delay(3000);
		writeln("Linux menu clicked");
	}

	void btn3Click(Control c, EventArgs e) {
		this.tic.showBalloon("Wings Balloon", "This is Wings Balloon Text", 3000);
	}

	private:
		Form frm;
		Button btn1, btn2, btn3;
		Calendar cal;
		CheckBox cb1, cb2;
		ComboBox cmb;
		DateTimePicker dtp;
		GroupBox gb1, gb2;
		Label lb1, lb2;
		ListBox lbx;
		ListView lv;
		MenuBar mb;
		NumberPicker np1, np2;
		ProgressBar pgb;
		RadioButton rb1, rb2;
		TextBox tb;
		TrackBar tkb1, tkb2;
		TreeView tv;
		Timer tmr;	
		TrayIcon tic;
}


void main()
{
	auto app = new App();	
	app.display();
}