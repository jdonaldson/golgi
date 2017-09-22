package golgi.builder;
import golgi.builder.Route;
import haxe.macro.Context;
import haxe.macro.Expr;
/**
  Steps for generating the golgi instance constructor
 **/
class Constructor {
    public static function build(routes:Array<Route>){
        var d = [];
        d.push( macro this.dict = new Map());
        var default_field = null;
        for (route in routes){
            var handler_name = route.route.name;
            var field_name = handler_name;
            var pattern = null;
            for (r in route.route.meta){
                if (r.name == "pattern"){
                    pattern = r.params[0];
                } else if (r.name == "default"){
                    if (default_field != null){
                        Context.error("Only one default field per Api", Context.currentPos());
                    }
                    default_field = r.name;
                    handler_name = "";
                } else {
                    pattern = macro $v{field_name};
                }
            }


            if (route.middleware.length > 0){
                var next = macro function(context : Dynamic): Dynamic{
                    return this.$field_name($a{route.exprs});
                };
                for (i in 0...route.middleware.length){
                    var m = route.middleware[i];
                    var mm = {expr:m, pos: Context.currentPos()};
                    next = macro return $mm(context, $next);
                }
                var func = macro function(parts:Array<String>, params:Dynamic, context : Dynamic){
                    return $next;
                };
                d.push( macro { dict.set($v{handler_name}, $func); });
            } else {
                var func = macro function(parts:Array<String>, params:Dynamic, context : Dynamic){
                    return this.$field_name($a{route.exprs});
                };
                d.push( macro { dict.set($v{handler_name}, $func); });
            }
        };

        var block = macro $b{d};

        return {
            name: "new",
            doc: null,
            meta: [],
            access: [APublic],
            kind: FFun({args : [], ret : null , expr : block}),
            pos: Context.currentPos()
        };
    }
}