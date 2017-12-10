import golgi.Api;
import golgi.Golgi;
import golgi.Subroute;

typedef Blah = {
    y: String,
    z:Int
}

class Main {
    static function main() {
        try{
            Golgi.run("food/1/2", {hi : 4}, {}, new Foo());
        } catch (e:Dynamic){
            trace(e + " is the value for e");
        }
        trace("DONE");
    }
}

class Foo extends Api<Req,String> {
    static function bar(context:Req, next : Req->String) : String {
        return next(context) + "!";
    }

    @get @post
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
