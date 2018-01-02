package golgi.meta;
/**
  Classes that extend this class follow the MetaGolgi pattern.  Their instance
  methods can be used as middleware within Golgi Apis.
 **/
@:autoBuild(golgi.builder.MetaBuilder.build())
class MetaGolgi<TReq, TRet> {
    public function new(){}
}

