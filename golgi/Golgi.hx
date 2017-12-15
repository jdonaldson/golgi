package golgi;
import golgi.meta.MetaGolgi;
class Golgi{
    public static function run<TReq, TRet>(api : Api<TReq,TRet,Dynamic>, path : String, params : Dynamic, request : TReq)  : TRet{
        var parts = path.split("/");
        if( parts[0] == "" ) parts.shift();
        return api.__golgi__(parts, params, request);
     }

}

