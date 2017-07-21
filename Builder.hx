import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.ComplexTypeTools;

typedef CheckFn = {
    subdispatch : Bool,
    params : Bool,
    fn : Function
}

class Builder {

    static function processArg(arg : FunctionArg, idx : Int, check: CheckFn){
        var path_idx = idx;
        if (!check.subdispatch) path_idx++;
        var dispatch_slice = check.fn.args.length;
        if (check.params) dispatch_slice--;
        return switch(arg){
            case {type : TPath({name : "Int"})}     : macro Validate.int(parts[$v{path_idx++}] , $v{arg.opt});
            case {type : TPath({name : "String"})}  : macro Validate.string(parts[$v{path_idx++}] , $v{arg.opt});
            case {type : TPath({name : "Float"})}   : macro Validate.float(parts[$v{path_idx++}]  , $v{arg.opt});
            case {type : TPath({name : "Bool"})}    : macro Validate.bool(parts[$v{path_idx++}]   , $v{arg.opt});
            case {type : TPath({name : "Dispatch"})}: {
                macro new Dispatch(parts.slice($v{dispatch_slice}), params);
            };
            case {name : "params", type : TAnonymous(fields)} : {
                macro params;
            }
            case _ : Context.error('Unhandled argument type on ${arg.name}', check.fn.expr.pos);
        }
    }

    static function checkFn(fn:Function) : CheckFn{
        var subdispatch = false;
        var params = false;
        for (i in 0...fn.args.length){
            var arg = fn.args[i];
            switch(arg){
                case {name : "params", type : TAnonymous(fields)} : {
                    if (i != fn.args.length-1){
                        Context.error("The params argument must be unique and the final argument in the method signature", arg.value.pos);
                    }
                    params = true;
                };
                case {name : "params"} : {
                    Context.error("The params argument must be an anonymous object type declaration (and not a type def)", arg.value.pos);
                }
                case {type : TPath({name : "Dispatch"})}: {
                    if (i != 0){
                        Context.error("The Dispatch typed argument must be unique and the first argument in the method signature", arg.value.pos);
                    }
                    subdispatch = true;
                }
                case _ : continue; 
            }
        }
        return {fn : fn, subdispatch : subdispatch, params : params};
    }


    static function processFn(f : Field, fn : Function ){
        var path_arg = 0; 
        var path_idx = 0;
        var status = checkFn(fn);
        var exprs = [];
        for (i in 0...fn.args.length){
            var arg = fn.args[i];  
            var arg_expr = processArg(arg, i, status);
            exprs.push(arg_expr);
        }
        return {route:f, ffun : fn, subdispatch : status.subdispatch, params : status.params, exprs : exprs};
    }

    macro public static function build() : Array<Field>{
        var fields = Context.getBuildFields();
        var routes = [];

        // capture function types
        for (f in fields){
            switch(f.kind){
                case FFun(fn)  : {
                    routes.push(processFn(f,fn));
                }
                default : continue; 
            }
        }

        // validate: optional dispatch argument must be first, 
        // optional params must be last, only one of each
        for (r in routes){
            var dispatch = false;
            var params = false;
            for (i in 0...r.ffun.args.length){
                var a = r.ffun.args[i];
                switch(a){
                    case {type : TPath({name : "Dispatch"})}:{

                    }
                    case _ : null;
                }
            }
        }



        // sort
        routes.sort(function(x,y) return x.route.name.length > y.route.name.length ? -1 : x.route.name.length < y.route.name.length ? 1 : 0);

        var path =  [for (r in routes) '(^${r.route.name}$)'].join("|");
        var pattern = macro $v{path};

        var handler_steps = [];


        for (i in 0...routes.length){
            var route = routes[i];
            var path_arg_count = route.ffun.args.length; 
            if (route.subdispatch) path_arg_count--;
            if (route.params) path_arg_count--;
            var handler_name = route.route.name;
            var macro_step = macro {
                if (this.reg.matched($v{i + 1})!= null){
                    if (!$v{route.subdispatch} && $v{path_arg_count} != parts_arg_count){
                        throw 'Path args do not match funciton args for ${route.route.name}: path_args:' + parts_arg_count + ' and function_args: ${$v{path_arg_count}}';
                    };
                    trace(parts);
                    this.$handler_name($a{route.exprs});
                    return;
                }
            }
            handler_steps.push(macro_step);
        }


        var handler_macro = macro {
            var matched = this.reg.match(parts[0]);
            var parts_arg_count = parts.length-1;
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
            name: "__dispatch__",
            doc: null,
            meta: [],
            access: [AOverride],
            kind: FFun({args : [
                {name:"parts", type: TPath({name : "Array", pack:[], params : [TPType(TPath({name : "String", pack : []}))] })},
                {name:"params", type: TPath({name : "Dynamic", pack:[]})},
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
