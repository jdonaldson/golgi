# hxdispatch
a quick sketch of an @:autoBuild-generated dispatch mechanism for url routing.

```haxe

class Main {
    static function main() {
        trace("hello world");
        var r = new Router(); 
        Dispatch.dispatch("foo", r);
        Dispatch.dispatch("bar", r);
        try {
        Dispatch.dispatch("blah", r);
        } catch (e:Dynamic){
            trace("not matched!");
        }
    }
}

class Router extends Dispatch {
    public function foo(){
        trace("foo was called!");
    }
    public function bar(){
        trace("bar was called");
    }
}
```
