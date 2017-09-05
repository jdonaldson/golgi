import golgi.Api;
import golgi.Builder;
import golgi.Golgi;
typedef Blah = {
    y: String,
    z:Int
}

class Main {
    static function main() {
        Golgi.run("foo/1/3", {y:"hi", z:"ho"}, new Foo());
    }
}

class Foo extends Api {
    public function foo(x:Int, params : {y : String, z : Int}){
        trace((params.z + 4) + " is the value for (params.z + 4)");
        trace(x + " is the value for x");
        trace(params.y + " is the value for params.y");
    }
}
