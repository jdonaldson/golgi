import haxe.macro.Context;
import haxe.macro.Expr;

@:autoBuild(Builder.build())
interface Dispatch {
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
        var path =  [for (r in routes) '($r\\b)'].join("|");
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

        var handler_steps = [];
        for (i in 0...routes.length){
            var handler_name = routes[i];
            handler_steps.push(
                    macro {
                        if (this.reg.matched($v{i} + 1)!= null){
                            this.$handler_name();
                            return;
                        }
                    }
            );
        }

        var handler_macro = macro {
            var matched = this.reg.match(path);
            if (!matched){
                throw "not matched";
            } else {
                $a{handler_steps};
            }
        };

        var routes_field = {
            name: "routes",
            doc: null,
            meta: [],
            access: [],
            kind: FVar(macro:Array<String>),
            pos: Context.currentPos()
        }
        var ereg_field = {
            name: "reg",
            doc: null,
            meta: [],
            access: [],
            kind: FVar(macro:EReg),
            pos: Context.currentPos()
        }
                
                


        var dispatch_func = {
            name: "dispatch",
            doc: null,
            meta: [],
            access: [APublic],
            kind: FFun({args : [{name:"path", type: TPath({name : "String", pack:[]})}], ret : null , expr : handler_macro}),
            pos: Context.currentPos()
        };

        fields.push(init_field);
        fields.push(dispatch_func);
        fields.push(routes_field);
        fields.push(ereg_field);

        return fields;
    }
}
