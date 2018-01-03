package golgi;
import golgi.meta.MetaGolgi;
import golgi.api.Api;

/**
  The main class that is used to invoke each individual api's private routing
  method.
 **/
class Golgi{
    public static function run<TReq, TRet>(path : Path, params : Any, request : TReq, api : Api<TReq,TRet,Dynamic>)  : TRet {
        return api.__golgi__(path, params, request);
    }
}

/**
  A simple abstract that is useful as a "path" argument.  It's compatible with
  strings (splitting the path on '/' characters), or arrays of strings (you can
  use a pre-defined tokenization for the path.
 **/
abstract Path(Array<String>){
    function new(parts : Array<String>){
        this = parts;
    }
    @:from public static function fromString(str:String){
        return new Path(str.split("/"));
    }
    @:from public static function fromStringArr(arr : Array<String> ) {
        return new Path(arr);
    }
    @:to inline public function toArray() : Array<String> {
        return this;
    }
}

