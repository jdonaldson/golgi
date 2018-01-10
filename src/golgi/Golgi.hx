package golgi;
import golgi.meta.MetaGolgi;

/**
  The main class that is used to invoke each individual api's private routing
  method.
 **/
class Golgi{
    public static function run<TReq, TRet>(path : Path, params : Any, request : TReq, api : Api<TReq,TRet,Dynamic>)  : TRet {
#if cs
        try {
#end
        return api.__golgi__(path, params, request);

#if cs
        } catch (e : Dynamic) {
            if (Std.is(e, golgi.Error)){
                throw e;
            } else {
                var gbe = e.GetBaseException();
                if (Std.is(gbe, golgi.Error)){
                    throw gbe;
                } else {
                    throw e;
                }
            }
        }
#end
    }

}

