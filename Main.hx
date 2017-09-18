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
        Golgi.run("foo/1", {y:"hi", z:4}, {a:4}, new Foo());
        } catch(e:golgi.Error){
            trace(e + " is the value for e");
            switch(e){
                case InvalidValue : trace("yep");
                default : trace("nope");
            }
        } catch (e : Dynamic){
            trace('whaaaa');
        }
    }
}

class Foo extends Api<Req,String> {
    public function foo(x:Int, params : {y : String, z : Int}, context : Req, golgi : Golgi) : String {
        trace(context + " is the value for context");
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

typedef Req = {
    a:Int
}
typedef Res = {}
