package golgi.meta;
/**
  Classes that extend this class follow the MetaGolgi pattern.  Their instance
  methods can be used as middleware within Golgi Apis.
 **/
@:autoBuild(golgi.builder.MetaBuilder.build())
class MetaGolgi<TReq, TRet> {
    public function new(){}
    /**
      This is the pass through interface, it will not generate a middleware call
      in the resulting route table.
    **/
    public function _golgi_pass(req: TReq, next : TReq->TRet) : TRet{
        return next(req);
    }
}

