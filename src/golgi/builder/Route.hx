package golgi.builder;
import haxe.macro.Expr;
import haxe.macro.Type;
typedef Route = {
    name       : String,
    meta       : Metadata,
    pos        : Position,
    params     : Bool,
    subroute   : Bool,
    arg_exprs      : Array<Expr>,
    middleware : Array<ExprDef>,
}

