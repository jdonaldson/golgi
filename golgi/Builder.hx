package golgi;

import haxe.macro.Context;
import haxe.macro.Expr;
import golgi.Validate;
using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;

typedef CheckFn = {
    subdispatch : Bool,
    params : Bool,
    fn : Function
}

#if macro
class Builder {

    static function validateArg(arg_expr : Expr, arg_type : ComplexType, optional : Bool, leftovers : ComplexType->Expr){
        return switch(arg_type){
            case TPath({name : "Int"})     : macro golgi.Validate.int   (${arg_expr} , $v{optional});
            case TPath({name : "String"})  : macro golgi.Validate.string(${arg_expr} , $v{optional});
            case TPath({name : "Float"})   : macro golgi.Validate.float (${arg_expr} , $v{optional});
            case TPath({name : "Bool"})    : macro golgi.Validate.bool  (${arg_expr} , $v{optional});
            default : leftovers(arg_type);  
        }
    }
    static function processArg(arg : FunctionArg, idx : Int, check: CheckFn){
        var path_idx = idx;
        if (!check.subdispatch) path_idx++;
        var dispatch_slice = check.fn.args.length;
        if (check.params) dispatch_slice--;
        var path = macro parts[$v{path_idx++}];
        var pos = check.fn.expr.pos;
        return validateArg(path, arg.type, arg.opt, function(c){
            return switch(arg){
                case {type : TPath({name : "Dispatch"})}: {
                    macro new Dispatch(parts.slice($v{dispatch_slice}), params);
                };
                case {name : "context"} : {
                    macro untyped $i{"context"};
                }
                case {name : "params", type : TAnonymous(fields)} : {
                    var arr = [];
                    for (f in fields){
                        switch(f.kind){
                            case FVar(t): {
                                var name = f.name;
                                var pf = macro params.$name; 
                                var v = validateArg(pf, t, false, function(c) {
                                    Context.error('Unhandled argument type on params.${f.name}. Only String, Float, Int, and Bool are supported', pos);
                                    return macro null;
                                });
                                arr.push({field : name , expr : v});
                            };
                            default : null;
                        }
                    }
                    {expr :EObjectDecl(arr), pos : pos};
                }
                case _ : Context.error('Unhandled argument type ${arg.type} on ${arg.name}.  Only String, Float, Int, and Bool are supported.', pos);
            }
        });
    }

    static function checkFn(fn:Function) : CheckFn{
        var subdispatch = false;
        var params = false;
        for (i in 0...fn.args.length){
            var arg = fn.args[i];
            var pos = fn.expr.pos;
            switch(arg){
                case {name : "params", type : TAnonymous(fields)} : {
                    params = true;
                };
                case {name : "params", type : TPath({name : name})} : {
                    Context.error("The params argument must be an anonymous object type declaration (and not a typedef... yet)", pos);
                }
                case {type : TPath({name : "Dispatch"})}: {
                    if (i != 0){
                        Context.error("The Dispatch typed argument must be unique and the first argument in the method signature", pos);
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

        var cls = Context.getLocalClass();
        var k = cls.get().superClass;
        while(k.t.get().module != "golgi.Api"){
             k = k.t.get().superClass; 
             if (k == null){
                 Context.error("Class must extend golgi.Api", cls.get().pos);
             }
        }
        var tctx = k.params[0].toComplexType();
        var tret = k.params[1].toComplexType();




        // capture function types
        for (f in fields){
            switch(f.kind){
                case FFun(fn)  : {
                    routes.push(processFn(f,fn));
                }
                default : continue;
            }
        }

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
        var handler_macro = macro {
            if (parts.length == 0) return null;
            if (dict.exists(parts[0])){
                return dict.get(parts[0])(parts,params,context);
            } else {
                throw golgi.Error.NotFound(parts[0]);
            }
        };

        var map_field = {
            name: "dict",
            doc: null,
            meta: [],
            access: [],
            kind: FVar(macro:Map<String, Array<String>->Dynamic->Dynamic->String> ),
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
                {name:"context", type: TPath({name : "Dynamic", pack:[]})}
            ], ret : tret, expr : handler_macro}),
            pos: Context.currentPos()
        };

        var d = [];
        d.push( macro var d = new Map());
        for (route in routes){
            var handler_name = route.route.name;
            d.push( macro {
                d.set($v{route.route.name},
                        function(parts:Array<String>, params:Dynamic, context : Dynamic){
                            return this.$handler_name($a{route.exprs});
                        });
            });
        };
        d.push(macro this.dict = d);

        var block = macro $b{d};

        var new_field = {
            name: "new",
            doc: null,
            meta: [],
            access: [APublic],
            kind: FFun({args : [], ret : null , expr : block}),
            pos: Context.currentPos()
        };

        fields.push(dispatch_func);
        fields.push(map_field);
        fields.push(new_field);

        return fields;
    }
}
#end
