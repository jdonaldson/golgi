package;

import golgi.*;
import golgi.meta.MetaGolgi;
import foo.*;
import foo.TestApiGolgi;


class TestPaths extends haxe.unit.TestCase {
    public function shouldthrow() {
        fail("Test should have thrown error");
    }
    public function fail(msg : String){
        print(msg);
        assertTrue(false);
    }
    static var req = { msg : "dummy"};
    var api : TestApi;
    var golgi : TestApiGolgi;
    var meta : TestMeta;
    public function new(){
        api = new TestApi();
        meta = new TestMeta();

        golgi = new TestApiGolgi(api, meta);
        super();
    }

    public function testBasicPath(){
        var res = golgi.route("vanilla", {}, req);
        assertTrue(res.match(Vanilla("vanilla")));
    }

    public function testFailInvalidPath(){
        try{
            var res = golgi.route("chocolate", {}, req);
            shouldthrow();
        } catch (e : Error) {
            assertTrue(e.match(NotFound("chocolate")));
        }
    }

    public function testSingleArg(){
        var res = golgi.route("singlearg/1", {}, req);
        assertTrue(res.match(Singlearg('1')));
    }

    public function testFailSingleArg(){
        try{
            var res = golgi.route("singlearg/blah", {}, req);
            shouldthrow();
        } catch (e : Error){
            assertTrue(e.match(InvalidValue("x")));
        }
    }

    public function testMultipleArgs(){
        var res = golgi.route("multiarg/1/2", {}, req);
        assertTrue(res.match(Multiarg("12")));
    }

    public function testParamArgString() {
        var res = golgi.route("paramArgString", {msg:"received"}, req);
        assertTrue(res.match(ParamArgString("received")));
    }

    public function testParamArgInt() {
        var res = golgi.route("paramArgInt", {msg:"1"}, req);
        assertTrue(res.match(ParamArgInt("1")));
    }

    public function testFailParamArgInt() {
        try {
            var res = golgi.route("paramArgInt", {msg:'no'}, req);
            shouldthrow();
        } catch (e : Error){
            assertTrue(e.match(InvalidValueParam("msg")));
        }
    }

    public function testMetaGolgi(){
        var res = golgi.route("metagolgi", {}, req);
        assertTrue(res.match(Intercepted));
    }

    public function testChain(){
        var res = golgi.route("bang", {}, req);
        assertTrue(res.match(Intercepted));
    }

    public function testDefault(){
        var res = golgi.route("", {}, req);
        assertTrue(res.match(DefaultRoute("default")));
    }

    public function testDefaultRoot(){
        var res = golgi.route("/", {}, req);
        assertTrue(res.match(DefaultRoute("default")));
    }

    public function testSubRoute(){
        var res = golgi.route("passToSub/1/2/sub", {msg :"0"}, req);
        assertTrue(res.match(PassToSub("12sub_1")));
    }

    public function testSubRouteAlias(){
        var res = golgi.route("passToSub/1/2/3", {msg : "0"}, req);
        assertTrue(res.match(PassToSub("subAlias")));
    }

    public function testSubRouteDefault(){
        var res = golgi.route("passToSub/1/2/", {msg : "0"}, req);
        assertTrue(res.match(PassToSub("default")));
    }

}

