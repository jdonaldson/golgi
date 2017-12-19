package golgi;
import golgi.meta.MetaGolgi;

@:allow(golgi.Subroute, golgi.Golgi)
@:autoBuild(golgi.builder.Builder.build())
class Api<TReq,TRet,TMeta:MetaGolgi<TReq,TRet>> {
    var __golgi_meta__ : TMeta;
    var __golgi_dict__ : Map<String, Array<String>->Dynamic->Dynamic->TRet>;
    function __golgi_init__() : Void {};
    public function new(meta : TMeta){
        __golgi_meta__ = meta;
        __golgi_dict__ = new Map();
        __golgi_init__();
    }
    function __golgi__(parts : Array<String>, params: Dynamic, request : TReq)  : TRet {
        return null;
    }
}

