package golgi;
import golgi.Error;


/**
  String conversion and validation utilities
 **/
class Validate {
    public static function string(str:String, optional=false, arg_name : String, param : Bool) : String {
        if (str == null){
            if (!optional) throw param ? MissingParam(arg_name) : Missing(arg_name);
            else return null;
        } else {
            return StringTools.urlDecode(str);
        }
    }
    public static function int(str:String, optional=false, arg_name : String, param : Bool) : Int {
        if (str == null || str == ''){
            if (!optional) throw param ? MissingParam(arg_name) : Missing(arg_name);
            return 0;
        } else {
            var res = Std.parseInt(str);
            if (res == null) throw InvalidValue(arg_name);
            return res;
        }
    }
    public static function float(str:String, optional=false, arg_name : String, param : Bool) : Float {
        if (str == null || str == ''){
            if (!optional) throw param ? MissingParam(arg_name) : Missing(arg_name);
            else return 0.0;
        } else {
            var res = Std.parseFloat(str);
            if (Math.isNaN(res)) throw InvalidValue(arg_name);
            return res;
        }
    }
    public static function bool(str:String, optional=false, arg_name : String, param : Bool) : Bool {
        if (str == null || str == ''){
            if (!optional) throw param ? MissingParam(arg_name) : Missing(arg_name);
            return false;
        } else {
            return str != "0" && str != "false";
        }
    }
}


