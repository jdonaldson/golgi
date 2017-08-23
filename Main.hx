class Main {
    static function main() {
        var r = new Router(); 
        var n = 100000;
        var t = haxe.Timer.stamp();
        var routes = ["blah", "foob", "doof", "beans", "bear", "bing", "boo", "bad","balls","bed"]; 
        var routes = ["blah"]; 

        for (i in 0...n){
            Dispatch.run("blah", {}, new Blaher());
        }

        var time = (haxe.Timer.stamp() - t);
        var rps = n/time;
        trace(n + " is the value for n");
        trace(time + " is the value for time");
        trace(rps + " is the value for rps");
        var t= haxe.Timer.stamp();
        for (i in 0...n){
            haxe.web.Dispatch.run("foo", new Map(), new Old());
        }
        var time = haxe.Timer.stamp() - t;
        trace(time + " is the value for time");
        var rps = n/time;
        trace(rps + " is the value for rps");
    }
    static function main2(){
    }
}
class Old {
    var count = 0;
    public function new(){}
    function doFoo(){
        count++;
    }
    function doFoo1(){
        count++;
    }
    function doFoo2(){
        count++;
    }
    function doFoo3(){
        count++;
    }
    function doFoo4(){
        count++;
    }
    function doFoo5(){
        count++;
    }
    function doFoo6(){
        count++;
    }
    function doFoo7(){
        count++;
    }
}


class Router extends Api {
    public function foob(?x:Int, k:Float, params : {a : Int, ?b:Float}){
        trace(x + " is the value for x in foob");
        trace(k + " is the value for k");
    }
    public function dood(d:Dispatch, x : Int){
        // trace("dood was called!");
        d.dispatch(new Blaher());
    }
    public function bar(){
        trace("bar was called");
    }
}

class Blaher extends Api {
    public var count =0;
    public function blah(){
        // var f= haxe.Json.stringify(count);
        // var v = haxe.Json.parse(f);
        count++;
    }
    public function foob(){
        count++;
    }
    public function doof(){
        count++;
    }
    public function beans(){
        count++;
    }
    public function bear(){
        count++;
    }
    public function bing(){
        count++;
    }
    public function boo(){
        count++;
    }
    public function bad(){
        count++;
    }
    public function balls(){
        count++;
    }
    public function bed(){
        count++;
    }
}

