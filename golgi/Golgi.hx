package golgi;
class Golgi<TReq>{
    var parts : Array<String>;
    var params : Dynamic<Dynamic>;
    var request : TReq;
    public function new(parts : Array<String>, params : Dynamic, request : TReq){
        this.parts = parts;
        this.params = params;
        this.request = request;
    }
    inline public function subroute<TRet>(api : Api<TReq,TRet>) : TRet {
        return api.__golgi__(this.parts, this.params, this.request);
    }
    inline public function mapRequest<TReqA>(ctxf : TReq->TReqA) : Golgi<TReqA> {
        return new Golgi(this.parts, this.params, ctxf(this.request));
    }
    public static function run<A,B>(path : String, params : Dynamic, request : A, api : Api<A,B> ) {
        var parts = path.split("/");
        if( parts[0] == "" ) parts.shift();
        api.__golgi__(parts, params, request);
     }

}

