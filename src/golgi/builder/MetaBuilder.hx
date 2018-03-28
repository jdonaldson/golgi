package golgi.builder;

import haxe.macro.Expr;
import haxe.macro.Context;
import golgi.Build;
using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;

class MetaBuilder {
    static function error_msg(req_type : haxe.macro.Type, ret_type : haxe.macro.Type, pos : Position) {
        var req = req_type.toString();
        var ret = ret_type.toString();
        Context.error(
                'Every meta function in this class must be of type'
                + '$req->($req->$ret)->$ret',
                pos
                );

    }
    macro public static function build() : Array<Field> {
        var cls = Context.getLocalClass();

        var glg = cls.get().superClass;
        var treq = glg.params[0];
        var tret = glg.params[1];
        var fields = Context.getBuildFields();

        for (f in fields){
            if (f.access.indexOf(AStatic) != -1) continue;
            if (f.access.indexOf(APublic) == -1) continue;
            if (f.name == "new") continue;
            var pos = f.pos;
            switch(f.kind){
                case FFun(fn)  : {
                    var arg1= fn.args[0];
                    var arg2 = fn.args[1];
                    var tfnret = fn.ret.toType();
                    if (fn.args.length != 2) {
                        error_msg(treq, tret, pos);
                    }
                    if (f.access.indexOf(APublic) == -1) continue;
                    else if (f.access.indexOf(AStatic) != -1) continue;
                    else if(fn.ret == null || !Context.unify(tret, tfnret)){
                        error_msg(treq,tret,pos);
                    } else {
                        switch(arg2.type){
                            case TFunction( args, ret) : {
                                if (args.length != 1){
                                    error_msg(treq, tret,pos);
                                }
                                var at = args[0].toType();
                                var rt = ret.toType();

                                if (!Context.unify(at, treq) || !Context.unify(rt, tret)){
                                    error_msg(treq, tret,pos);
                                }
                            }
                            default : {
                                error_msg(treq, tret,pos);
                            }
                        }

                    }
                }
                default : {
                    error_msg(treq,tret,pos);
                }
            }
        }


        return fields;
    }
}
