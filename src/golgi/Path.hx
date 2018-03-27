package golgi;
/**
  A simple abstract that is useful as a "path" argument.  It's compatible with
  strings (splitting the path on '/' characters), or arrays of strings (you can
  use a pre-defined tokenization for the path.
 **/
abstract Path(Array<String>){
    public var length (get, never) : Int;
    function get_length() : Int {
        return this.length;
    }
    function new(parts : Array<String>){
        this = parts;
    }
    @:arrayAccess
    public inline function get(key:Int) {
        return this[key];
    }

    @:from public static function fromString(str:String){
        if (str.charAt(0)== "/"){
            return new Path(str.substring(1).split("/"));
        } else {
            return new Path(str.split("/"));
        }

    }
    @:from public static function fromStringArr(arr : Array<String> ) {
        return new Path(arr);
    }
    @:to inline public function toArray() : Array<String> {
        return this;
    }
}

