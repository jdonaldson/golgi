import golgi.Api;
import golgi.Golgi;

class SpeedTest {
    static function main() {
        var n = 100000;
        var t = haxe.Timer.stamp();
        var paths = ["blah1/1","blah2/5","blah3/2","blah4/8","blah5/3","blah6/8"];
        var sum = 0.0;
        var b = new Blaher(null);
        var o = {};
        var foo = 0;
        var t = haxe.Timer.stamp();
        for (i in 0...n){
            try{
                Golgi.run(paths[Std.random(paths.length)].split('/'), o, null, b);
            } catch (e : Dynamic) {
                trace(e + " is the value for e");
            }

        }
        var time = (haxe.Timer.stamp() - t);
        var rps = n/time;
        var spr = time/n;
        var target =
#if js
            'js'
#elseif java
            'java'
#elseif cpp
            'cpp'
#elseif neko
            'neko'
#elseif lua
            'lua'
#elseif hl
            'hl'
#elseif python
            'py'
#elseif php
            'php'
#end
            ;

        trace(', $target, golgi, ' + rps);

        var t= haxe.Timer.stamp();
        var o = new Old();
        for (i in 0...n){
            try{
                haxe.web.Dispatch.run(paths[Std.random(paths.length)], new Map(), o);
            } catch(e:Dynamic){
                trace(e + " is the value for e");
            }
        }
        var time = haxe.Timer.stamp() - t;
        var rps = n/time;
        trace(', $target, dispatch, ' + rps);

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



class Blaher extends Api<{}, String, Dynamic> {
    public var count : Int = 0;
    public function blah() : String{ return 'hi';}
    public function blah1(x:Int): String{ return 'hi'; }
    public function blah2(x:Int): String{ return 'hi'; }
    public function blah3(x:Int): String{ return 'hi'; }
    public function blah4(x:Int): String{ return 'hi'; }
    public function blah5(x:Int): String{ return 'hi'; }
    public function blah6(x:Int): String{ return 'hi'; }
}

