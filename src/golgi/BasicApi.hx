package golgi;
import golgi.meta.MetaGolgi;
class BasicApi<TReq,TRet> extends Api<TReq, TRet, MetaGolgi<TReq,TRet>> {
    public function new(){
        super(new MetaGolgi());
    }
}
