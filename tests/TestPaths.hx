import golgi.api.*;
import golgi.*;

class TestPaths extends haxe.unit.TestCase {
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
    public function testFailInvalidPath(){
        try{
            var res = Golgi.run("chocolate", {}, dummy_req, api);
            assertEquals(res, "vanilla");
        } catch (e : Error) {
            var res = switch(e){
                case NotFound("chocolate") : true;
                default : false;
            }
            assertTrue(res);

        }
    }
    public function testSingleArg(){
        var res = Golgi.run("singlearg/1", {}, dummy_req, api);
        assertEquals(res, "1");
    }
    public function testFailSingleArg(){
        try{
            var res = Golgi.run("singlearg/blah", {}, dummy_req, api);
        } catch (e : Error){
            var res = switch(e){
                case InvalidValue("x") : true;
                default : false;
            }
            assertTrue(res);
        }
    }
    public function testMultipleArgs(){
        var res = Golgi.run("multiarg/1/2", {}, dummy_req, api);
        assertEquals(res, "12");
    }
    public function testParamArgString() {
        var res = Golgi.run("paramArgString", {msg:"received"}, dummy_req, api);
        assertEquals(res, "received");
    }
    public function testParamArgInt() {
        var res = Golgi.run("paramArgInt", {msg:1}, dummy_req, api);
        assertEquals(res, "1");
    }
    public function testFailParamArgInt() {
        try {
            var res = Golgi.run("paramArgInt", {msg:'no'}, dummy_req, api);
        } catch (e : Error){
            var res = switch(e){
                case InvalidValueParam("msg") : true;
                default : false;
            }
            assertTrue(res);
        }
    }
    public function testMetaGolgi(){
        var res = Golgi.run("metagolgi", {}, dummy_req, api);
        assertEquals(res, "intercepted");
    }
    public function testChain(){
        var res = Golgi.run("bang", {}, dummy_req, api);
        assertEquals(res, "intercepted!");
    }
    public function testDefault(){
        var res = Golgi.run("", {}, dummy_req, api);
        assertEquals(res, "default");
    }
    public function testDefaultRoot(){
        var res = Golgi.run("/", {}, dummy_req, api);
        assertEquals(res, "default");
    }
    public function testSubRoute(){
        var res = Golgi.run("passToSub/1/2/sub", {msg : 0}, dummy_req, api);
        assertEquals(res, "sub");
    }
    public function testSubRouteAlias(){
        var res = Golgi.run("passToSub/1/2/3", {msg : 0}, dummy_req, api);
        assertEquals(res, "subAlias");
    }
    public function testSubRouteDefault(){
        var res = Golgi.run("passToSub/1/2/", {msg : 0}, dummy_req, api);
        assertEquals(res, "subDefault");
    }
}

typedef Req = {msg : String};
typedef Ret = String;

class TMeta extends golgi.meta.MetaGolgi<Req,Ret> {
    public function intercept(req : Req, next : Req->Ret) : Ret {
        return "intercepted";
    }
    public function bang(req : Req, next : Req->Ret) : Ret{
        return next(req) + "!";
    }
}

class TestApi extends Api<Req,Ret,TMeta> {

    @:default
    public function defaultRoute() : Ret {
        return 'default';
    }
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
    public function paramArgString(params : { msg : String} ) : Ret {
        return params.msg;
    }
    public function paramArgInt(params : { msg : Int} ) : Ret {
        return params.msg + '';
    }
    public function passToSub(arg : Int, arg2 : Int, params : { msg : Int }, subroute : Subroute<Req>) : Ret {
        return subroute.run(new SubTest(new TMeta()));
    }

    @intercept
    public function metagolgi() : Ret {
        return 'not intercepted';
    }

    @bang @intercept
    public function bang() : Ret {
        return 'not intercepted';
    }
}

class SubTest extends Api<Req,Ret,TMeta> {
    public function sub() : Ret {
        return 'sub';
    }

    @:route('3')
    public function subAlias( params : {msg : Int}, request : Req) : Ret {
        return 'subAlias';
    }

    @:default
    public function subDefault(request : Req) : Ret {
        return 'subDefault';
    }
}
