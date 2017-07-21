class Main {
    static function main() {
        // trace("hello world");
        var r = new Router(); 
        Dispatch.run("foob//3.3", {a:'4',b:'1.0'}, new Router());
        Dispatch.run("dood/1", {a:'4',b:'1.0'}, new Router());
    }
}


class Router extends Api {
    public function foob(?x:Int, k:Float, params : {a : Int, ?b:Float}){
        trace(x + " is the value for x in foob");
        trace(k + " is the value for k");
    }
    public function dood(d:Dispatch, x : Int){
        trace("dood was called!");
        d.dispatch(new Blaher());
    }
    public function bar(){
        trace("bar was called");
    }
}

class Blaher extends Api {
    public function blah(){
        trace("I blahhed!");
    }
}

