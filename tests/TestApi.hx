package;
import golgi.*;
class TestApi extends Api<Req> {

    // @:default
    public function defaultRoute() : String {
        return 'default';
    }
    public function error() : String {
        return 'yo';
    }

    public function vanilla() : String {
        return 'vanilla';
    }
    public function singlearg(x:Int) : String {
        return '$x';
    }
    public function multiarg(x:Int,y:Int) : String {
        return '$x$y';
    }
    public function interceptRoute(x : Int, y: String) : String {
        return '$x and $y were passed to me';
    }
    public function paramArgString(params : { msg : String} ) : String {
        return params.msg;
    }
    public function paramArgInt(params : { msg : Int} ) : String {
        return params.msg + '';
    }
    public function passToSub(arg : Int, arg2 : Int, params : { msg : Int }, subroute : Subroute<Req>) : String {
        var golgi = SubTest.golgi(new SubTest());
        // var golgi = SubTest.golgi(this);
        // switch( Subroute.run(subroute, golgi)){
        // };
        return null;
    }

    @intercept
    public function metagolgi() : String {
        return 'not intercepted';
    }

    // @bang @intercept
    public function bang() : String {
        return 'not intercepted';
    }
}
