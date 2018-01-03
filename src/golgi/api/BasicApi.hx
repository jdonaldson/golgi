package golgi.api;
import golgi.meta.MetaGolgi;

/**
  A basic version of the Golgi Api.  It does not accept a MetaGolgi argument.
 **/
@:allow(golgi.Subroute, golgi.Golgi)
class BasicApi<TReq,TRet> extends Api<TReq,TRet,MetaGolgi<TReq,TRet>>{
    public function new(){
        super(new MetaGolgi<TReq,TRet>());
    }
}

