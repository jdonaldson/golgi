class Main {
    static function main() {
        trace("hello world");
        var r = new Router(); 
        r.dispatch("foob//3.3", {a:'4',b:'1.0'});
    }
}


class Router implements Dispatch {
    public function foob(?x:Int, k:Float, args : {a : Int, ?b:Float}){
        trace(x + " is the value for x in foob");
        trace(k + " is the value for k");
        trace(args.a + " is the value for args.a");
        trace(args.b + " is the value for args.b");
    }
    public function foo(){
        trace("foo was called!");
    }
    public function bar(){
        trace("bar was called");
    }
}
