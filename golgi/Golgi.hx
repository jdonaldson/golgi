package golgi;
import golgi.meta.MetaGolgi;
class Golgi{
    public static function run<TReq, TRet>(path : String, params : Dynamic, request : TReq, api : Api<TReq,TRet,Dynamic>)  : TRet{
        var parts = path.split("/");
        if( parts[0] == "" ) parts.shift();
        return api.__golgi__(parts, params, request);
     }

}

