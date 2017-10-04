package golgi;
class Golgi<TCtx>{
    var parts : Array<String>;
    var params : Dynamic<Dynamic>;
    var context : TCtx;
    public function new(parts : Array<String>, params : Dynamic, context : TCtx){
        this.parts = parts;
        this.params = params;
        this.context = context;
    }
    inline public function subroute<TRet>(api : Api<TCtx,TRet>) : TRet {
        return api.__golgi__(this.parts, this.params, this.context);
    }
    inline public function mapContext<TCtxa>(ctxf : TCtx->TCtxa) : Golgi<TCtxa> {
        return new Golgi(this.parts, this.params, ctxf(this.context));
    }
    public static function run<A,B>(path : String, params : Dynamic, context : A, api : Api<A,B> ) {
        var parts = path.split("/");
        if( parts[0] == "" ) parts.shift();
        api.__golgi__(parts, params, context);
     }

}

