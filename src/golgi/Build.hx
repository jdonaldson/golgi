package golgi;
import haxe.macro.Type;
import haxe.macro.Expr;

#if macro
import golgi.builder.Route;
import haxe.macro.Expr.Position;

import golgi.Validate;
import golgi.builder.Initializer;
import haxe.macro.Context;
import golgi.builder.Initializer.titleCase;
using haxe.macro.ComplexTypeTools;
import haxe.macro.Expr.ComplexType;
using haxe.macro.TypeTools;
using Lambda;
#end




#if macro
class Build {
    static var reserved = ["params", "request", "subroute"];

    /**
      Shortcut for complex type unification
    **/
    static function unify(t:ComplexType, target : ComplexType){
        return Context.unify(t.toType(), target.toType());
    }

    /**
      Generates a expression that validates the arg expression.
    **/
    static function validateArg(arg : GolgiArg) : Expr {
        var leftover = false;
        arg.type = Context.followWithAbstracts(arg.type.toType()).toComplexType();
        if (reserved.indexOf(arg.name) != -1){
            return arg.leftovers(arg);
        }
        var missing = arg.param ? macro golgi.Validate.missingParam : macro golgi.Validate.missing;
        var invalid = arg.param ? macro golgi.Validate.invalidParam : macro golgi.Validate.invalid;

        var res = if (unify(arg.type, macro : Int)){
            macro golgi.Validate.int(${arg.expr} , $v{arg.optional}, $v{arg.name}, $missing, $invalid);
        } else if (unify(arg.type, macro : String)){
            macro golgi.Validate.string(${arg.expr} , $v{arg.optional}, $v{arg.name}, $missing);
        } else if (unify(arg.type, macro : Float)){
            macro golgi.Validate.float(${arg.expr} , $v{arg.optional}, $v{arg.name}, $missing, $invalid);
        } else if (unify(arg.type, macro : Bool)){
            macro golgi.Validate.bool(${arg.expr} , $v{arg.optional}, $v{arg.name}, $missing);
        } else {
            arg.leftovers(arg);
        }

        return res;
    }

