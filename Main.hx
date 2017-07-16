class Main {
    static function main() {
        trace("hello world");
        var r = new Router(); 
        r.dispatch("foob//3.3", {a:4});
    }
}


class Router implements Dispatch {
    public function foob(?x:Int, k:Float, args : {a : Int}){
        trace(x + " is the value for x in foob");
        trace(k + " is the value for k");
        trace(args.a + " is the value for args.a");
    }
    public function foo(){
        trace("foo was called!");
    }
    public function bar(){
        trace("bar was called");
    }
}
