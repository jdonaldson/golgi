package golgi.builder;
import haxe.macro.Expr;
import haxe.macro.Context;
class Dispatcher {
    public static function build(tret_complex : haxe.macro.ComplexType)  {
        var tret_complex = null;

        var handler_macro = macro {
            var path = "";
            if (parts.length == 0) {
                parts = [];
            } else {
                path = parts[0];
            }
            if (__dict__.exists(path)){
                return __dict__.get(path)(parts,params,request);
            } else {
                throw golgi.Error.NotFound(parts[0]);
            }
        };

        var dispatch_func = {
            name   : "__golgi__",
            doc    : null,
            meta   : [],
            access : [AOverride],
            kind: FFun({args : [
                {name:"parts",   type: TPath({name : "Array", pack:[], params : [TPType(TPath({name : "String", pack : []}))] })},
                {name:"params",  type: TPath({name : "Dynamic", pack:[]})},
                {name:"request", type: TPath({name : "Dynamic", pack:[]})}
            ], ret : tret_complex, expr : handler_macro}),
            pos: Context.currentPos()
        };

        return dispatch_func;
    }
}
