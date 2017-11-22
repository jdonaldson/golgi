package golgi.builder;

import haxe.macro.Context;
import golgi.builder.Constructor.build;
import golgi.builder.Dispatcher.build;
import haxe.macro.Expr;
import golgi.Validate;
using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;

#if macro
class Builder {
    static var reserved = ["params", "request", "golgi"];

    static function unify(t:haxe.macro.ComplexType, target : haxe.macro.ComplexType){
        return Context.unify(t.toType(), target.toType());

    }

    static function validateArg(arg : Arg) : Expr {
        var leftover = false;
        arg.type = Context.followWithAbstracts(arg.type.toType()).toComplexType();
        if (reserved.indexOf(arg.name) != -1){
            return arg.leftovers(arg);
        }

        var res = if (unify(arg.type, macro : Int)) {
            macro golgi.Validate.int(${arg.expr} , $v{arg.optional}, $v{arg.name});
        } else if (unify(arg.type, macro : String)){
            macro golgi.Validate.string(${arg.expr} , $v{arg.optional}, $v{arg.name});
        } else if (unify(arg.type, macro : Float)){
            macro golgi.Validate.float(${arg.expr} , $v{arg.optional}, $v{arg.name});
        } else if (unify(arg.type, macro : Bool)){
            macro golgi.Validate.bool(${arg.expr} , $v{arg.optional}, $v{arg.name});
        } else {
            arg.leftovers(arg);
        }

        return res;
    }

    /**
      An error message creator for argument problems
     **/
    static function arg_error(arg : Arg, ?param : String, ?pos : haxe.macro.Position){
        var type = arg.type.toType().toString();
        if (pos == null) pos = Context.currentPos();
        var name = arg.name;
        var param_str = param != null ? 'on params.$param' : '';
        Context.error('Unhandled argument type "$type" $param_str for $name.  Only types unifying with String, Float, Int, and Bool are supported as path arguments.', pos);
        return null;
    }

    static function argLeftovers(arg : FunctionArg) {
    }
    /**
      Process the args, wrapping them in validators and constructors where appropriate.
     **/
    static function processArg(arg : FunctionArg, idx : Int, check: CheckFn){
        var path_idx = idx + 1;
        var dispatch_slice = check.fn.args.length;
        if (check.params) dispatch_slice--;
        if (check.request) dispatch_slice--;
        var path = macro parts[$v{path_idx++}];
        var pos = check.fn.expr.pos;
        return validateArg({
            name : arg.name,
            expr : path,
            type : arg.type,
            optional : arg.opt,
            validate_name : true,
            reserved : Builder.reserved,
            leftovers : function(arg : Arg){
                return switch(arg.name){
                    case "golgi": {
                        macro new Golgi(parts.slice($v{dispatch_slice -1}), params, request);
                    };
                    case "request" : macro untyped $i{"request"};
                    case "params" : {
                        var arr = [];
                        var t = Context.followWithAbstracts(arg.type.toType());
                        switch(t){
                            case TAnonymous(fields) : {
                                for (f in fields.get().fields){
                                    switch(f.kind){
                                        case FVar(ft,_): {
                                            var name = f.name;
                                            var fct = f.type.toComplexType();
                                            var pf = macro params.$name;
                                            var v = validateArg({
                                                name : name,
                                                expr : pf,
                                                type : fct,
                                                optional : false,
                                                reserved : [],
                                                validate_name : false,
                                                leftovers : function(c) {
                                                    return arg_error(arg, f.name, f.pos);
                                                }
                                            });
                                            arr.push({field : name , expr : v});
                                        };
                                        default : arg_error(arg, f.pos);
                                    }
                                }
                            }
                            default : arg_error(arg, pos);
                        }
                        {expr :EObjectDecl(arr), pos : pos};
                    }
                    case _ : {
                        arg_error(arg, pos);
                    }
                }
            }});
    }

    /**
      Check for special params that may be present in the function
     **/
    static function checkFn(fn:Function) : CheckFn {
        var subroute = false;
        var params = false;
        var request = false;
        for (i in 0...fn.args.length){
            var arg = fn.args[i];
            var pos = fn.expr.pos;
            switch(arg){
                case {name : "params"} : {
                    params = true;
                };
                case {name : "golgi"}: {
                    subroute = true;
                }
                case {name : "request"}: {
                    request = true;
                }
                case _ : continue;
            }
        }
        return {fn : fn, subroute : subroute, params : params, request : request};
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
    static function processFn(f : Field, fn : Function, treq  : haxe.macro.Type ) : RouteInfo {
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
            if (arg.name == "request"){
                if (!Context.unify(arg.type.toType(), treq)){
                    Context.error('request argument must be of ${treq} type', fn.expr.pos);
                }
            }
            if (arg.name == "params"){
                var t = Context.follow(arg.type.toType());
                var anon = switch(t){
                    case TAnonymous(_)  : true;
                    default : {
                        trace("waaat");
                        false;
                    }
                }
                if (!anon){
                    Context.error('params argument must be of Anonymous type', fn.expr.pos);
                }
            }

            m.set(arg.name, i);
            var arg_expr = processArg(arg, i, status);
            exprs.push(arg_expr);
        }
        ensureOrder(m, ["params", "request", "golgi"], fn.expr);

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
        var treq = glg.params[0];
        var tret = glg.params[1];

        // capture routes
        for (f in fields){
            switch(f.kind){
                case FFun(fn)  : {
                    var tfnret = fn.ret.toType();
                    if (f.access.indexOf(APublic) == -1) continue;
                    else if (f.access.indexOf(AStatic) != -1) continue;
                    else if(fn.ret == null || !Context.unify(tret, tfnret)){
                        Context.error('Every route function in this class must be of type ${tret}', fn.expr.pos);
                    }
                    var route_fn = processFn(f,fn, treq);
                    routes.push(route_fn);
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


typedef CheckFn = {
    subroute : Bool,
    params   : Bool,
    request  : Bool,
    fn       : Function
}

typedef Arg = {
    name          : String,
    expr          : Expr,
    type          : ComplexType,
    optional      : Bool,
    reserved      : Array<String>,
    validate_name : Bool,
    leftovers : Arg->haxe.macro.Expr
}
