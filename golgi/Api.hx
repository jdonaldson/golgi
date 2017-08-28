package golgi;

@:allow(golgi.Golgi)
@:autoBuild(golgi.Builder.build())
class Api {
    function __dispatch__(parts : Array<String>, params: Dynamic<Dynamic>){}
}
