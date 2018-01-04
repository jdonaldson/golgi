package golgi;
import golgi.meta.MetaGolgi;

/**
  The main class that is used to invoke each individual api's private routing
  method.
 **/
class Golgi{
    public static function run<TReq, TRet>(path : Path, params : Any, request : TReq, api : Api<TReq,TRet,Dynamic>)  : TRet {
        return api.__golgi__(path, params, request);
    }
}

