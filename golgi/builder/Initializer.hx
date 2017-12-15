package golgi.builder;
import golgi.builder.Route;
import haxe.macro.Context;
import haxe.macro.Expr;
/**
  Steps for generating the golgi instance constructor
 **/
class Initializer {
    public static function build(routes:Array<Route>){
        var d = [];
        d.push( macro this.__dict__ = new Map());
        var default_field = null;
        for (route in routes){
            var handler_name = route.route.name;
            var field_name = handler_name;
            var pattern = null;

            if (route.middleware.length > 0){
                var next = macro function(request : Dynamic): Dynamic{
                    return this.$field_name($a{route.exprs});
                };
                for (i in 0...route.middleware.length){
                    var m = route.middleware[i];
                    var mm = {expr:m, pos: Context.currentPos()};
                    next = macro return $mm(request, $next);
                }
                var func = macro function(parts:Array<String>, params:Dynamic, request : Dynamic){
                    return $next;
                };
                d.push( macro { dict.set($v{handler_name}, $func); });
            } else {
                var func = macro function(parts:Array<String>, params:Dynamic, request : Dynamic){
                    return this.$field_name($a{route.exprs});
                };
                d.push( macro { __dict__.set($v{handler_name}, $func); });
            }
        };

        var block = macro $b{d};

        return {
            name   : "__init_golgi__",
            doc    : null,
            meta   : [],
            access : [AOverride],
            kind   : FFun({args : [], ret : null , expr : block}),
            pos    : Context.currentPos()
        };
    }
}
