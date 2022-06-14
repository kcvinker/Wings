
//import std.conv;
import std.stdio : log = writeln;
import std.stdio ;
import std.algorithm;
import std.typecons ;
import std.traits ;
import core.vararg ;
import std.conv ;
import std.array;
import std.process;
//import std.container;

int global = 1000;
immutable int sams = 41;
alias int_ptr = int* ;

void main() {   
    
    
	
	// string conEmu = r"E:\cmder\vendor\conemu-maximus5\ConEmu64.exe" ;
	// string wDir = r"E:\OneDrive Folder\OneDrive\Programming\D Lang\WinGLib" ;
	// string wfDir = r"E:\OneDrive Folder\OneDrive\Programming\Odin\Winforms";
	// //auto cmu = execute([conEmu, "-run", "dmd -i -run", "app.d"], null, Config.none, size_t.max, wDir);
	// auto cmu = execute([conEmu, "-run", "odin run", "app.odin", "-file"], null, Config.none, size_t.max, wfDir);
	//test();
    
    double val = 46;
	double pre = 0.2;
	double re = val + pre;
	log(re);
   
}


void test() {
	auto smp = new Sample;
	log("We are doing some processings");
	log("Okay we can close now");

}

class Sample {
	this() {
		this.mToken = 100;
		log("Sample created and mToken is - ", this.mToken);
	}
	
	~this() {
		log("destroyed");
	}
	
	private :
		uint mToken ;
}


enum Colors : uint {red, green = 50, blue, yellow, orange, white}

void sample(uint clr) {
	log("the color is - ", clr + 9);
}

