import golgi.Api;
import golgi.Builder;
import golgi.Golgi;

typedef Blah = {
    y: String,
    z:Int
}

class Main {
    static function main3(){
        var o = new Old();
        try{
            haxe.web.Dispatch.run("blah/foo", ["foo"=>'hi'], o);
        }catch (e:Dynamic){
            trace(e);
        }
    }
    static function main() {
        try{
            Golgi.run("foo/1", {y:"hi", z:4}, {a:4}, new Foo());
        } catch(e:golgi.Error){
            switch(e){
                case InvalidValue : trace("yep");
                default : trace("nope");
            }
        } catch (e : Dynamic){
            trace('whaaaa');
        }
    }
}

class Foo extends Api<Req,String> {
    public function foo(x:Int, params : {y : String, z : Int}, context : Req, golgi : Golgi<Req>) : String {
        var res = golgi.subroute(new Bar());
        trace(res + " is the value for res");
        return "foo";
    }
}

abstract Boo(Int){
    public function new(i:Int){
        this = i;
    }
    public function toString(){
        return [this].toString();
    }
}

typedef Req = {
    a:Int
}
typedef Res = {}

class Bar extends Api<Req,Int>{
    @default
    public function bloo(?x:Int) : Int{
        trace(x + " is the value for x");
        return 0;
    }
}


class Old {
    public var count = 0;
    public function new(){}
    function doBlah(d:haxe.web.Dispatch){ 
        d.dispatch(new Bing());
        count = count + Std.random(10); }
    function doBlah1(x:Int, y:Int){ count = count + Std.random(10); }
    function doBlah2(x:Int, y:Int){ count = count + Std.random(10); }
    function doBlah3(x:Int, y:Int){ count = count + Std.random(10); }
    function doBlah4(x:Int, y:Int){ count = count + Std.random(10); }
    function doBlah5(x:Int, y:Int){ count = count + Std.random(10); }
    function doBlah6(x:Int, y:Int){ count = count + Std.random(10); }
}

class Bing {
    public var count = 0;
    public function new(){}
    public function doFoo(){
        trace("HI");
    }
}
