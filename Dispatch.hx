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
                case FFun(fn)  : {
                    routes.push({name : f.name , ffun : fn});
                }
                case _ : null; 
            }
        }
        routes.sort(function(x,y) return x.name.length > y.name.length ? -1 : x.name.length < y.name.length ? 1 : 0);
        var path =  [for (r in routes) '(${r.name}\\b)'].join("|");
        var pattern = macro $v{path};

        var init_field = {
            name: "new",
            doc: null,
            meta: [],
            access: [APublic],
            kind: FFun({args : [], ret : null , expr : macro {
                this.reg = new EReg($pattern, 'i');
            }}), 
            pos: Context.currentPos()
        };

        var handler_steps = [];
        for (i in 0...routes.length){
            var handler_name = routes[i].name;
            var route = routes[i];
            var validation_args = [];
            for (j in 0...route.ffun.args.length){
                var arg = route.ffun.args[j];
                var validation = switch(arg.type){
                    case TPath({name:"Int"})    : macro Validate.int(parts[$v{j}+1]    , $v{arg.opt});
                    case TPath({name:"String"}) : macro Validate.string(parts[$v{j}+1] , $v{arg.opt});
                    case TPath({name:"Float"})  : macro Validate.float(parts[$v{j}+1]  , $v{arg.opt});
                    case TPath({name:"Bool"})   : macro Validate.bool(parts[$v{j}+1]   , $v{arg.opt});
                    case _ : throw "Unhandled argument type";
                }
                validation_args.push(validation);
            }
            var macro_step = macro {
                if (this.reg.matched($v{i} + 1)!= null){
                    var parts = Validate.split(this.reg.matchedRight(),"/");
                    this.$handler_name($a{validation_args});
                    return;
                }
            }
            handler_steps.push(macro_step);
        }

        var handler_macro = macro {
            var matched = this.reg.match(path);
            if (!matched){
                throw "not matched";
            } else {
                $a{handler_steps};
            }
        };

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
        fields.push(ereg_field);

        return fields;
    }
}
