package;

import golgi.*;
import golgi.meta.MetaGolgi;
import foo.TestApi;
import foo.TestApi.*;


class TestPaths extends haxe.unit.TestCase {
    static var dummy_req = { msg : "dummy"};
    var api : TestApi;
    public function new(){
        var k = new TestMeta();
        api = new TestApi();
        super();
    }

    public function testBasicPath(){
        var meta = new TestMeta();
        var router = TestApi.golgi(api, meta);
        // var res = router.route(["vanilla"], {}, dummy_req);
        var k = TestApiRoute.getName();
        trace(k + " is the value for k");
        var o = TestApiRoute.getConstructors();
        trace(o + " is the value for o");
        this.assertTrue(true);

        // switch(res){
        //     case TestApiRoute.Vanilla(val) : assertEquals(val, "vanilla");
        //     default : this.assertTrue(false);
        // }
    }

    // public function testFailInvalidPath(){
    //     try{
    //         var res = Golgi.run("chocolate", {}, dummy_req, api);
    //         assertEquals(res, "vanilla");
    //     } catch (e : Error) {
    //         var res = switch(e){
    //             case NotFound("chocolate") : true;
    //             default : falsel;
    //         }
    //         assertTrue(res);

    //     }
    // }
    // public function testSingleArg(){
    //     var res = Golgi.run("singlearg/1", {}, dummy_req, api);
    //     assertEquals(res, "1");
    // }
    // public function testFailSingleArg(){
    //     try{
    //         var res = Golgi.run("singlearg/blah", {}, dummy_req, api);
    //     } catch (e : Error){
    //         var res = switch(e){
    //             case InvalidValue("x") : true;
    //             default : false;
    //         }
    //         assertTrue(res);
    //     }
    // }
    // public function testMultipleArgs(){
    //     var res = Golgi.run("multiarg/1/2", {}, dummy_req, api);
    //     assertEquals(res, "12");
    // }
    // public function testParamArgString() {
    //     var res = Golgi.run("paramArgString", {msg:"received"}, dummy_req, api);
    //     assertEquals(res, "received");
    // }
    // public function testParamArgInt() {
    //     var res = Golgi.run("paramArgInt", {msg:"1"}, dummy_req, api);
    //     assertEquals(res, "1");
    // }
    // public function testFailParamArgInt() {
    //     try {
    //         var res = Golgi.run("paramArgInt", {msg:'no'}, dummy_req, api);
    //     } catch (e : Error){
    //         var res = switch(e){
    //             case InvalidValueParam("msg") : true;
    //             default : false;
    //         }
    //         assertTrue(res);
    //     }
    // }
    // public function testMetaGolgi(){
    //     var res = Golgi.run("metagolgi", {}, dummy_req, api);
    //     assertEquals(res, "intercepted");
    // }
    // public function testChain(){
    //     var res = Golgi.run("bang", {}, dummy_req, api);
    //     assertEquals(res, "intercepted!");
    // }
    // public function testDefault(){
    //     var res = Golgi.run("", {}, dummy_req, api);
    //     assertEquals(res, "default");
    // }
    // public function testDefaultRoot(){
    //     var res = Golgi.run("/", {}, dummy_req, api);
    //     assertEquals(res, "default");
    // }
    // public function testSubRoute(){
    //     var res = Golgi.run("passToSub/1/2/sub", {msg :"0"}, dummy_req, api);
    //     assertEquals(res, "sub");
    // }
    // public function testSubRouteAlias(){
    //     var res = Golgi.run("passToSub/1/2/3", {msg : "0"}, dummy_req, api);
    //     assertEquals(res, "subAlias");
    // }
    // public function testSubRouteDefault(){
    //     var res = Golgi.run("passToSub/1/2/", {msg : "0"}, dummy_req, api);
    //     assertEquals(res, "subDefault");
    // }

}





