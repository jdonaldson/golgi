package golgi;
class Subroute<TReq> {
    var parts : Array<String>;
    var params : Dynamic<Dynamic>;
    var request : TReq;
    public function new(parts : Array<String>, params : Dynamic, request : TReq){
        this.parts = parts;
        this.params = params;
        this.request = request;
    }
    inline public function mapRequest<TReqA>(ctxf : TReq->TReqA) : Subroute<TReqA> {
        return new Subroute(this.parts, this.params, ctxf(this.request));
    }
    inline public function run<TRet>(api : Api<TReq,TRet>) : TRet {
        return api.__golgi__(this.parts, this.params, this.request);
    }
}
