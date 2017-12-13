import golgi.Api;
import golgi.Golgi;
import golgi.meta.MetaGolgi;
import golgi.Subroute;

typedef Blah = {
    y: String,
    z:Int
}

class Main {
    static function main() {
        var g = new Golgi(new Foo());
        try{
            g.run("food/1/2", {hi : 4}, {a:4});
        } catch (e:Dynamic){
            trace(e + " is the value for e");
        }
        trace("DONE");
    }
}

@:meta(FooMeta)
class Foo extends Api<Req,String> {
    static function bar(context:Req, next : Req->String) : String {
        return next(context) + "!";
    }

    public function food(x  : Int, params : Params, request : Req, subroute : Subroute<Req>) : String {
        trace(x + " is the value for x");
        return 'o';
    }

}


typedef Req = {
    a:Int
}
typedef Res = {}

typedef Params = { hi : Int}

class FooMeta extends MetaGolgi<Req,String> {
    static function burp(){
    }
    function wat(){
    }
}
