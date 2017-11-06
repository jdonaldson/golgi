import golgi.Api;
import golgi.Golgi;

typedef Blah = {
    y: String,
    z:Int
}

class Main {
    static function main() {
        try{
            Golgi.run("food/1", {}, {}, new Foo());
        } catch (e:Dynamic){
            trace(e + " is the value for e");
        }
        trace("DONE");
    }
}

@:context(context)
@:params(params)
class Foo extends Api<Req,String> {
    static function bar(context:Req, next : Req->String) : String {
        return next(context) + "!";
    }
    @:mw(bar)
    public function food(x  : Int, context : String, golgi : Golgi<Req>) : String {
        trace(x + " is the value for x");
        return 'o';
    }

}


typedef Req = {
    a:Int
}
typedef Res = {}

