class Main {
    static function main() {
        var r = new Router(); 
        var n = 100000;
        trace(n + " is the value for n");
        var t = haxe.Timer.stamp();
        var routes = ["blah1","blah2","blah3","blah4","blah5","blah6"]; 
        var sum = 0.0;
        var t = haxe.Timer.stamp();
        var b = new Blaher();
        for (i in 0...n){
            var route = routes[Std.random(routes.length)];
            Dispatch.run(route, {}, b);
        }
        var time = (haxe.Timer.stamp() - t);
        var rps = n/time;
        trace(time + " is the value for time");
        trace(rps + " is the value for rps");
        var t= haxe.Timer.stamp();
        var o = new Old();
        for (i in 0...n){
            var route = routes[Std.random(routes.length)];
            haxe.web.Dispatch.run(route, new Map(), o);
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
    function doBlah1(){
        count++;
    }
    function doBlah2(){
        count++;
    }
    function doBlah3(){
        count++;
    }
    function doBlah4(){
        count++;
    }
    function doBlah5(){
        count++;
    }
    function doBlah6(){
        count++;
    }
    function doBlah7(){
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
    public function blah1(){
        count++;
    }
    public function blah2(){
        count++;
    }
    public function blah3(){
        count++;
    }
    public function blah4(){
        count++;
    }
    public function blah5(){
        count++;
    }
    public function blah6(){
        count++;
    }
    public function blah7(){
        count++;
    }
}

