import golgi.Api;
import golgi.Builder;
import golgi.Golgi;

class Main {
    static function main() {
        var n = 100000;
        trace(n + " is the value for n");
        var t = haxe.Timer.stamp();
        var routes = ["blah1/1","blah2/1","blah3/1","blah4/1","blah5/1","blah6/1"]; 
        var sum = 0.0;
        var t = haxe.Timer.stamp();
        var b = new Blaher();
        for (i in 0...n){
            var route = routes[Std.random(routes.length)];
            Golgi.run(route, {}, b);
        }
        var time = (haxe.Timer.stamp() - t);
        var rps = n/time;
        var spr = time/n;
        trace("[golgi] " + b.count + " is the value for b.count");
        trace("[golgi] " + time + " is the value for time");
        trace("[golgi] " + spr + " is the value for spr");
        trace("[golgi] " + rps + " is the value for rps");

        var t= haxe.Timer.stamp();
        var o = new Old();
        for (i in 0...n){
            var route = routes[Std.random(routes.length)];
            haxe.web.Dispatch.run(route, new Map(), o);
        }
        var time = haxe.Timer.stamp() - t;
        var rps = n/time;
        trace("-----------");
        trace("[Dispatch] " + o.count + " is the value for o.count");
        trace("[Dispatch] " + time + " is the value for time");
        trace("[Dispatch] " + spr + " is the value for spr");
        trace("[Dispatch] " + rps + " is the value for rps");

    }
    static function main2(){
    }
}
class Old {
    public var count = 0;
    public function new(){}
    function doBlah1(x:Int){ count++; }
    function doBlah2(x:Int){ count++; }
    function doBlah3(x:Int){ count++; }
    function doBlah4(x:Int){ count++; }
    function doBlah5(x:Int){ count++; }
    function doBlah6(x:Int){ count++; }
    function doBlah7(x:Int){ count++; }
}



class Blaher extends Api {
    public var count = 0;
    public function blah1(x:Int){ count++; }
    public function blah2(x:Int){ count++; }
    public function blah3(x:Int){ count++; }
    public function blah4(x:Int){ count++; }
    public function blah5(x:Int){ count++; }
    public function blah6(x:Int){ count++; }
    public function blah7(x:Int){ count++; }
}

