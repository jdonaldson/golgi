package golgi.builder;
import haxe.macro.Context;
import haxe.macro.Expr;

/**
  Steps for generating the golgi instance constructor
 **/
class Initializer {
    static function alteration_check(altered : Bool, pos : Position){
        if (altered){
            Context.error("Only one path-based metadata per route", pos);
        }
    }

    /*
       Generate a chained middleware call
     */
    static function mw_gen(field_name : String, route : Route, path_default : Bool) : Expr {
        return macro function(parts : Array<String>, params : Dynamic, request : Dynamic) {
            return ${mw_gen_recur(route.middleware, field_name, route, path_default)};
        }
    }

    static function route_arg_count(route : Route, path_default : Bool) : Int {
        return if (path_default){
            1;
        } else {
            var arg_count = route.exprs.length + 1;
            if (route.params) arg_count--;
            if (route.subroute) arg_count--;
            arg_count;
        }
    }
    /*
       Recursive helper for middleware call
     */
    static function mw_gen_recur(mw : Array<ExprDef>, field_name : String, route : Route, path_default : Bool) : Expr{
        if (mw.length == 0){
            var route_args = route_arg_count(route, path_default);
            return macro {
                if (parts.length > $v{route_args}){
                    throw golgi.Error.TooManyValues;
                }
                return this.$field_name($a{route.exprs});
            }
        } else {
            var mwc = mw.copy();
            var m = mwc.shift();
            var mm = {expr:m, pos: Context.currentPos()};
            return macro return $mm(request , function(x) ${mw_gen_recur(mwc, field_name, route, path_default)});
        }
    }

    public static function build(routes:Array<Route>){
        var d = [];
        var observed_paths = new Map<String,Bool>();
        for (route in routes){
            var field_name=  route.route.name;
            var paths = [field_name];
            var path_altered = false;

            var path_default = false;
            for (m in route.route.meta){
                switch(m.name){
                    case ":default" : {
                        alteration_check(path_altered,route.route.pos);
                        paths = [""];
                        path_altered = true;
                        path_default = true;
                    };
                    case ":alias" : {
                        alteration_check(path_altered, route.route.pos);
                        var alias_paths = [];
                        for (p in m.params){
                            switch(p.expr){
                                case EConst(CString(str)) :{
                                    alias_paths.push(str);
                                }
                                default : {
                                    Context.error("Alias paths must be anonymous strings", route.route.pos);
                                }

                            }
                        }
                        paths = paths.concat(alias_paths);
                        path_altered = true;
                    }
                    case ":route" : {
                        alteration_check(path_altered, route.route.pos);
                        var route_paths = [];
                        for (p in m.params){
                            switch(p.expr){
                                case EConst(CString(str)) :{
                                    route_paths.push(str);
                                }
                                default : {
                                    Context.error("Alias paths must be anonymous strings", route.route.pos);
                                }

                            }
                        }
                        paths = route_paths;
                        path_altered = true;

                    }
                }

            }

            for (path_name in paths){
                if (observed_paths.exists(path_name)){
                    Context.error('Path name $path_name already exists in Api', route.route.pos);
                } else {
                    observed_paths.set(path_name, true);
                }
                if (route.middleware.length > 0){
                    var func = mw_gen(field_name, route, path_default);
                    d.push( macro  __golgi_dict__.set($v{path_name}, $func));
                } else {
                    var route_args = route_arg_count(route, path_default);
                    var func = macro function(parts:Array<String>, params:Dynamic, request : Dynamic){
                        if (parts.length > $v{route_args}){
                            throw golgi.Error.TooManyValues;
                        }
                        return this.$field_name($a{route.exprs});
                    };
                    d.push( macro __golgi_dict__.set($v{path_name}, $func));
                }
            }

        };

        var block = macro $b{d};

        return {
            name   : "__golgi_init__",
            doc    : null,
            meta   : [],
            access : [AOverride],
            kind   : FFun({args : [], ret : null , expr : block}),
            pos    : Context.currentPos()
        };
    }
}

