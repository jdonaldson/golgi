import golgi.Api;
import golgi.Builder;
import golgi.Golgi;

class SpeedTest {
    static function main() {
        var n = 100000;
        trace(n + " is the value for n");
        var t = haxe.Timer.stamp();
        var routes = ["blah1/1/2","blah2/1/5","blah3/1/2","blah4/1/8","blah5/1/2","blah6/1/2"]; 
        var routes = ["blah1/1/2","blah2/1/5","blah3/1/2","blah4/1/8","blah5/1/2","blah6/1/2"]; 
        var sum = 0.0;
        var b = new Blaher();
        var o = {};
        var foo = 0;
        var t = haxe.Timer.stamp();
        for (i in 0...n){
            try{
                Golgi.run(routes[Std.random(routes.length)], o, b);
            } catch (e : Dynamic) {
                trace(e + " is the value for e");
            }

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
            try{
                haxe.web.Dispatch.run(routes[Std.random(routes.length)], new Map(), o);
            } catch(e:Dynamic){
                trace(e + " is the value for e");
            }
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
    function doBlah(){ count = count + Std.random(10); }
    function doBlah1(x:Int, y:Int){ count = count + Std.random(10); }
    function doBlah2(x:Int, y:Int){ count = count + Std.random(10); }
    function doBlah3(x:Int, y:Int){ count = count + Std.random(10); }
    function doBlah4(x:Int, y:Int){ count = count + Std.random(10); }
    function doBlah5(x:Int, y:Int){ count = count + Std.random(10); }
    function doBlah6(x:Int, y:Int){ count = count + Std.random(10); }
}



class Blaher extends Api {
    public var count = 0;
    public function blah(){ count = count + Std.random(10); }
    public function blah1(x:Int, y:Int){ count = count + Std.random(10); }
    public function blah2(x:Int, y:Int){ count = count + Std.random(10); }
    public function blah3(x:Int, y:Int){ count = count + Std.random(10); }
    public function blah4(x:Int, y:Int){ count = count + Std.random(10); }
    public function blah5(x:Int, y:Int){ count = count + Std.random(10); }
    public function blah6(x:Int, y:Int){ count = count + Std.random(10); }
}

