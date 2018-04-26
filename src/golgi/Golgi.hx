package golgi;
import golgi.MetaGolgi;

@:autoBuild(golgi.Build.golgi())
class Golgi<TReq, TApi:Api<TReq>, TResult, TMeta:MetaGolgi<TReq, TResult>> {
    var api : TApi;
    var meta : TMeta;
    var dict : Map<String, Array<String>->Dynamic->TReq->TResult>;

    function __init() : Void return null;

    public function new(api : TApi, ?meta : TMeta){
        this.api = api;
        this.meta = meta != null ? meta : cast new MetaGolgi<TReq,TResult>();
        this.dict = new Map();
        __init();
    }
    public function route(parts : Array<String>, params : Dynamic, request : TReq): TResult {
        var path = parts.length > 0 ? parts[0] : "";

        if (dict.exists(path)) {
            return dict.get(path)(parts, params, request);
        } else {
            throw Error.NotFound(parts[0]);
        }
    }
}
