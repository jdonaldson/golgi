package golgi.builder;
class Lazy<T> {
    public var next : Void -> T;
    public var hasNext : Void -> Bool;

    public function new(iter : Iterator<T>){
        next = iter.next;
        hasNext = iter.hasNext;
    }

    public function map<TMap>( f : T->TMap ) : Lazy<TMap> {
        return new Lazy({
            hasNext: this.hasNext,
            next : function() { return f(this.next()); }
        });
    }

    public function filter( f : T->Bool ) : Lazy<T> {
        var buffer : T = null;
        if (this.hasNext()){
            var hasNextf = function(){
                do buffer = this.next()
                    while (!f(buffer) && this.hasNext());
                return this.hasNext();
            };
            var nextf = function() {
                return buffer;
            }
            return new Lazy({
                hasNext : hasNextf,
                next : nextf
            });

        } else {
            return new Lazy(this);
        }
    }

    public function fold<TSeed>(f : T->TSeed->TSeed, seed : TSeed) {
        var result = seed;
        for (v in this){
            result = f(v,result);
        }
        return result;
    }

    public function each(f : T->Void) : Void
        for (v in this) f(v);

    public static function lazy_iterator<T>(itb : Iterable<T>) : Lazy<T>
        return new Lazy(itb.iterator());

    public static function lazy<T>(itr : Iterator<T>) : Lazy<T>
        return new Lazy(itr);

}
