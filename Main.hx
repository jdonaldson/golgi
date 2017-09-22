import golgi.Api;
import golgi.Builder;
import golgi.Golgi;

typedef Blah = {
    y: String,
    z:Int
}

class Main {
    static function main() {
        try{
        Golgi.run("food/1", {}, {}, new Foo());
        } catch (e:Dynamic){
            trace(e + " is the value for e");
        }
    }
}

class Foo extends Api<Req,String> {
    public function food(x  : Int, context : String, golgi : golgi.Golgi<Req>) : String {
        trace("HI");
        return 'o';
    }

}


typedef Req = {
    a:Int
}
typedef Res = {}

