import golgi.Error;
class Main {
   static function main() {
      var ctors = TestApiRoute.getConstructors();
      trace(ctors + " is the value for ctors");

      var api = new TestApi();
      var glg = new TestApiGolgi(api);
      var req = {header : "dummy"};

      var foo = glg.route(["foo"],{},req);
      trace(foo + " is the value for foo");

      var bar = glg.route(["bar"],{},req);
      trace(bar + " is the value for bar");

      var arg = glg.route(["arg","1"], {}, req);
      trace(arg + " is the value for arg");

      try{
         var arg_missing = glg.route(["arg"], {}, req);
      } catch (e : Error){
         switch(e){
            case Missing(missing) : {
              trace(missing + " is the value for missing");
            }
            default : null;
         }
      }

      var param = glg.route(["param", "1"], {y : "2"}, req);
      trace(param + " is the value for param");

      var request = glg.route(["request"], {}, req);
      trace(request + " is the value for req");

      var sub = glg.route(["subroute","foo","1"], {}, req);
      trace(sub + " is the value for sub");


   }
}
