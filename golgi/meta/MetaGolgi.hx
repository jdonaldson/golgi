package golgi.meta;
class MetaGolgi<TReq, TRet> {
    public function new(){}
    var __middleware__ : Array<TReq->(TReq->TRet)->TRet>;
    var __filter__ : Array<TReq->(TReq->TRet)->TRet>;
}

enum MetaMethod<TReq,TRet> {
    Middleware(fn: TReq->(TReq->TRet)->TRet);
    RouteAlias(fn: String->Array<String>);
    PathTransform(fn : String->String);
}

