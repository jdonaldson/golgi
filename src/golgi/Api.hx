package golgi;
import golgi.MetaGolgi;


/**
  The base subclass for a Golgi Api.
 **/
@:autoBuild(golgi.Check.api())
class Api<TReq> {
    public function new(){ }
}

