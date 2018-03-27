package golgi;
import golgi.meta.MetaGolgi;

typedef TMap<TReq,TRet> = #if lua TableMap<TReq,TRet> #else Map<TReq,TRet> #end

/**
  The base subclass for a Golgi Api.  Classes inheriting this class will get a
  custom __golgi__ method constructed that contains routing information specific
  to the instance.
 **/
@:allow(golgi.Subroute)
@:autoBuild(golgi.Builder.golgi())
class Api<TReq> {
    var _treq : TReq;
    public function new(){ }
}

#if lua
/**
  Faster Map implementation for Lua.  Loses references to keys if the values
  are null.
 **/
class TableMap<K,V> {
    public var t : lua.Table<K,V>;
    public function new(){
        t = lua.Table.create();
    }
    inline public function get(k:K) : V {
        return t[cast k];
    }
    inline public function set(k:K, v:V) : Void {
        t[cast k] = v;
    }
    inline public function exists(k:K) : Bool {
        return t[cast k] != null;
    }
    inline  public function toString() : String {
        return Std.string(t);
    }
    inline public function keys() : Array<String> {
        return lua.PairTools.pairsFold(t, function(x,y,z : Array<String>) {z.push(Std.string(x)); return z;}, []);
    }
}
#end

