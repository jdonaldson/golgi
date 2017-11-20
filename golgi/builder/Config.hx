package golgi.builder;
using haxe.macro.Context;
import haxe.macro.Expr;

/**
  Simple config merge routine
 **/
class Config {
    public static macro function merge<T>(arr : Array<ExprOf<T>>) : Expr {
        var fields = new Array<ObjectField>();
        var seen = new Map<String,Int>();
        var type = Context.followWithAbstracts(Context.typeof(a))
        for (a in arr){
            switch (type){
                case TAnonymous(b) :  {
                    var k = b.get();
                    for (f in k.fields){
                        if (!seen.exists(f.name)){
                            var name = f.name;
                            fields.push({
                                field : name,
                                expr : macro ${a}.$name
                            });
                            seen.set(name,1);
                        }
                    }
                }
                default : {
                    Context.error('unsupported: $type', a.pos);
                }
            }
        }
        return {expr : EObjectDecl(fields), pos : Context.currentPos()};
    }

}
