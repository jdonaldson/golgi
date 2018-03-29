package golgi;
import haxe.macro.Type;

import golgi.Validate;
import golgi.builder.Initializer.build;
import haxe.macro.Context;
import haxe.macro.Expr.Position;
import haxe.macro.Expr;
import golgi.builder.*;
import golgi.builder.Initializer.titleCase;
using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;
using Lambda;


#if macro
class Build {
    static var reserved = ["params", "request", "subroute"];
    static var path_meta = [":default", ":alias", ":route"];

    /**
      Shortcut for complex type unification
    **/
    static function unify(t:haxe.macro.ComplexType, target : haxe.macro.ComplexType){
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
    static function arg_error(arg : GolgiArg, ?param : String, ?pos : haxe.macro.Position){
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
      Process the args, wrapping them in validator and constructor expr where
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
      Make sure that the special named arguments happen in the right order
     **/
    static function ensureOrder(m:Map<String,Int>, names : Array<String>, pos : Position) : Void {
        for (i in 0...names.length){
            var name = names[i];
            for (j in (i+1)...names.length){
                var other = names[j];
                if (m.exists(name) && m.exists(other)){
                    if (m.get(name) > m.get(other)){
                        Context.error('$name must come before $other in the argument order', pos);
                    }
                }
            }
        }
    }

    static function checkArguments(fn : Function, treq : Type) : Void {
        var args = fn.args;
        var pos = fn.expr.pos;

        var map = new Map<String, Int>();
        for (i in 0...args.length){
            var arg = args[i];
            switch(arg.name){
                case "subroute" : {
                    if (!Context.unify(Context.getType("golgi.Subroute"), arg.type.toType())){
                        Context.error("subroute argument must be of golgi.Subroute type", pos);
                    }
                }
                case "request" : {
                    if (!Context.unify(arg.type.toType(), treq)){
                        Context.error('request argument must be of ${treq} type', pos);
                    }
                }
                case "params" : {
                    var t = Context.follow(arg.type.toType());
                    var anon = switch(t){
                        case TAnonymous(_)  : true;
                        default : false;
                    }
                    if (!anon){
                        Context.error('params argument must be of Anonymous type', pos);
                    }
                }
            }
            map.set(arg.name, i);
        }
        ensureOrder(map, ["params", "request", "subroute"], pos);
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
    static function processClassField(f : ClassField , args : Array<TFunArg>, treq  : haxe.macro.Type , class_meta : Metadata) : Route {
        var path_arg = 0;
        var path_idx = 0;
        var status = paramConfig(args);
        var exprs = [];
        var map = new Map<String, Int>();
        var pos = f.pos;
        for (i in 0...args.length){
            var arg = args[i];
            var arg_expr = processArg(arg, pos, args, i, status);
            exprs.push(arg_expr);
        }

        var mw = genFieldMiddleware(f.meta.get(), class_meta);

        return {
            name       : f.name,
            meta       : f.meta.get(),
            pos        : pos,
            subroute   : status.subroute,
            params     : status.params,
            exprs      : exprs,
            middleware : mw
        };
    }

    static function checkForInvalidPathMetadata(meta: haxe.macro.Type.MetaAccess, pos : Position ){
        for (m in path_meta){
            if (meta.has(m)) {
                Context.error('$m is path level metadata applicable for routes only', pos);
            }
        }
    }


    static function getRequestType(cls : ClassType) : Type {
        var treq : Type = null;
        if (cls.params.length > 0){
            treq = cls.params[0].t;
        }else {
            var glg = cls.superClass;
            while(glg.params.length <= 0){
                glg = glg.t.get().superClass;
            }
            treq = glg.params[0];
        }
        return treq;
    }

    /**
      The main build method for golgi api types
     **/
    macro public static function api() : Array<Field> {
        var fields = Context.getBuildFields();
        var cls = Context.getLocalClass().get();


        var meta = cls.meta;

        checkForInvalidPathMetadata(meta,cls.pos);

        var treq = getRequestType(cls);

        for (f in fields){
            if (f.name == "new") continue;
            switch(f.kind){
                case FFun(fn)  : {
                    var mw = [for (f in f.meta) f.name];
                    var tfnret = fn.ret.toType();
                    if (f.access.indexOf(APublic) == -1) [];
                    else if (f.access.indexOf(AStatic) != -1) [];
                    checkArguments(fn, treq);
                }
                default : continue;
            }
        };
        return fields;
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

    static function checkModule(cls: {module : String, name : String}){
        var modules = cls.module.split(".");
        if (cls.name != modules[modules.length-1]){
            Context.error("Classes and enums built by Golgi must be top level in their module.  Please move this declaration to a new file.", pos());
        }
    }

    static function golgi(?api : Expr, ?route : Expr, ?meta : Expr) : Array<Field> {

        var cls = Context.getLocalClass().get();
        checkModule(cls);

        var api_class = getClass(api);
        var fields = api_class.fields.get();

        var route_enum = getEnum(route);

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

        var meta_type : Type = if (!meta.expr.match(EConst(CIdent("null")))){
            var meta_class = getClass(meta);
            Context.getType(meta_class.name);
        } else {

            var meta : TypePath = {
                name : "MetaGolgi",
                pack : ["golgi", "meta"],
                params : [TPType(treq.toComplexType()), TPType(enum_ctype)]
            };
            TPath(meta).toType();
        }


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
            if (dict.exists(path)){
                return dict.get(path)(parts,params,request);
            } else {
                throw golgi.Error.NotFound(parts[0]);
            }
        };

        var router = {
            name   : "route",
            access : [APublic],
            kind: FFun({
                args : [
                    {name:"parts",   type: TPath({name : "Path", pack:["golgi"]})},
                    {name:"params",  type: TPath({name : "Dynamic", pack:[]})},
                    {name:"request", type: treq.toComplexType()}
                ],
                ret  : enum_ctype,
                expr : handler_macro
            }),
            pos: Context.currentPos()
        };


        var new_field = Initializer.build(routes, route_enum.name);

        var constructor : Field = {
            name : "new",
            access : [APublic],
            kind : FFun({
                args : [{
                    name : "api",
                    type : api_type.toComplexType(),
                },
                {
                    name : "meta",
                    type : meta_type.toComplexType(),
                    opt  : true
                }],
                ret : null,
                expr : macro $b{new_field}
            }),
            pos : Context.currentPos()
        };

        var map_type = macro : Map<String, Array<String>->Dynamic->Dynamic->$enum_ctype>;
        var dict_init = macro new Map<String, Array<String>->Dynamic->Dynamic->$enum_ctype>();

        var dict : Field = {
            name : "dict",
            access : [],
            kind : FVar(map_type, dict_init),
            pos : Context.currentPos()
        }

        var api : Field = {
            name : "api",
            access : [],
            kind : FVar(api_type.toComplexType(), null),
            pos : Context.currentPos()
        }

        var meta : Field = {
            name : "meta",
            access : [],
            kind : FVar(meta_type.toComplexType(), null),
            pos : Context.currentPos()
        }
        var fields = Context.getBuildFields();
        var ret_fields = fields.concat([constructor, router, dict, api, meta]);
        return ret_fields;
    }

    public static function routes(?api : Expr) : Array<Field> {

        var enm = Context.getLocalType().getEnum();
        checkModule(enm);
        var api_name = enm.name;

        var reg = ~/Route$/;

        var class_name = ~/Route$/.replace(api_name, "");
        var class_type = Context.getType(class_name);
        var class_inst = class_type.getClass();

        var fields = class_inst.fields.get();
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
                        pos : Context.currentPos(),
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

typedef Arg = {
    name : String,
    type : Type
}


typedef RouteFunction = {
    name : String,
    meta : Metadata,
    pos : Position,
    args : Array<FunctionArg>,
    mw : Array<String>
}

typedef TFunArg = {t : Type, opt : Bool, name : String};
