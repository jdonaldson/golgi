class Main {
    static function main() {
        trace("hello world");
        var r = new Router(); 
        r.dispatch("foob");
    }
}

class Router implements Dispatch {
    public function foob(){
        trace("foob was called");
    }
    public function foo(){
        trace("foo was called!");
    }
    public function bar(){
        trace("bar was called");
    }
}
