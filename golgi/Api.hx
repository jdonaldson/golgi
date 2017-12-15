package golgi;
import golgi.meta.MetaGolgi;

@:allow(golgi.Subroute, golgi.Golgi)
@:autoBuild(golgi.builder.Builder.build())
class Api<TReq,TRet,TMeta:MetaGolgi<TReq,TRet>> {
    var __meta__ : TMeta;
    var __dict__ : Map<String, Array<String>->Dynamic->Dynamic->TRet>;
    function __init_golgi__(){};
    public function new(meta : TMeta){
        __meta__ = meta;
        __init_golgi__();
    }
    function __golgi__(parts : Array<String>, params: Dynamic, request : TReq)  : TRet {
        return null;
    }
}

