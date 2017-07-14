
class Validate {
    public static function split(str:String, delim:String) : Array<String> {
        return str.split(delim);
    }
    public static function string(str:String, optional:Bool) : String {
        if (str == null){
            if (!optional) throw "Missing argument";
            else return null;
        } else {
            return StringTools.urlDecode(str);
        }
    }
    public static function int(str:String, optional:Bool) : Int {
        if (str == null){
            if (!optional) throw "Missing argument";
            else return null;
        } else {
            var res = Std.parseInt(str);
            if (res == null) throw "Invalid argument type";
            return res;
        }
    }
    public static function float(str:String, optional:Bool) : Float {
        if (str == null){
            if (!optional) throw "Missing argument";
            else return null;
        } else {
            var res = Std.parseFloat(str);
            if (res == null) throw "Invalid argument type";
            return res;
        }
    }
    public static function bool(str:String, optional:Bool) : Bool {
        if (str == null){
            if (!optional) throw "Missing argument";
            else return null;
        } else {
            var res = Std.parseInt(str);
            if (res == null) throw "Invalid argument type";
            return res > 0;
        }
    }
}
