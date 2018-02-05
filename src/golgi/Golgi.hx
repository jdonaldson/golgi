package golgi;
import golgi.meta.MetaGolgi;

/**
  The main class that is used to invoke each individual api's private routing
  method.
 **/
class Golgi{

    public static function run<TReq, TRet>(path : Path, params : Dynamic<String>, request : TReq, api : Api<TReq,TRet,Dynamic>)  : TRet {
#if cs
        return _runcs(path, params, request, api);
#else
        return api.__golgi__(path, params, request);

#end
    }

#if cs
    inline public static function _runcs<TReq, TRet>(path : Path, params : Dynamic<String>, request : TReq, api : Api<TReq,TRet,Dynamic>)  : TRet {
        try{
            return api.__golgi__(path, params, request);
        } catch (e : Dynamic) {
            if (Std.is(e, golgi.Error)){
                throw e;
            } else {
                var gbe = e.GetBaseException();
                if (Std.is(gbe.obj, golgi.Error)){
                    throw gbe;
                } else {
                    throw e;
                }
            }
            return null;
        }
    }
#end


}

