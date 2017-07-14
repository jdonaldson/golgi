class Main {
    static function main() {
        trace("hello world");
        var r = new Router(); 
        r.dispatch("foob/1");
    }
}

class Router implements Dispatch {
    public function foob(?x:Int){
        trace(x + " is the value for x in foob");

    }
    public function foo(){
        trace("foo was called!");
    }
    public function bar(){
        trace("bar was called");
    }
}
