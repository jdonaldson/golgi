import haxe.macro.Expr;
import golgi.Subroute;
import DMeta;
class Main {
    static function main() {
        trace("hello world");
        var a  = new Api();
        var golgi = Api.golgi(a);
        try{
            var o = golgi.route(["bar"], {}, {});
            switch(o){
                case Foo(s) | Bar(s) : {
                    trace(s + " is the value for s");
                }
            }
        } catch(e:Dynamic){
            trace(e);
        }

    }
}


class Api extends golgi.Api<TReq,DMeta> {
    public function new() super(new DMeta());
    public function bar(subroute : Subroute<TReq>) : String {
        var bargolgi = Bar.golgi(new Bar());
        var k = subroute.run(bargolgi);
        switch(k){
            case Ding(ret) : {
                trace(ret);
            }
        }
        return 'ho';
    }
    public function foo() : String {
        return 'hi';
    }
}


typedef TReq = Dynamic;


class Bar extends golgi.Api<TReq,DMeta> {
    public function new() super(new DMeta());
    public function ding() : String {
        return 'hi';
    }
}


