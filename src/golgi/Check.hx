package golgi;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;


class Check {

    static var path_meta = [":default", ":alias", ":route"];
    /**
      The main @:build method for golgi api types.  Only checks arguments.
     **/
    macro public static function api() : Array<Field> {
        var fields = Context.getBuildFields();
        var cls = Context.getLocalClass().get();


        var meta = cls.meta;


        checkForInvalidPathMetadata(meta,cls.pos);

        var treq = getRequestType(cls);

        for (f in fields){
            if (f.name == "new") continue;
            if (f.access.indexOf(APublic) == -1) [];
            else if (f.access.indexOf(AStatic) != -1) [];
            switch(f.kind){
                case FFun(fn)  : {
                    var mw = [for (f in f.meta) f.name];
                    var tfnret = fn.ret.toType();
                    checkArguments(fn, treq);
                }
                case FVar(t) : {
                    var mw = [for (f in f.meta) f.name];
                    var tfnret = t;
                }
                default : continue;
            }
        };
        return null; // haxe will use the original build fields.
    }

    static function checkForInvalidPathMetadata(meta: haxe.macro.Type.MetaAccess, pos : Position ){
        for (m in path_meta){
            if (meta.has(m)) {
                Context.error('$m is path level metadata applicable for routes only', pos);
            }
        }
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

    static function getApiType(arr : Array<Type>) : haxe.ds.Option<Type>{
        return null;

    }

    static function getRequestType(cls : ClassType) : Type {
        var treq : Type = null;
        var stack = [];
        var find_api = function(cls : ClassType){
            for(i in cls.interfaces) {
                var type = i.t.get();
                var arr = type.pack;
                arr.push(type.name);
                if (arr.join('.') == "golgi.Api"){
                    return i.params[0].applyTypeParameters(type.params, i.params);
                }
            };
            return null;
        }
        var api_type = find_api(cls);

        var stack = [];

        while(api_type == null && cls.superClass != null){
            stack.push(cls.superClass);
            cls = cls.superClass.t.get();
            api_type = find_api(cls);
        };
        if (api_type != null){
            var req_t = api_type;
            for (cls in stack){
                req_t = req_t.applyTypeParameters(cls.t.get().params, cls.params);
            }
            return req_t;
        }
        return null;
    }
}
