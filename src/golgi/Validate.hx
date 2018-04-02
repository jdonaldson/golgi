package golgi;
import golgi.Error;


/**
  String conversion and validation utilities
 **/
class Validate {
    public static function string(str:String, optional=false, arg_name : String, missingf : String->Error) : String {
        if (str == null){
            if (!optional) throw missingf(arg_name);
            else return null;
        } else {
            return str;
        }
    }
    public static function int(str:String, optional=false, arg_name : String, missingf : String->Error, invalidf : String->Error) : Int {
        if (str == null || str == ''){
            if (!optional) throw missingf(arg_name);
            return 0;
        } else {
            var res = Std.parseInt(str);
            if (res == null) throw invalidf(arg_name);
            return res;
        }
    }
    public static function float(str:String, optional=false, arg_name :String, missingf : String->Error, invalidf : String->Error) : Float {
        if (str == null || str == ''){
            if (!optional) throw missingf(arg_name);
            else return 0.0;
        } else {
            var res = Std.parseFloat(str);
            if (Math.isNaN(res)) throw invalidf(arg_name);
            return res;
        }
    }
    public static function bool(str:String, optional=false, arg_name : String, missingf : String->Error) : Bool {
        if (str == null || str == ''){
            if (!optional) throw missingf(arg_name);
            return false;
        } else {
            return str != "0" && str != "false";
        }
    }
    public static function missingParam(name : String) : Error {
        return MissingParam(name);
    }
    public static function missing(name : String) : Error {
        return Missing(name);
    }
    public static function invalid(name : String) : Error {
        return InvalidValue(name);
    }
    public static function invalidParam(name : String) : Error {
        return InvalidValueParam(name);
    }
}


