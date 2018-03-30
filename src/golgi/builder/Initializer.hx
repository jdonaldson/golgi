package golgi.builder;
import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;

/**
  Steps for generating the golgi instance constructor
 **/
class Initializer {
    static function alteration_check(altered : Bool, pos : Position){
        if (altered){
            Context.error("Only one path-based metadata per route", pos);
        }
    }

    public static function titleCase(name : String) : String{
        return name.charAt(0).toUpperCase() + name.substr(1);
    }
    static function route_arg_count(route : Route, path_default : Bool) : Int {
        return if (route.subroute){
            -1;
        } else if (path_default){
            1;
        } else {
            var arg_count = route.exprs.length + 1;
            if (route.params) arg_count--;
            arg_count;
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

    static function invoke_field(field_name : String, route : Route, path_default : Bool) : Expr {
            var route_args = route_arg_count(route, path_default);
            var length_check = route.subroute ? null : macro {
                if (parts.length > $v{route_args}) throw golgi.Error.TooManyValues;
            }
            var title = titleCase(field_name);
            var enum_name = { expr : EConst(CIdent(title)), pos : route.pos};
            return macro {
                $length_check;
                return ${enum_name}(api.$field_name($a{route.exprs}));
            }
    }

    /*
       Recursive helper for middleware call
     */
    static function mw_gen_recur(mw : Array<ExprDef>, field_name : String, route : Route, path_default : Bool) : Expr{
        if (mw.length == 0){
            return invoke_field(field_name, route, path_default);
        } else {
            var mwc = mw.copy();
            var m = mwc.shift();
            var mm = {expr:m, pos: Context.currentPos()};
            return macro return $mm(request , function(x) ${mw_gen_recur(mwc, field_name, route, path_default)});
        }
    }

    public static function build(routes:Array<Route>, enum_name : String) : Array<Expr>{
        var block = [macro super(api,meta)];
        var observed_paths = new Map<String,Bool>();
        for (route in routes){
            var field_name=  route.name;
            var paths = [field_name];
            var path_altered = false;

            var path_default = false;
            for (m in route.meta){
                switch(m.name){
                    case ":default" : {
                        alteration_check(path_altered,route.pos);
                        paths = [""];
                        path_altered = true;
                        path_default = true;
                    };
                    case ":alias" : {
                        alteration_check(path_altered, route.pos);
                        var alias_paths = [];
                        for (p in m.params){
                            switch(p.expr){
                                case EConst(CString(str)) :{
                                    alias_paths.push(str);
                                }
                                default : {
                                    Context.error("Alias paths must be anonymous strings", route.pos);
                                }

                            }
                        }
                        paths = paths.concat(alias_paths);
                        path_altered = true;
                    }
                    case ":route" : {
                        alteration_check(path_altered, route.pos);
                        var route_paths = [];
                        for (p in m.params){
                            switch(p.expr){
                                case EConst(CString(str)) :{
                                    route_paths.push(str);
                                }
                                default : {
                                    Context.error("Alias paths must be anonymous strings", route.pos);
                                }

                            }
                        }
                        paths = route_paths;
                        path_altered = true;

                    }
                }

            }

            for (path_name in paths){
                var api_expr = {expr : EConst(CIdent(enum_name)), pos : Context.currentPos()};
                var enum_name = titleCase(field_name);
                var enum_expr = macro $api_expr.$enum_name;

                if (observed_paths.exists(path_name)){
                    Context.error('Path name $path_name already exists in Api', route.pos);
                } else {
                    observed_paths.set(path_name, true);
                }
                if (route.middleware.length > 0){
                    var func = mw_gen(field_name, route, path_default);
                    block.push( macro  dict.set($v{path_name}, $func));
                } else {
                    var route_args = route_arg_count(route, path_default);
                    var func = if (route.subroute){
                        macro function(parts:Array<String>, params:Dynamic, request : Dynamic){
                            return $enum_expr(api.$field_name($a{route.exprs}));
                        };
                    } else {
                        macro function(parts:Array<String>, params:Dynamic, request : Dynamic){
                            if (parts.length > $v{route_args}) throw golgi.Error.TooManyValues;
                            return $enum_expr(api.$field_name($a{route.exprs}));
                        };
                    }
                    block.push( macro dict.set($v{path_name}, $func));

                }
            }

        };

        return block;
    }
}

