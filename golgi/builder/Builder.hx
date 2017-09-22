package golgi.builder;

import haxe.macro.Context;
import golgi.builder.Constructor.build;
import golgi.builder.Dispatcher.build;
import haxe.macro.Expr;
import golgi.Validate;
using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;

typedef CheckFn = {
    subroute : Bool,
    params : Bool,
    context : Bool,
    fn : Function
}


#if macro
class Builder {

    static function unify(t:haxe.macro.ComplexType, str:String){
        return Context.unify(t.toType(), Context.getType(str));
    }
    static function validateArg(arg_expr : Expr, arg_name : String, arg_type : ComplexType, optional : Bool, validate_name : Bool, reserved : Array<String>, leftovers : ComplexType->Expr){
        var leftover = false;
        arg_type = Context.followWithAbstracts(arg_type.toType()).toComplexType();
        if (reserved.indexOf(arg_name) != -1){
            return leftovers(arg_type);
        }
        var res = if (unify(arg_type,"Int")) {
            macro golgi.Validate.int(${arg_expr} , $v{optional}, $v{arg_name});
        } else if (unify(arg_type, "String")){
            macro golgi.Validate.string(${arg_expr} , $v{optional}, $v{arg_name});
        } else if (unify(arg_type, "Float")){
            macro golgi.Validate.float(${arg_expr} , $v{optional}, $v{arg_name});
        } else if (unify(arg_type, "Bool")){
            macro golgi.Validate.bool(${arg_expr} , $v{optional}, $v{arg_name});
        } else {
            leftovers(arg_type);
        }
        return res;
    }

    /**
      An error message creator for argument problems
     **/
    static function arg_error(arg : FunctionArg, ?param : String){
        var type = arg.type.toType().toString();
        var name = arg.name;
        var param_str = param != null ? 'on params.$param' : '';
        Context.error('Unhandled argument type "$type" $param_str for $name.  Only types unifying with String, Float, Int, and Bool are supported as path arguments.', Context.currentPos());
        return null;
    }

    /**
      Process the args, wrapping them in validators and constructors where appropriate.
     **/
    static function processArg(arg : FunctionArg, idx : Int, check: CheckFn){
        var path_idx = idx + 1;
        var dispatch_slice = check.fn.args.length;
        if (check.params) dispatch_slice--;
        if (check.context) dispatch_slice--;
        var path = macro parts[$v{path_idx++}];
        var pos = check.fn.expr.pos;
        var reserved = ["golgi", "params", "context"];
        return validateArg(path, arg.name, arg.type, arg.opt, true, reserved, function(c){
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
                                var v = validateArg(pf, name, t, false, false, [], function(c) {
                                    return arg_error(arg, f.name);
                                });
                                arr.push({field : name , expr : v});
                            };
                            default : arg_error(arg);
                        }
                    }
                    {expr :EObjectDecl(arr), pos : pos};
                }
                case {name : "params"} : {
                    Context.error("The 'params' argument must be an anonymous object declaration", Context.currentPos());
                }
                case _ : {
                    arg_error(arg);
                }
            }
        });
    }

    /**
      Check the function to ensure that it is valid for a route
     **/
    static function checkFn(fn:Function) : CheckFn {
        var subroute = false;
        var params = false;
        var context = false;
        for (i in 0...fn.args.length){
            var arg = fn.args[i];
            var pos = fn.expr.pos;
            switch(arg){
                case {name : "params", type : TAnonymous(fields)} : {
                    params = true;
                };
                case {type : TPath({name : "Golgi", pack : ["golgi"]})}: {
                    subroute = true;
                }
                case {name : "contex"}: {
                    context = true;
                }
                case _ : continue;
            }
        }
        return {fn : fn, subroute : subroute, params : params, context : context};
    }


    /**
      Make sure that the special named arguments happen in the right order
     **/
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


    /**
      Process the function, ensuring that special named arguments are the right type, and in the right order
     **/
    static function processFn(f : Field, fn : Function ) : RouteInfo {
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

        var mw_idx = -1;
        var mw = [];
        for (i in 0...f.meta.length){
            var m = f.meta[i];
            if (m.name == ":mw"){
                mw_idx = i;
            }
        }
        if (mw_idx != -1){
            var mwv = f.meta[mw_idx];
            var k = mwv.params[0].expr;
            mw.push(k);
        }
        return {
            route      : f,
            ffun       : fn,
            subroute   : status.subroute,
            params     : status.params,
            exprs      : exprs,
            middleware : mw
        };
    }

    static function findGolgiSuper(cls : Null<haxe.macro.Type.Ref<haxe.macro.Type.ClassType>>){
        var glg = cls.get().superClass;
        while(glg.t.get().module != "golgi.Api"){
             glg = glg.t.get().superClass;
             if (glg == null){
                 Context.error("Class must extend golgi.Api", cls.get().pos);
             }
        }
        return glg;
    }

    /**
      The main build method for golgi api types
     **/
    macro public static function build() : Array<Field>{
        var fields = Context.getBuildFields();
        var routes = [];

        var cls = Context.getLocalClass();
        var glg = findGolgiSuper(cls);
        var tctx = glg.params[0];
        var tret = glg.params[1];


        // capture function types
        for (f in fields){
            switch(f.kind){
                case FFun(fn)  : {
                    if (f.access.indexOf(APublic) == -1) continue;
                    else if (f.access.indexOf(AStatic) != -1) continue;
                    else if(fn.ret == null || !Context.unify(glg.params[1], fn.ret.toType())){
                        Context.error('Every route function in this class must be of the same type ${glg.params[1]}', fn.expr.pos);
                    }
                    routes.push(processFn(f,fn));
                }
                default : continue;
            }
        }


        var tret_complex = tret.toComplexType();

        var map_field = {
            name   : "dict",
            doc    : null,
            meta   : [],
            access : [],
            kind   : FVar(macro:Map<String, Array<String>->Dynamic->Dynamic->$tret_complex> ),
            pos    : Context.currentPos()
        }


        var dispatch_func = Dispatcher.build(tret_complex);
        fields.push(dispatch_func);
        fields.push(map_field);
        var new_field = Constructor.build(routes);
        fields.push(new_field);

        return fields;
    }
}
#end


typedef RouteInfo = {
    route      : Field,
    ffun       : Function,
    subroute   : Bool,
    params     : Bool,
    exprs      : Array<Expr>,
    middleware : Array<ExprDef>
}
