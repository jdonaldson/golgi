class Dispatch {
    var parts : Array<String>;
    var params : Dynamic<Dynamic>; 
    public function new(parts : Array<String>, params : Dynamic){
        this.parts = parts;
        this.params = params;
    }
    inline public function dispatch(api : Api){
        api.__dispatch__(this.parts, this.params);
    };
    public static function run(path : String, params : Dynamic, api : Api ){
        var parts = path.split("/");
        if( parts[0] == "" ) parts.shift();
        var d = new Dispatch(parts, params);
        api.__dispatch__(d.parts, d.params);
    }

}
