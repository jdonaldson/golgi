package golgi.builder;
import haxe.macro.Expr;
typedef Route = {
    route      : Field,
    ffun       : Function,
    params     : Bool,
    subroute   : Bool,
    exprs      : Array<Expr>,
    middleware : Array<ExprDef>,
}
