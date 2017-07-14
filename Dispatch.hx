import haxe.macro.Context;
import haxe.macro.Expr;

@:autoBuild(Builder.build())
class Dispatch {
    public var routes : Array<String>;
    public var reg : EReg;
    public static function dispatch(route : String, d : Dispatch){
        var matched = d.reg.match(route);
        if (!matched){
            throw "not matched";
        } else {
            for (idx in 0...d.routes.length){
                var match = d.reg.matched(idx + 1);
                if (match != null){
                    Reflect.callMethod(d, Reflect.field(d, d.routes[idx]), []);
                }
            }
        }
    }
}

class Builder {
    macro public static function build() : Array<Field>{
        var fields = Context.getBuildFields();
        var routes = [];
        for (f in fields){
            switch(f.kind){
                case FFun(_)  : {
                    routes.push(f.name);
                }
                case _ : null; 
            }
        }
        routes.sort(function(x,y) return x.length > y.length ? -1 : x.length < y.length ? 1 : 0);
        var path =  [for (r in routes) '($r)'].join("|");
        var pattern = macro $v{path};
        var routes_expr = macro $v{routes};
        var init_field = {
            name: "new",
            doc: null,
            meta: [],
            access: [APublic],
            kind: FFun({args : [], ret : null , expr : macro {
                this.routes = $routes_expr; 
                this.reg = new EReg($pattern, 'i');
            }}),
            pos: Context.currentPos()
        };
        var dispatch_field = {

        }

        fields.push(init_field);

        return fields;
    }
}
