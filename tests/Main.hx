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
        var fm = new FooMeta();
        var f = new Foo(fm);
        var x = haxe.rtti.Meta.getType(Foo);
        trace(x + " is the value for x");
        try {
            var k = Golgi.run("food/1", {hi : 4}, {a:4},f);
            trace(k + " is the value for k");
            var o = Golgi.run("", {hi : 4}, {a:4}, f);
            trace(o + " is the value for o");
        } catch (e:Dynamic){
            trace(e + " is the value for e");
        }
        trace("DONE");
    }
}

class Dood extends golgi.basic.Api<Any,Any> {
    public function bar() : Any {
        return 'hi';
    }
}

@bing @bar
class Foo extends Api<Req,String, FooMeta> {
    static function bar(context:Req, next : Req->String) : String {
        return next(context) + "!";
    }

    @:default
    public function bard() : String {
        return "HI";
    }

    @_golgi_pass
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
    public function bar(x:Req, next : Req->String) : String {
        return next(x) + "!";
    }
    public function _golgi_pass(x : Req, next : Req->String) : String{
        return next(x);
    }
    public function bing(x:Req, next : Req->String) : String {
        return next(x) + "?";
    }
}
