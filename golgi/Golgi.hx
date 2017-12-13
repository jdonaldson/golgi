package golgi;
import golgi.meta.MetaGolgi;
class Golgi<TReq,TRet>{
    var api : Api<TReq, TRet>;
    public function new(api : Api<TReq,TRet>, ?meta : MetaGolgi<TReq, TRet>){
        if (meta == null) meta = new golgi.meta.MetaGolgi();
        this.api = api;
    }
    public function run(path : String, params : Dynamic, request : TReq) {
        var parts = path.split("/");
        if( parts[0] == "" ) parts.shift();
        api.__golgi__(parts, params, request);
     }

}

