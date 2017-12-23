import golgi.api.PlainApi;
import golgi.api.Api;
import golgi.Golgi;
import golgi.meta.MetaGolgi;
import golgi.Subroute;

typedef Blah = {
    y: String,
    z:Int
}

class Main {
    static function main() {
        var fm = new FooMeta();
        try{
            var k = Golgi.run("food/1/2", {hi : 4}, {a:4}, new Foo());
            trace(k + " is the value for k");
            var o = Golgi.run("", {hi : 4}, {a:4}, new Foo());
            trace(o + " is the value for o");
        } catch (e:Dynamic){
            trace(e + " is the value for e");
        }
        trace("DONE");
    }
}

@bing @bar
class Foo extends Api<Req,String> {
    static function bar(context:Req, next : Req->String) : String {
        return next(context) + "!";
    }

    @:default
    public function bard() : String {
        return "HI";
    }
    public function food(x  : Int, params : Params, request : Req, subroute : Subroute<Req>) : String {
        return 'o';
    }

}


typedef Req = {
    a:Int
}
typedef Res = {}

typedef Params = { hi : Int}

class FooMeta extends MetaGolgi<Req,String> {
    public function bar(x:Req, next : Req->String) : String {
        return next(x) + "!";
    }
    public function bing(x:Req, next : Req->String) : String {
        return next(x) + "?";
    }
}
