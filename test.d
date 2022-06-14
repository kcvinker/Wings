
//import std.conv;
import std.stdio : log = writeln;
import std.stdio ;
//import intinc;
import std.typecons ;

int global = 1000;


void main() {
    
    
    writeln("Vinod is learning 'D' in Sublime Text 4 !");
    //alias Person = tuple!(string, "name", int, "age", double, "salary") ;
    
    cont(50) ;
    

}

void cont(int tv) 
in {assert(tv == 50);} do
{
    writeln("value of tv is ",tv);
}

struct PostBlit {
    int[] foo;
     
    this(this) {foo = foo.dup;}
}
void printPtr(PostBlit cpb) {
    writeln("Inside: ", cpb.foo.ptr);
}

struct Person {
    string name = "Sample" ;
    int age = 5;
    int salary = 40000;

   this(int x, int y) {this.age = x ; this.salary = y;}

}

class Animal {
    int age = 2;
    string name = "fluffy";

    static Animal ani ;

    this(){}

    this(int a, string s) 
    {
        this.name = s;
        this.age = a ;
        writeln("Animal is constructed");
    }

    static this() {
        writeln("static constructed") ;
        ani = new Animal() ;
        ani.name = "Static";

    }

    void scp(ref int y){
        //int x = 45;
        writeln("x is ", y);
        scope(exit) y = 4;
        writeln("x is ", y);

    }


    ~this(){writeln("Animal is destroyed");}
    void print(){writeln("Animal is printing");}


}




//static ~this() {writeln("Static destroyed");} // Module destructer


