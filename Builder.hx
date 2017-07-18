import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.ComplexTypeTools;

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
            var arg_length = route.ffun.args.length;
            var j = 0;
            var k = 0;
            while (j < arg_length){
                var arg = route.ffun.args[j];
                var validation = switch(arg){
                    case {type : TPath({name : "Int"})}      : macro Validate.int(parts[$v{k}+1]    , $v{arg.opt});
                    case {type : TPath({name : "String"})}   : macro Validate.string(parts[$v{k}+1] , $v{arg.opt});
                    case {type : TPath({name : "Float"})}    : macro Validate.float(parts[$v{k}+1]  , $v{arg.opt});
                    case {type : TPath({name : "Bool"})}     : macro Validate.bool(parts[$v{k}+1]   , $v{arg.opt});
                    case {type : TPath({name : "Dispatch"})} : {
                        k--;
                        macro new Dispatch(parts.slice($v{route.ffun.args.length}), args);
                    };
                    case {name : "args", type : TAnonymous(fields)} : {
                        if (j != route.ffun.args.length-1){
                            Context.error("The args argument must be the final argument accepted by the route", route.route.pos);
                        }
                        var vfields = [];
                        for (f in fields){
                            switch(f.kind){
                                case FVar(fv): {
                                    var optional = Lambda.exists(f.meta, function(m) return m.name == ":optional");
                                    var fname = f.name; 
                                    var expr = switch(fv){
                                        case TPath({name : "Int"})    : macro Validate.int(args.$fname, $v{optional});
                                        case TPath({name : "String"}) : macro Validate.string(args.$fname, $v{optional});
                                        case TPath({name : "Float"})  : macro Validate.float(args.$fname, $v{optional});
                                        case TPath({name : "Bool"})   : macro Validate.bool(args.$fname, $v{optional});
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
                        Context.error('Unhandled argument type' , route.route.pos);
                        null;
                    }
                }
                validation_args.push(validation);
                j++;
                k++;
            }
            var handler_name = route.route.name;
            var macro_step = macro {
                if (this.reg.matched($v{i} + 1)!= null){
                    // var parts = Validate.split(this.reg.matchedRight(),"/");
                    var vargs = {};
                    this.$handler_name($a{validation_args});
                    return;
                }
            }
            handler_steps.push(macro_step);
        }


        var handler_macro = macro {
            var matched = this.reg.match(parts[0]);
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
            access: [APublic,AOverride],
            kind: FFun({args : [
                {name:"parts", type: TPath({name : "Array", pack:[], params : [TPType(TPath({name : "String", pack : []}))] })},
                {name:"args", type: TPath({name : "Dynamic", pack:[]})},
                // {name:"extra_args", opt : true, type: TPath({name : "Dynamic", pack:[]})},
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
