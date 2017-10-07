package golgi;

@:allow(golgi.Golgi)
@:autoBuild(golgi.builder.Builder.build())
class Api<TCtx,TRet> {
    function __golgi__(parts : Array<String>, params: Dynamic, context : TCtx)  : TRet { 
        return null;
    } 
}
