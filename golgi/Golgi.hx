package golgi;
class Golgi <A>{
    var parts : Array<String>;
    var params : Dynamic<Dynamic>;
    var context : Dynamic<Dynamic>;
    public function new(parts : Array<String>, params : Dynamic, context : Dynamic){
        this.parts = parts;
        this.params = params;
        this.context = context;
    }
    public static function run<A,B>(path : String, params : Dynamic, request : A, api : Api<A,B> ) {
        var parts = path.split("/");
        if( parts[0] == "" ) parts.shift();
        api.__dispatch__(parts, params, request);
     }

}

