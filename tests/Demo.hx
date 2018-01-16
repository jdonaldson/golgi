import golgi.Api;
import golgi.Golgi;
import golgi.meta.MetaGolgi;
import golgi.Subroute;

typedef Blah = {
    y : String,
    z : Int
}


@:expose
class Demo extends Api<Req,String, DemoMeta> {

    @:default
    public function bar() : String {
        return "default";
    }

    // public function food(x  : Int, params : Params, request : Req, subroute : Subroute<Req>) : String {
    public function food(x : String) : String {
        trace(x + " is the value for x");
        return x;
    }
    public static function dump(api : Demo){
        return api.__golgi_dict__;
    }

#if lua
    public static var api = new Demo(new DemoMeta()).__golgi_dict__.t;
#end

}

class Util {
    @:keep
    public static function split_path(str : String) : Array<String> {
        str = str.substring(1);
        return str.split('/');
    }
    static function error(e : golgi.Error) {
        untyped __lua__("ngx.say({0})", Std.string(e));
    }
}



typedef Req = {
    a:Int
}
typedef Res = {}

typedef Params = { hi : Int}

class DemoMeta extends MetaGolgi<Req,String> {
    public function bar(x:Req, next : Req->String) : String {
        return next(x) + "!";
    }
    public function bing(x:Req, next : Req->String) : String {
        return next(x) + "?";
    }
}