    /**
      An error message creator for argument problems
     **/
    static function arg_error(arg : GolgiArg, ?param : String, ?pos : Position){
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
    static function processLeftoverParamArg(arg : GolgiArg) : Expr {
        return switch(arg.name){
            case "subroute": {
                macro new golgi.Subroute(parts.slice($v{arg.dispatch_slice -1}), params, request);
            };
            case "request" : macro request;
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
                                        param          : true,
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
      Process an arg, wrapping it in validator and constructor expr where
      appropriate.
     **/
    static function processArg(arg : TFunArg, pos : Position, args : Array<TFunArg>, idx : Int, check: ParamConfig){
        var path_idx = idx + 1;
        var dispatch_slice = args.length;
        if (check.params) dispatch_slice--;
        if (check.request) dispatch_slice--;
        if (check.subroute) dispatch_slice++;
        var path = macro parts[$v{path_idx++}];

        return validateArg({
            name           : arg.name,
            expr           : path,
            field_pos      : pos,
            type           : arg.t.toComplexType(),
            optional       : arg.opt,
            param          : false,
            reserved       : Build.reserved,
            dispatch_slice : dispatch_slice,
            leftovers      : processLeftoverParamArg
        });

    }

    /**
      Generate param configuration info for the current function.  This includes
      info on whether special subroute, params, requests, etc. are present
     **/
    static function paramConfig(args : Array<TFunArg>) : ParamConfig {
        var subroute = false;
        var params = false;
        var request = false;

        for (arg in args){
            switch(arg.name){
                case "params"   : params = true;
                case "subroute" : subroute = true;
                case "request"  : request = true;
                case _          : continue;
            }
        }

        return {subroute : subroute, params : params, request : request};
    }

    /**
      Generate a series of expresssions that instantiates the route's middleware
      handlers.
     **/
    public static function genFieldMiddleware(field_meta : Metadata, class_meta : Metadata) : Array<ExprDef>{
        var mw = [];
        var add_meta = function(m : MetadataEntry, mw : Array<ExprDef>){
            if (!~/^[a-zA-Z]\w*/.match(m.name)) return;
            else if (m.name == "_golgi_pass") return;
            else if (m.name == ":helper") return;
            var name = m.name;
            var expr = macro meta.$name;
            mw.push(expr.expr);
        }
        for (m in field_meta){
            add_meta(m, mw);
        }

        if (class_meta != null){
            for (m in class_meta){
                add_meta(m, mw);
            }
        }
        return mw;
    }


    /**
      Process the  function information, ensuring that special named arguments
      are the right type, and in the right order
     **/
    static function processClassField(f : ClassField , args : Array<TFunArg>, treq  : Type , class_meta : Metadata) : Route {
        var path_arg = 0;
        var path_idx = 0;
        var status = paramConfig(args);
        var arg_exprs = [];
        var map = new Map<String, Int>();
        var pos = f.pos;
        for (i in 0...args.length){
            var arg = args[i];
            var arg_expr = processArg(arg, pos, args, i, status);
            arg_exprs.push(arg_expr);
        }

        var mw = genFieldMiddleware(f.meta.get(), class_meta);

        var method = switch(f.kind){
            case FVar(_) : false;
            case FMethod(_) : true;
            default : Context.error('Only field variables and methods allowed', pos);
        }

        return {
            name       : f.name,
            meta       : f.meta.get(),
            pos        : pos,
            subroute   : status.subroute,
            params     : status.params,
            arg_exprs  : arg_exprs,
            method     : method,
            middleware : mw
        };
    }






    static function pos() {
        return Context.currentPos();
    }

    static function getType(arg : Expr) {
        var class_name = switch(arg){
            case {expr : EConst(CIdent(str) | CString(str))} : str;
            default : {
                Context.error("Argument should be a Class name", pos());
                null;
            }
        }
        return Context.getType(class_name);
    }

    static function getClass(arg : Expr) {
        var type = getType(arg);
        var cls = type.getClass();
        if (cls == null){
            Context.error('Class ${type.getName()} does not exist', pos());
        }
        return cls;
    }

    static function getEnum(arg : Expr) {
        var type = getType(arg);
        var enm = type.getEnum();
        if (enm == null){
            Context.error('Enum ${type.getName()} does not exist', pos());
        }
        return enm;

    };

    static function checkTopLevel(cls: {module : String, name : String}){
        var modules = cls.module.split(".");
        if (cls.name != modules[modules.length-1]){
            Context.error("Classes and enums built by Golgi must be top level in their module.  Please move this declaration to a new file.", pos());
        }
    }

    static function isTypeParameter(t : Type) {
        switch(Context.follow(t)){
            case TInst(_) : return true;
            default : return false;
        }
    }
    static function buildSupers(cls:ClassType) : Array<SuperParams>{
        var cursup = cls.superClass;
        var supers = [];
        while(cursup != null){
            supers.push({tp : cursup.t.get().params, cp : cursup.params});
            cursup = cursup.t.get().superClass;
        }
        return supers;
    }

    static function applyTypeParameters(cls:ClassType, type : Type, ?supers : Array<SuperParams>) :  Type {
        if (supers == null){
            supers = buildSupers(cls);
        }
        for (i in 0...supers.length){
            var p = supers[supers.length-i-1];
            type = type.applyTypeParameters(p.tp, p.cp);
        }
        return type;
    }

    static function golgi() : Array<Field> {

        var cls = Context.getLocalClass().get();
        checkTopLevel(cls);
        if (cls.params.length > 0){
            return null;
        }
        var api_param = cls.findField("api").type;
        var k = api_param.follow();

        var sup = cls.superClass;
        var supers = buildSupers(cls);

        var api_type = applyTypeParameters(cls, api_param, supers);

        var route_field = "route";
        var route_f = Context.follow(cls.findField(route_field).type);

        var cursup = sup;

        var route_type = switch(route_f)  {
            case TFun(_,ret) : {
                applyTypeParameters(cls, ret);
            }
            default : {
                Context.error("Illegal route function type", cls.pos);
            };
        }

        var meta_param = cls.findField("meta").type;
        var meta_type = applyTypeParameters(cls, meta_param, supers);


        var route_enum = switch(route_type){
            case TEnum(e,p) : e.get();
            case TInst(c,p) : {
                switch(c.get().kind){
                    case KTypeParameter(_) : {
                        return null; // a type parameter was passed.  Defer build.
                    }
                    default : Context.error("Invalid result type", pos());
                }
            }
            default : Context.error("Invalid result type", pos());
        }

        var api_class = applyTypeParameters(cls, api_type).getClass();
        var fields = api_class.fields.get();

        var api_type = Context.getType(api_class.name);

        var enum_ctype = Context.getType(route_enum.name).toComplexType();


        var routes = [];

        var param : Type;
        var sup = api_class.superClass;
        if (api_class.params.length > 0){
            param = api_class.params[0].t;
        } else {
            while (sup != null){
                if (sup.params.length > 0){
                    param = sup.params[0];
                    break;
                }
                sup = sup.t.get().superClass;
            }
            if (param == null){
                Context.error("No suitable request parameter found", pos());
            }
        }


        var treq = param;

        var api_meta = api_type.getClass().meta.get();


        for (f in fields){
            if (f.name == "new") continue;
            if (!f.isPublic) continue;
            switch(f.kind){
                case FMethod(MethNormal) : {
                    switch(Context.follow(f.type)) {
                        case TFun(args, t) : {
                            var route_fn = processClassField(f, args, treq, api_meta);
                            routes.push(route_fn);
                        }
                        default : Context.error("Illegal api field type", pos());
                    }
                }
                case FVar(t,p) : {
                    var route_fn= processClassField(f, [], treq, api_meta);
                    routes.push(route_fn);
                }
                default : continue;
            }
        }


        var new_field = Initializer.build(routes, route_enum.name);

        var init : Field = {
            name : "__init",
            access : [AOverride],
            kind : FFun({
                args : [],
                ret : null,
                expr : macro $b{new_field}
            }),
            pos : Context.currentPos()
        };

        var fields = Context.getBuildFields();
        return fields.concat([init]);
    }

    public static function results(api : Expr) : Array<Field> {

        var enm = Context.getLocalType().getEnum();

        checkTopLevel(enm);
        var type =Context.getLocalType();
        switch(type){
            case TEnum(_) : null;
            default : Context.error("Results builder requires an enum", pos());

        }


        var api_class = getClass(api);
        var api_name = {expr :EConst(CString(api_class.name)), pos : enm.pos};

        enm.meta.add("_golgi_api", [api_name], enm.pos);

        var fields = api_class.fields.get();
        var enum_fields = [];

        // capture routes
        for (f in fields){
            if (f.name == "new") continue;

            switch(f.kind){
                case FMethod(fn)  : {
                    var tfnret = f.type;
                    var wa = tfnret.toComplexType();
                    var ret = switch(wa){
                        case TFunction(_,ret) : ret;
                        default : {
                            Context.error('Method type should be function', Context.currentPos());
                            null;
                        }
                    }
                    if (!f.isPublic) continue;
                    enum_fields.push({
                        name : titleCase(f.name),
                        pos : api.pos,
                        kind : FFun({
                            args : [{
                                name : "result",
                                type : ret
                            }],
                            expr : null,
                            ret : null
                        })
                    });
                }
                case FVar(t,p) : {
                    var ret = f.type.toComplexType();
                    enum_fields.push({
                        name : titleCase(f.name),
                        pos : api.pos,
                        kind : FFun({
                            args : [{
                                name : "result",
                                type : ret
                            }],
                            expr : null,
                            ret : null
                        })

                    });

                }
                default : continue;
            }
        }

        return enum_fields.concat(Context.getBuildFields());
    }
}
#end

typedef ParamConfig = {
    subroute : Bool,
    params   : Bool,
    request  : Bool,
}

typedef GolgiArg = {
    name           : String,
    expr           : Expr,
    field_pos      : Position,
    type           : ComplexType,
    optional       : Bool,
    reserved       : Array<String>,
    param          : Bool,
    dispatch_slice : Int,
    leftovers      : GolgiArg->Expr
}

typedef TFunArg = {t : Type, opt : Bool, name : String};

typedef SuperParams = {tp : Array<TypeParameter>, cp : Array<Type>};
