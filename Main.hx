import golgi.BasicApi;
import golgi.Golgi;
import golgi.meta.MetaGolgi;
import golgi.Subroute;

typedef Blah = {
    y: String,
    z:Int
}

class Main {
    static var x = {
        dingo : 0
    }
    static function main() {
        try{
            var k = Golgi.run( new Foo(new FooMeta()), "food/1/2", {hi : 4}, {a:4});
            trace(k + " is the value for k");
        } catch (e:Dynamic){
            trace(e + " is the value for e");
        }
        trace("DONE");
    }
}

class Foo extends BasicApi<Req,String> {
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
    public function bar(x:Req, next : Req->String) : String {
        return next(x) + "!";
    }
}
