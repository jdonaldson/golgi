package golgi;
import golgi.meta.MetaGolgi;

@:autoBuild(golgi.Build.golgi())
class Golgi<TReq, TApi:Api<TReq>, TRoute, TMeta:MetaGolgi<TReq, TRoute>> {
    var api : TApi;
    var meta : TMeta;
    var dict : Map<String, Array<String>->Dynamic->TReq->TRoute>;
    public function new(api : TApi, ?meta : TMeta){
        this.api = api;
        this.meta = meta != null ? meta : cast new MetaGolgi<TReq,TRoute>();
        this.dict = new Map();
    }
    public function route(parts : Array<String>, params : Dynamic, request : TReq): TRoute {
        return null;
    }
}
