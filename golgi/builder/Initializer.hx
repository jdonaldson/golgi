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
    static function mw_gen(field_name : String, route : Route) : Expr {
        return macro function(parts : Array<String>, params : Dynamic, request : Dynamic) {
            return ${mw_gen_recur(route.middleware, field_name, route)};
        }
    }

    /*
       Recursive helper for middleware call
     */
    static function mw_gen_recur(mw : Array<ExprDef>, field_name : String, route : Route) : Expr{
        if (mw.length == 0){
            return macro this.$field_name($a{route.exprs});
        } else {
            var mwc = mw.copy();
            var m = mwc.shift();
            var mm = {expr:m, pos: Context.currentPos()};
            return macro $mm(request , function(x) return ${mw_gen_recur(mwc, field_name, route)});
        }
    }

    public static function build(routes:Array<Route>){
        var d = [];
        var observed_paths = new Map<String,Bool>();
        for (route in routes){
            var field_name=  route.route.name;
            var paths = [field_name];
            var path_altered = false;

            for (m in route.route.meta){
                switch(m.name){
                    case ":default" : {
                        paths = [""];
                        alteration_check(path_altered,route.route.pos);
                        path_altered = true;
                    };
                    case ":alias" : {
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
                        alteration_check(path_altered, route.route.pos);
                        path_altered = true;
                    }
                    case ":route" : {
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
                        alteration_check(path_altered, route.route.pos);
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
                    var func = mw_gen(field_name, route);
                    d.push( macro  __golgi_dict__.set($v{path_name}, $func));
                } else {
                    var func = macro function(parts:Array<String>, params:Dynamic, request : Dynamic){
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

