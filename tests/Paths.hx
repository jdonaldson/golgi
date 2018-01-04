import golgi.api.*;
import golgi.*;

class Paths extends haxe.unit.TestCase {
    var api  : TestApi;
    static var dummy_req = { msg : "dummy"};
    public function new(){
        api = new TestApi(new TMeta());
        super();
    }
    public function testBasicPath(){
        var res = Golgi.run("vanilla", {}, dummy_req, api);
        assertEquals(res, "vanilla");
    }
    public function testSingleArg(){
        var res = Golgi.run("singlearg/1", {}, dummy_req, api);
        assertEquals(res, "1");
    }
    public function testMultipleArgs(){
        var res = Golgi.run("multiarg/1/2", {}, dummy_req, api);
        assertEquals(res, "12");
    }
}

typedef Req = {msg : String};
typedef Ret = String;
class TMeta extends golgi.meta.MetaGolgi<Req,Ret> {
    public function intercept(req : Req, next : Req->Ret) : Ret {
        return "intercepted";
    }
}

class TestApi extends Api<Req,Ret,TMeta> {
    public function vanilla() : Ret {
        return 'vanilla';
    }
    public function singlearg(x:Int) : Ret {
        return '$x';
    }
    public function multiarg(x:Int,y:Int) : Ret {
        return '$x$y';
    }
    public function interceptRoute(x : Int, y: String) : Ret {
        return '$x and $y were passed to me';
    }
}
