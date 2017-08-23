
class Validate {
    public static function split(str:String, delim:String) : Array<String> {
        return str.split(delim);
    }
    public static function string(str:String, optional=false) : String {
        if (str == null){
            if (!optional) throw "Missing argument";
            else return null;
        } else {
            return StringTools.urlDecode(str);
        }
    }
    public static function int(str:String, optional=false) : Int {
        if (str == null || str == ''){
            if (!optional) throw "Missing argument";
            return 0;
        } else {
            var res = Std.parseInt(str);
            if (res == null) throw "Invalid argument type";
            return res;
        }
    }
    public static function float(str:String, optional=false) : Float {
        if (str == null || str == ''){
            if (!optional) throw "Missing argument";
            else return 0.0;
        } else {
            var res = Std.parseFloat(str);
            // if (res == null) throw "Invalid argument type";
            return res;
        }
    }
    public static function bool(str:String, optional=false) : Bool {
        if (str == null || str == ''){
            if (!optional) throw "Missing argument";
            return false;
        } else {
            return str != "0" && str != "false";
        }
    }
}
