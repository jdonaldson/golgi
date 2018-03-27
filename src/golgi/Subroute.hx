package golgi;

typedef GolgiRouter<TReq,TRet> = {
    function route( path : Path, params : Dynamic, req : TReq) : TRet;
}
/**
  A class for containing leftover path parts from a partial route request.
 **/
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
    inline public function run<TRet>(router : GolgiRouter<TReq,TRet>) : TRet {
        return router.route(parts, params, request);
    }
}

