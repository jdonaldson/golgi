class Main {
    static function main() {
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
        var spr = time/n;
        trace("[hxdispatch] " + b.count + " is the value for b.count");
        trace("[hxdispatch] " + time + " is the value for time");
        trace("[hxdispatch] " + rps + " is the value for rps");
        trace("[hxdispatch] " + spr + " is the value for spr");

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
        trace("[Dispatch] " + rps + " is the value for rps");
        trace("[Dispatch] " + spr + " is the value for spr");

    }
    static function main2(){
    }
}
class Old {
    public var count = 0;
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



class Blaher extends Api {
    public var count = 0;
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

