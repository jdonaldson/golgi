package golgi.builder;
import haxe.macro.Expr;
typedef Route = {
    route      : Field,
    ffun       : Function,
    subroute   : Bool,
    params     : Bool,
    exprs      : Array<Expr>,
    middleware : Array<ExprDef>,
}
