package;

import golgi.*;
import golgi.MetaGolgi;
import foo.*;
import foo.TestApiGolgi;
using TestPaths.PathTools;


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
        var res = golgi.route("vanilla".path(), {}, req);
        assertTrue(res.match(Vanilla("vanilla")));
    }

    public function testFailInvalidPath(){
        try{
            var res = golgi.route("chocolate".path(), {}, req);
            shouldthrow();
        } catch (e : Error) {
            assertTrue(e.match(NotFound("chocolate")));
        }
    }

    public function testSingleArg(){
        var res = golgi.route("singlearg/1".path(), {}, req);
        assertTrue(res.match(Singlearg('1')));
    }

    public function testFailSingleArg(){
        try{
            var res = golgi.route("singlearg/blah".path(), {}, req);
            shouldthrow();
        } catch (e : Error){
            assertTrue(e.match(InvalidValue("x")));
        }
    }

    public function testMultipleArgs(){
        var res = golgi.route("multiarg/1/2".path(), {}, req);
        assertTrue(res.match(Multiarg("12")));
    }

    public function testParamArgString() {
        var res = golgi.route("paramArgString".path(), {msg:"received"}, req);
        assertTrue(res.match(ParamArgString("received")));
    }

    public function testParamArgInt() {
        var res = golgi.route("paramArgInt".path(), {msg:"1"}, req);
        assertTrue(res.match(ParamArgInt("1")));
    }

    public function testFailParamArgInt() {
        try {
            var res = golgi.route("paramArgInt".path(), {msg:'no'}, req);
            shouldthrow();
        } catch (e : Error){
            assertTrue(e.match(InvalidValueParam("msg")));
        }
    }

    public function testMetaGolgi(){
        var res = golgi.route("metagolgi".path(), {}, req);
        assertTrue(res.match(Intercepted));
    }

    public function testChain(){
        var res = golgi.route("bang".path(), {}, req);
        assertTrue(res.match(Intercepted));
    }

    public function testDefault(){
        var res = golgi.route("".path(), {}, req);
        assertTrue(res.match(DefaultRoute("default")));
    }

    public function testDefaultRoot(){
        var res = golgi.route("/".path(), {}, req);
        assertTrue(res.match(DefaultRoute("default")));
    }

    public function testSubRoute(){
        var res = golgi.route("passToSub/1/2/sub".path(), {msg :"0"}, req);
        assertTrue(res.match(PassToSub("12sub_1")));
    }

    public function testSubRouteAlias(){
        var res = golgi.route("passToSub/1/2/3".path(), {msg : "0"}, req);
        assertTrue(res.match(PassToSub("subAlias")));
    }

    public function testSubRouteDefault(){
        var res = golgi.route("passToSub/1/2/".path(), {msg : "0"}, req);
        assertTrue(res.match(PassToSub("default")));
    }

    public function testBasic() {
        var api = new TestBasicApi();
        var golgi = new TestBasicApiGolgi(api);
        var res = golgi.route("foo".path(), {}, {});
        assertTrue(res.match(Foo(1)));
    }

}


class PathTools {
    public static function path(str:String){
        if (str.charAt(0)== "/"){
            return str.substring(1).split("/");
        } else {
            return str.split("/");
        }
    }
}
