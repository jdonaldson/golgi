import golgi.Api;
import golgi.Builder;
import golgi.Golgi;

typedef Blah = {
    y: String,
    z:Int
}

class Main {
    static function main() {
        try{
        Golgi.run("foo/1", {y:"hi", z:"ho"}, {}, new Foo());
        } catch(e:golgi.Error){
            switch(e){
                case InvalidValue : trace("yep");
                default : trace("nope");
            }
            trace(e + " is the value for e");
        } catch (e : Dynamic){
            trace('whaaaa');
        }
    }
}

class Foo extends Api<Req,String> {
    public function foo(x:Int, params : {y : String, z : Int}, context : Req) : String {
        trace((params.z + 4) + " is the value for (params.z + 4)");
        trace(x + " is the value for x");
        trace(params.y + " is the value for params.y");
        return "foo";
    }
}

abstract Boo(Int){
    public function new(i:Int){
        this = i;
    }
    public function toString(){
        return [this].toString();
    }
}

typedef Req = {}
typedef Res = {}
