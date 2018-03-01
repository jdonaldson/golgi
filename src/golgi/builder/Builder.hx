package golgi.builder;
import haxe.macro.Type;

import golgi.Validate;
import golgi.builder.Initializer.build;
import haxe.macro.Context;
import haxe.macro.Expr.Position;
import haxe.macro.Expr;
using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;
using Lambda;

typedef ClassRef = Null<haxe.macro.Type.Ref<haxe.macro.Type.ClassType>>;
typedef SuperRef = {t : ClassRef, params :Array<haxe.macro.Type>};


#if macro
class Builder {
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
    static function processArg(arg : FunctionArg, field : Field, idx : Int, check: ParamConfig){
        var path_idx = idx + 1;
        var dispatch_slice = check.fn.args.length;
        if (check.params) dispatch_slice--;
        if (check.request) dispatch_slice--;
        if (check.subroute) dispatch_slice++;
        var path = macro parts[$v{path_idx++}];
        var pos = check.fn.expr.pos;

        return validateArg({
            name           : arg.name,
            expr           : path,
            field_pos      : field.pos,
            type           : arg.type,
            optional       : arg.opt,
            param          : false,
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
    static function ensureOrder(m:Map<String,Int>, names : Array<String>, pos : Position){
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

    /**
      Generate a series of expresssions that instantiates the route's middleware
      handlers.
     **/
    static function genFieldMiddleware(field_meta : Metadata, class_meta : Metadata) : Array<ExprDef>{
        var mw = [];
        var add_meta = function(m : MetadataEntry, mw : Array<ExprDef>){
            if (!~/^[a-zA-Z]\w*/.match(m.name)) return;
            else if (m.name == "_golgi_pass") return;
            else if (m.name == ":helper") return;
            var name = m.name;
            var expr = macro  untyped meta.$name;
            mw.push(expr.expr);
        }
        for (m in field_meta){
            add_meta(m, mw);
        }

        for (m in class_meta){
            add_meta(m, mw);
        }
        return mw;
    }


    /**
      Process the  FFun function, ensuring that special named arguments are the
      right type, and in the right order
     **/
    static function processFFun(f : Field, fn : Function, treq  : haxe.macro.Type , class_meta : Metadata) : Route {
        var path_arg = 0;
        var path_idx = 0;
        var status = paramConfig(fn);
        var exprs = [];
        var map = new Map<String, Int>();
        var pos : Int;
        for (i in 0...fn.args.length){
            var arg = fn.args[i];
            switch(arg.name){
                case "subroute" : {
                    if (!Context.unify(Context.getType("golgi.Subroute"), arg.type.toType())){
                        Context.error("subroute argument must be of golgi.Subroute type", fn.expr.pos);
                    }
                }
                case "request" : {
                    if (!Context.unify(arg.type.toType(), treq)){
                        Context.error('request argument must be of ${treq} type', fn.expr.pos);
                    }
                }
                case "params" : {
                    var t = Context.follow(arg.type.toType());
                    var anon = switch(t){
                        case TAnonymous(_)  : true;
                        default : false;
                    }
                    if (!anon){
                        Context.error('params argument must be of Anonymous type', fn.expr.pos);
                    }
                }
            }

            map.set(arg.name, i);
            var arg_expr = processArg(arg, f, i, status);
            exprs.push(arg_expr);
        }
        ensureOrder(map, ["params", "request", "subroute"], fn.expr.pos);

        var mw = genFieldMiddleware(f.meta, class_meta);

        return {
            route      : f,
            ffun       : fn,
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
    static function defineGolgi(golgi_name : String, pack : Array<String>, routes : Array<Route>, enum_name : String, enum_type : ComplexType, treq : Type){
        var type = Context.getLocalType().toComplexType();
        var new_field = Initializer.build(routes, enum_name);
        var meta_type = Context.getType("golgi.meta.MetaGolgi");
        var constructor : Field = {
            name : "new",
            access : [APublic],
            kind : FFun({
                args : [{
                    name : "api",
                    type : type
                },
                {
                    name : "meta",
                    type : meta_type.toComplexType()
                }
                ],
                ret : null,
                expr : macro $b{new_field}
            }),
            pos : Context.currentPos()
        };

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
            kind: FFun({args : [
                {name:"parts",   type: TPath({name : "Array", pack:[], params : [TPType(TPath({name : "String", pack : []}))] })},
                {name:"params",  type: TPath({name : "Dynamic", pack:[]})},
                {name:"request", type: TPath({name : "Dynamic", pack:[]})}
            ], ret : null, expr : handler_macro}),
            pos: Context.currentPos()
        };


        var map_type = macro : Map<String, Array<String>->Dynamic->Dynamic->$enum_type>;
        var dict_init = macro new Map<String, Array<String>->Dynamic->Dynamic->$enum_type>();

        var dict : Field = {
            name : "dict",
            access : [],
            kind : FVar(map_type, dict_init),
            pos : Context.currentPos()
        }

        var api_definition : TypeDefinition = {
            fields : [constructor,router, dict],
            isExtern : false,
            kind : TDClass(),
            name : golgi_name,
            pack : pack,
            pos : Context.currentPos()
        }

        Context.defineType(api_definition);
    }

    static function defineRouteEnum(name : String, fields : Array<Field>, pack : Array<String>){
        var definition : TypeDefinition = {
            fields : fields,
            isExtern : false,
            kind : TDEnum,
            name : name,
            pack : pack,
            pos : Context.currentPos()
        }


        Context.defineType(definition);
    }

    /**
      The main build method for golgi api types
     **/
    macro public static function build() : Array<Field> {
        var fields = Context.getBuildFields();
        var routes = [];

        var cls = Context.getLocalClass().get();

        var meta = cls.meta;

        checkForInvalidPathMetadata(meta,cls.pos);

        var glg = cls.superClass;
        var treq = glg.params[0];
        var tmet = glg.params[1];

        var enum_fields = [];


        // capture routes
        for (f in fields){
            if (f.name == "new") continue;
            switch(f.kind){
                case FFun(fn)  : {
                    var tfnret = fn.ret.toType();
                    if (f.access.indexOf(APublic) == -1) continue;
                    else if (f.access.indexOf(AStatic) != -1) continue;
                    var route_fn = processFFun(f, fn, treq, meta.get());
                    routes.push(route_fn);
                    enum_fields.push({
                        name : Initializer.titleCase(f.name),
                        pos : Context.currentPos(),
                        kind : FFun({
                            args : [{
                                name : "api",
                                type : tfnret.toComplexType()
                            }],
                            expr : null,
                            ret : null
                        })

                    });
                }
                default : continue;
            }
        }


        var enum_name = cls.name + "Route";

        defineRouteEnum(enum_name, enum_fields, cls.pack);
        var enum_type = Context.getType(enum_name).toComplexType();


        var metagolgi_name = cls.name + "MetaGolgi";
        var superClass : TypePath = {
            name : "MetaGolgi",
            pack : ["golgi", "meta"],
            params : [TPType(treq.toComplexType()), TPType(enum_type)]
        };
        var definition : TypeDefinition = {
            fields : [],
            isExtern : false,
            kind : TDClass(superClass),
            name : metagolgi_name,
            pack : cls.pack,
            pos : Context.currentPos()
        }
        Context.defineType(definition);

        var meta_type = Context.getType("golgi.meta.MetaGolgi").toComplexType();


        var golgi_name = cls.name + "Golgi";
        defineGolgi(golgi_name, cls.pack, routes, enum_name, enum_type, treq);




        var golgi : TypePath= {
            name : golgi_name,
            pack : cls.pack

        }
        var golgi_type = Context.getType(golgi_name).toComplexType();
        var builder : Field = {
            name : "golgi",
            access : [APublic, AStatic],
            kind : FFun({
                args : [{
                    name : "api",
                    type : Context.getLocalType().toComplexType()
                },{
                    name : "meta",
                    type : meta_type,
                    opt : true
                }],
                ret : golgi_type,
                expr : macro return new $golgi(api,meta)
            }),
            pos : Context.currentPos()
        }
        fields.push(builder);

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

