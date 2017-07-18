class Dispatch {
    var parts : Array<String>;
    var params : Dynamic<Dynamic>; 
    public function new(parts : Array<String>, params : Dynamic){
        this.parts = parts;
        this.params = params;
    }
    public function dispatch(api : Api){
        api.dispatch(this.parts, this.params);
    };
    public static function run(path : String, params : Dynamic, api : Api ){
		var parts = path.split("/");
		if( parts[0] == "" ) parts.shift();
        var d = new Dispatch(parts, params);
        api.dispatch(d.parts, d.params);
    }

}
