#!rdmd
import std.stdio;
import wings;

// Since, Wings use delegates for event handling and D is an OOP language...
// We can wrap up the entire app in a class. It's handy.
class App {
	// import wings.commons: log;
	this() {
		this.createControls();
		this.setControlProps();		
	}

	void createControls() {
		// First of all, create the form aka window.
		frm = new Form("Wing window in D Lang", 900, 500);
		frm.enablePrintPoint();
		// frm.createHandle();

		//Let's create a tray icon for this program.
		tic = new TrayIcon("Wings tray icon!", "wings_icon.ico");

		// Now, add a context menu to our tray. '|' is for separator.
		tic.addContextMenu(true, TrayMenuTrigger.anyClick, "Windows_ti", "Linux_ti", "|", "MacOS_ti");

		// // If this set to true, all control handles will be
		// // created right after the class ctor finished.
		frm.createChildHandles = true; 

		//Let's add a menu bar and some menu items
		mb = frm.addMenuBar(true, "Windows", "Linux", "MacOS");
		
		// Add 3 buttons
		btn1 = new Button(frm, "Normal", 10, 10);
		btn2 = new Button(frm, "Color", btn1.right!10, 10);
		btn3 = new Button(frm, "Gradient", btn2.right!10, 10);

		cmb = new ComboBox(frm, btn3.right!10, 10, 150, 30);
		dtp = new DateTimePicker(frm, cmb.right!10, 10); 

		gb1 = new GroupBox(frm, "Compiler Options", 10, btn1.bottom!10, 200, 170);
		cb1 = new CheckBox(gb1, "Profile", 15, 35);
		cb2 = new CheckBox(gb1, "Low Mem", 15, 65);
		rb1 = new RadioButton(gb1, "Console App", 15, 95);
		rb2 = new RadioButton(gb1, "Windowed App", 15, 125);
		rb2.checked = true;

		gb2 = new GroupBox(frm, "Project Settings", 10, gb1.bottom!10, 220, 100);
		lb1 = new Label(gb2, "Line Space", 10, 35);
		lb2 = new Label(gb2, "Thread Count", 10, 65);

		// NumberPicker aka NumericUpdown in .NET
		np1 = new NumberPicker(gb2, 100, 30);	
		np2 = new NumberPicker(gb2, 100, 60, btnLeft : true);

		pgb = new ProgressBar(frm, 10, gb2.bottom!10, 204, 25);
		// auto catimage = "D:\\Downloads_Ex\\2026\\nvidia-com.png";
		pbx = new PictureBox(frm, 710, 272, 150, 150, "nvidia-com.png", PictureSizeMode.stretch);

		tb = new TextBox(frm, 10, pgb.bottom!10, pgb.width, 30);
		lbx = new ListBox(frm, gb1.right!10, btn1.bottom!15, 120, 160);

		// ListView ctor takes an array for items and another for col widths.
		lv = new ListView(frm, lbx.right!10, btn1.bottom!15, 300, 180);

		// Trackbar ctor takes a delegate for onValueChanged event.
		tkb1 = new TrackBar(frm, dtp.right!10, 10, 150, 40, true, &this.onTrackValueChanged);

		tv = new TreeView(frm, lv.right!10, lv.ypos, 200, 200);

		// Calendar aka MonthCalendar in .NET
		cal = new Calendar(frm, gb2.right!10, lv.bottom!15);

		// Another trackbar but this time, it's vertical.
		tkb2 = new TrackBar(frm, 500, 270, 60, 150, vertical: true, cdraw: true);

		// Add a timer with a delegate to handle the onTick event.
		tmr = frm.addTimer(&this.timerTickHandler, 800);
	}

	void setControlProps() {	
		// Set some properties of our controls.
		btn1.onClick = &this.btn1OnClick;
		btn1.font.name = "Blackadder ITC";
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
		tb.cueBanner = "Type something here...";   
		tkb1.onValueChanged = &this.onTrackValueChanged;
		 
		lbx.addRange("Windows", "Linux", "MacOS", "ReactOS");

		lv.addColumns(["Windows",  "MacOS", "Linux"], [80, 120, 100]);
		lv.addRow("XP", "Mountain Lion", "RedHat");
		lv.addRow("Vista", "Mavericks", "Mint");
		lv.addRow("Win7", "Mavericks", "Ubuntu");
		lv.addRow("Win8", "Catalina", "Debian");
		lv.addRow("Win10", "Big Sur", "Kali");

		// lv.createHandle();
		lv.addContextMenu("Windows", "Linux", "|", "MacOS");


		tv.backColor = 0xddddbb;
		tv.addNodeWithChildren("Windows", "Win 11", "Win 10", "Win 8");
		tv.addNodeWithChildren("Linux", "Ubuntu", "Debian", "Fedora");
		tv.addNodeWithChildren("MacOS", "Monterey", "Catalina", "Big Sur");
		// tv.createHandle();
		// Add menu items for our main menus.
		mb["Windows"].addItems("Windows 8", "|", "Windows 10",  "Windows 11");
		mb["Linux"].addItems("Ubuntu", "Debian", "Kali");
		mb["MacOS"].addItems("Mavericks", "Catalina", "Big Sur");

		// Add menu click event handler for tray icon context menu.
		tic.contextMenu["Windows_ti"].onClick = &this.onContextMenuClick;

		// Add handler for listview's context menu.
		lv.contextMenu["Linux"].onClick = &this.onLVContextMenuClick;
		np1.onMouseEnter = &this.menter;
		np1.onMouseLeave = &this.mleave;
	}

	void display() {this.frm.show();}

	// When clicked on button, combo's drop down style will change. 
	void btn1OnClick(Object s, EventArgs e) {
		auto ofd = new FileOpenDialog("Open files", "", 
										"Pdf Files|*.pdf|Text Files|*.txt");
		ofd.multiSelection = true;
		if (ofd.showDialog()) {
			print("Selected file: ", ofd.fileNames);
		}
	}

	// Timer tick event handler
	void timerTickHandler(Object c, EventArgs e) {writeln("Timer ticked...");}

	// ProgressBar will show the track bar values.
	void onTrackValueChanged(Object c, EventArgs e) {
		pgb.value = tkb1.value;
	}

	void onContextMenuClick(Object m, EventArgs e) {
		// delay(3000);
		writeln("Windows menu clicked");
	}

	void onLVContextMenuClick(Object m, EventArgs e) {
		// delay(3000);
		writeln("Linux menu clicked");
	}

	void btn3Click(Object c, EventArgs e) {
		// this.tic.showBalloon("Wings Balloon", "This is Wings Balloon Text", 3000);
		print("Gradient button clicked");
	}
	void menter(Object c, EventArgs e) {
		writeln("Mouse entered combo");
	}
	void mleave(Object c, EventArgs e) {
		writeln("Mouse leave from combo");
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
		PictureBox pbx;
		RadioButton rb1, rb2;
		TextBox tb;
		TrackBar tkb1, tkb2;
		TreeView tv;
		Timer tmr;	
		TrayIcon tic;
}


void main()
{
	import core.sys.windows.windows;
	auto app = new App();	
	app.btn1.tpr();
	app.display();
	
}

// 91471 66 30 84 7