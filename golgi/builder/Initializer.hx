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
    public static function build(routes:Array<Route>){
        var d = [];
        d.push( macro this.__dict__ = new Map());
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
                    var next = macro function(request : Dynamic): Dynamic{
                        return this.$field_name($a{route.exprs});
                    };
                    for (i in 0...route.middleware.length){
                        var m = route.middleware[i];
                        var mm = {expr:m, pos: Context.currentPos()};
                        next = macro return $mm(request, $next);
                    }
                    var func = macro function(parts:Array<String>, params:Dynamic, request : Dynamic){
                        return $next;
                    };
                    d.push( macro { __dict__.set($v{path_name}, $func); });
                } else {
                    var func = macro function(parts:Array<String>, params:Dynamic, request : Dynamic){
                        return this.$field_name($a{route.exprs});
                    };
                    d.push( macro { __dict__.set($v{path_name}, $func); });
                }
            }

        };

        var block = macro $b{d};

        return {
            name   : "__init_golgi__",
            doc    : null,
            meta   : [],
            access : [AOverride],
            kind   : FFun({args : [], ret : null , expr : block}),
            pos    : Context.currentPos()
        };
    }
}

