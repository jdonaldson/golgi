import golgi.BasicApi;
import golgi.Golgi;

class SpeedTest {
    static function main() {
        var n = 100000;
        trace(n + " is the value for n");
        var t = haxe.Timer.stamp();
        var routes = ["blah1/1","blah2/5","blah3/2","blah4/8","blah5/3","blah6/8"];
        var sum = 0.0;
        var b = new Blaher();
        var o = {};
        var foo = 0;
        var t = haxe.Timer.stamp();
        for (i in 0...n){
            try{
                Golgi.run(routes[Std.random(routes.length)], o, null, b);
            } catch (e : Dynamic) {
                trace(e + " is the value for e");
            }

        }
        var time = (haxe.Timer.stamp() - t);
        var rps = n/time;
        var spr = time/n;
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
    function doBlah(){ return 'hi'; }
    function doBlah1(x:Int){return 'hi'; }
    function doBlah2(x:Int){return 'hi'; }
    function doBlah3(x:Int){return 'hi'; }
    function doBlah4(x:Int){return 'hi'; }
    function doBlah5(x:Int){return 'hi'; }
    function doBlah6(x:Int){return 'hi'; }
}



class Blaher extends BasicApi<{}, String> {
    public var count : Int = 0;
    public function blah() : String{ return 'hi';}
    public function blah1(x:Int): String{ return 'hi'; }
    public function blah2(x:Int): String{ return 'hi'; }
    public function blah3(x:Int): String{ return 'hi'; }
    public function blah4(x:Int): String{ return 'hi'; }
    public function blah5(x:Int): String{ return 'hi'; }
    public function blah6(x:Int): String{ return 'hi'; }
}

