package golgi.builder;

import golgi.Validate;
import golgi.builder.Initializer.build;
import haxe.macro.Context;
import haxe.macro.Expr.Position;
import haxe.macro.Expr;
using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;

typedef ClassRef = Null<haxe.macro.Type.Ref<haxe.macro.Type.ClassType>>;
typedef SuperRef = {t : ClassRef, params :Array<haxe.macro.Type>};


#if macro
class Builder {
    static var reserved = ["params", "request", "subroute"];

    /**
      Shortcut for complex type unification
    **/
    static function unify(t:haxe.macro.ComplexType, target : haxe.macro.ComplexType){
        return Context.unify(t.toType(), target.toType());

    }

    /**
      Validate the given arg
    **/
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

    /**
      Process leftover params that occur in base arguments
    **/
    static function processLeftoverParamArg(arg : Arg) : Expr {
        return switch(arg.name){
            case "subroute": {
                macro new golgi.Subroute(parts.slice($v{arg.dispatch_slice -1}), params, request);
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
                                        name           : name,
                                        expr           : pf,
                                        field_pos      : f.pos,
                                        type           : fct,
                                        optional       : false,
                                        reserved       : [],
                                        validate_name  : false,
                                        dispatch_slice : arg.dispatch_slice,
                                        leftovers      : function(c) {
                                            return arg_error(arg, f.name, f.pos);
                                        }
                                    });

                                    arr.push({field : name , expr : v});
                                };
                                default : arg_error(arg, f.pos);
                            }
                        }
                    }
                    default : arg_error(arg, arg.expr.pos);
                }
                {expr :EObjectDecl(arr), pos : arg.expr.pos};
            }
            case _ : {
                arg_error(arg, arg.field_pos);
            }
        }

    }

    /**
      Process the args, wrapping them in validator and constructor expr where
      appropriate.
     **/
    static function processArg(arg : FunctionArg, field : Field, idx : Int, check: ParamConfig){
        var path_idx = idx + 1;
        var dispatch_slice = check.fn.args.length;
        if (check.params) dispatch_slice--;
        if (check.request) dispatch_slice--;
        var path = macro parts[$v{path_idx++}];
        var pos = check.fn.expr.pos;

        return validateArg({
            name           : arg.name,
            expr           : path,
            field_pos      : field.pos,
            type           : arg.type,
            optional       : arg.opt,
            validate_name  : true,
            reserved       : Builder.reserved,
            dispatch_slice : dispatch_slice,
            leftovers      : processLeftoverParamArg
        });

    }

    /**
      Generate param configuration info for the current function.  This includes
      info on whether special subroute, params, requests, etc. are present
     **/
    static function paramConfig(fn:Function) : ParamConfig {
        var subroute = false;
        var params = false;
        var request = false;

        for (arg in fn.args){
            switch(arg.name){
                case "params"   : params = true;
                case "subroute" : subroute = true;
                case "request"  : request = true;
                case _          : continue;
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
    static function processFFun(f : Field, fn : Function, treq  : haxe.macro.Type ) : Route {
        var path_arg = 0;
        var path_idx = 0;
        var status = paramConfig(fn);
        var exprs = [];
        var map = new Map<String, Int>();
        var pos : Int;
        for (i in 0...fn.args.length){
            var arg = fn.args[i];
            if (arg.name == "subroute"){
                if (!Context.unify(Context.getType("golgi.Subroute"), arg.type.toType())){
                    Context.error("subroute argument must be of golgi.Subroute type", fn.expr.pos);
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
                        false;
                    }
                }
                if (!anon){
                    Context.error('params argument must be of Anonymous type', fn.expr.pos);
                }
            }

            map.set(arg.name, i);
            var arg_expr = processArg(arg, f, i, status);
            exprs.push(arg_expr);
        }
        ensureOrder(map, ["params", "request", "subroute"], fn.expr);

        var mw = [];
        for (m in f.meta){
            if (!~/\[a-zA-Z]\w*/.match(m.name)) continue;
            var name = m.name;
            var expr = macro __meta__.$name;
            mw.push(expr.expr);
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

    /**
      The main build method for golgi api types
     **/
    macro public static function build() : Array<Field>{
        var fields = Context.getBuildFields();
        var routes = [];

        var cls = Context.getLocalClass();


        var glg = cls.get().superClass;
        var treq = glg.params[0];
        var tret = glg.params[1];
        var tmet = glg.params[2];


        // capture routes
        for (f in fields){
            if (f.name == "new") continue;
            switch(f.kind){
                case FFun(fn)  : {
                    var tfnret = fn.ret.toType();
                    if (f.access.indexOf(APublic) == -1) continue;
                    else if (f.access.indexOf(AStatic) != -1) continue;
                    else if(fn.ret == null || !Context.unify(tret, tfnret)){
                        var ret = tret.toString();
                        var k = tret.toString();
                        Context.error('Every route function in this class must be of type $ret according to the golgi API.', fn.expr.pos);
                    }
                    var route_fn = processFFun(f, fn, treq);
                    routes.push(route_fn);
                }
                default : continue;
            }
        }


        var tret_complex = tret.toComplexType();


        var dispatch_func = Dispatcher.build(tret_complex);
        fields.push(dispatch_func);
        var new_field = Initializer.build(routes);
        fields.push(new_field);

        return fields;
    }
}
#end

typedef ParamConfig = {
    subroute : Bool,
    params   : Bool,
    request  : Bool,
    fn       : Function
}

typedef Arg = {
    name           : String,
    expr           : Expr,
    field_pos      : Position,
    type           : ComplexType,
    optional       : Bool,
    reserved       : Array<String>,
    validate_name  : Bool,
    dispatch_slice : Int,
    leftovers      : Arg->Expr
}

