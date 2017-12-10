package golgi;
class Golgi<TReq>{
    public static function run<A,B>(path : String, params : Dynamic, request : A, api : Api<A,B> ) {
        var parts = path.split("/");
        if( parts[0] == "" ) parts.shift();
        api.__golgi__(parts, params, request);
     }

}

