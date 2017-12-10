package golgi;

@:allow(golgi.Subroute, golgi.Golgi)
@:autoBuild(golgi.builder.Builder.build())
class Api<TReq,TRet> {
    function __golgi__(parts : Array<String>, params: Dynamic, request : TReq)  : TRet {
        return null;
    }
}
