package golgi;
import golgi.meta.MetaGolgi;

/**
  The base subclass for a Golgi Api.  Classes inheriting this class will get a
  custom __golgi__ method constructed that contains routing information specific
  to the instance.
 **/
@:allow(golgi.Subroute, golgi.Golgi)
@:autoBuild(golgi.builder.Builder.build())
class Api<TReq,TRet,TMeta:MetaGolgi<TReq,TRet>> {
    // defined metadata for this instance
    var __golgi_meta__ : TMeta;

    // path dictionary
    var __golgi_dict__ : Map<String, Array<String>->Dynamic->Dynamic->TRet>;

    /**
      An initializer that is replaced by the macro @:autoBuild function.
     **/
    function __golgi_init__() : Void {};

    public function new(meta : TMeta){
        __golgi_meta__ = meta;
        __golgi_dict__ = new Map();
        __golgi_init__();
    }

    /**
      The function that invokes the api.  It is replaced at compile time by the
      @:autoBuild macro.
     **/
    function __golgi__(parts : Array<String>, params: Dynamic, request : TReq)  : TRet {
        return null;
    }
}

