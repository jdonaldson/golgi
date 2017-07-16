import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.ComplexTypeTools;

@:autoBuild(Builder.build())
interface Dispatch {
}


class Builder {
    macro public static function build() : Array<Field>{
        var fields = Context.getBuildFields();
        var routes = [];
        for (f in fields){
            switch(f.kind){
                case FFun(fn)  : routes.push({route:f, ffun : fn});
                default : continue; 
            }
        }
        routes.sort(function(x,y) return x.route.name.length > y.route.name.length ? -1 : x.route.name.length < y.route.name.length ? 1 : 0);

        var path =  [for (r in routes) '(${r.route.name}\\b)'].join("|");
        var pattern = macro $v{path};


        var handler_steps = [];
        for (i in 0...routes.length){
            var route = routes[i];
            var validation_args = [];
            var validation_arg_var = [];
            for (j in 0...route.ffun.args.length){
                var arg = route.ffun.args[j];
                var validation = switch(arg){
                    case {type : TPath({name : "Int"})}    : macro Validate.int(parts[$v{j}+1]    , $v{arg.opt});
                    case {type : TPath({name : "String"})} : macro Validate.string(parts[$v{j}+1] , $v{arg.opt});
                    case {type : TPath({name : "Float"})}  : macro Validate.float(parts[$v{j}+1]  , $v{arg.opt});
                    case {type : TPath({name : "Bool"})}   : macro Validate.bool(parts[$v{j}+1]   , $v{arg.opt});
                    case {name : "args", type : TAnonymous(fields)} : {
                        if (j != route.ffun.args.length-1){
                            Context.error("The args argument must be the final argument accepted by the route", route.route.pos);
                        }
                        var vfields = [];
                        for (f in fields){
                            switch(f.kind){
                                case FVar(fv): {
                                    var fname = f.name; 
                                    var expr = switch(fv){
                                        case TPath({name : "Int"})    : macro Validate.int(args.$fname, $v{arg.opt});
                                        case TPath({name : "String"}) : macro Validate.string(args.$fname, $v{arg.opt});
                                        case TPath({name : "Float"})  : macro Validate.float(args.$fname, $v{arg.opt});
                                        case TPath({name : "Bool"})   : macro Validate.bool(args.$fname, $v{arg.opt});
                                        default : Context.error("Unhandled argument type", route.route.pos); 
                                    };
                                    vfields.push({field:fname, expr : expr});
                                }
                                default : {
                                    Context.error("Unhandled argument type", route.route.pos);
                                    null;
                                }
                            }
                        }

                        {expr : EObjectDecl(vfields), pos : route.route.pos};
                    }
                    case _ : {
                        var k = arg.type.toType();
                        trace(k + " is the value for k");
                        Context.error('Unhandled argument type' , route.route.pos);
                        null;
                    }
                }
                validation_args.push(validation);
            }
            var handler_name = route.route.name;
            var macro_step = macro {
                if (this.reg.matched($v{i} + 1)!= null){
                    var parts = Validate.split(this.reg.matchedRight(),"/");
                    var vargs = {};
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
            kind: FFun({args : [
                {name:"path", type: TPath({name : "String", pack:[]})},
                {name:"args", opt : true, type: TPath({name : "Dynamic", pack:[]})},
                {name:"extra_args", opt : true, type: TPath({name : "Dynamic", pack:[]})},
            ], ret : null , expr : handler_macro}),
            pos: Context.currentPos()
        };

        var new_field = {
            name: "new",
            doc: null,
            meta: [],
            access: [APublic],
            kind: FFun({args : [], ret : null , expr : macro {
                this.reg = new EReg($pattern, 'i');
            }}), 
            pos: Context.currentPos()
        };

        fields.push(dispatch_func);
        fields.push(ereg_field);
        fields.push(new_field);

        return fields;
    }
}
