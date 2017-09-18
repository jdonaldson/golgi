package golgi;

import haxe.macro.Context;
import haxe.macro.Expr;
import golgi.Validate;
using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;

typedef CheckFn = {
    subroute : Bool,
    params : Bool,
    fn : Function
}

#if macro
class Builder {

    static function validateArg(arg_expr : Expr, arg_name : String, arg_type : ComplexType, optional : Bool, validate_name : Bool, pos : haxe.macro.Position, leftovers : ComplexType->Expr){
        var leftover = false;
        var res =  switch(arg_type){
            case TPath({name : "Int"})     : macro golgi.Validate.int   (${arg_expr} , $v{optional}, $v{arg_name});
            case TPath({name : "String"})  : macro golgi.Validate.string(${arg_expr} , $v{optional}, $v{arg_name});
            case TPath({name : "Float"})   : macro golgi.Validate.float (${arg_expr} , $v{optional}, $v{arg_name});
            case TPath({name : "Bool"})    : macro golgi.Validate.bool  (${arg_expr} , $v{optional}, $v{arg_name});
            default : {
                leftover = true;
                leftovers(arg_type);  
            }
        }
        if (validate_name && !leftover && ["context","params"].indexOf(arg_name) != -1){
            Context.error('Reserved path argument name for $arg_name', pos );
        }
        return res;
    }
    static function processArg(arg : FunctionArg, idx : Int, check: CheckFn){
        var path_idx = idx;
        if (!check.subroute) path_idx++;
        var dispatch_slice = check.fn.args.length;
        if (check.params) dispatch_slice--;
        var path = macro parts[$v{path_idx++}];
        var pos = check.fn.expr.pos;
        return validateArg(path, arg.name, arg.type, arg.opt, true, pos, function(c){
            return switch(arg){
                case {name : "golgi"}: {
                    macro new Golgi(parts.slice($v{dispatch_slice -1}), params, context);
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
                                var v = validateArg(pf, name, t, false, false, pos, function(c) {
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
        var subroute = false;
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
                case {type : TPath({name : "Golgi", pack : ["golgi"]})}: {
                    subroute = true;
                }
                case _ : continue;
            }
        }
        return {fn : fn, subroute : subroute, params : params};
    }


    static function ensureOrder(m:Map<String,Int>, names : Array<String>, expr : Expr){
        for (i in 0...names.length){
            var name = names[i];
            for (j in (i+1)...names.length){
                var other = names[j];
                if (m.exists(name) && m.exists(other)){
                    if (m.get(name) > m.get(other)){
                        Context.error('$name must come before $other in the argument order', expr.pos);
                    }
                }
            }
        }
    }

    static function processFn(f : Field, fn : Function ){
        var path_arg = 0;
        var path_idx = 0;
        var status = checkFn(fn);
        var exprs = [];
        var m = new Map<String, Int>();
        for (i in 0...fn.args.length){
            var arg = fn.args[i];
            if (arg.name == "golgi"){
                if (!Context.unify(Context.getType("golgi.Golgi"), arg.type.toType())){
                    Context.error("golgi argument must be of Golgi type", fn.expr.pos);
                }
            }
            m.set(arg.name, i);
            var arg_expr = processArg(arg, i, status);
            exprs.push(arg_expr);
        }
        ensureOrder(m, ["params", "context", "golgi"], fn.expr);
        if (m.exists("golgi")){
            if (!m.exists("context")){
                Context.error("Subrouting in golgi requires a passed context argument", fn.expr.pos);
            }
        }
        return {route:f, ffun : fn, subroute : status.subroute, params : status.params, exprs : exprs};
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


        var handler_macro = macro {
            var path = "";
            if (parts.length == 0) {
                parts = [];
            } else {
                path = parts[0];
            }
            trace(dict + " is the value for dict");
            trace(path + " is the value for path");
            if (dict.exists(path)){
                return dict.get(path)(parts,params,context);
            } else {
                throw golgi.Error.NotFound(parts[0]);
            }
        };

        var map_field = {
            name: "dict",
            doc: null,
            meta: [],
            access: [],
            kind: FVar(macro:Map<String, Array<String>->Dynamic->Dynamic->$tret> ),
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
        var default_field = null;
        for (route in routes){
            var handler_name = route.route.name;
            var field_name = handler_name;
            for (r in route.route.meta){
                trace(r.name + " is the value for r.name");
                if (r.name == "default"){
                    if (default_field != null){
                        Context.error("Only one default field per Api", Context.currentPos());
                    }
                    default_field = r.name; 
                    handler_name = "";
                }
            }
            d.push( macro {
                d.set($v{handler_name},
                        cast function(parts:Array<String>, params:Dynamic, context : Dynamic){
                            return this.$field_name($a{route.exprs});
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
