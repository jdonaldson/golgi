package foo;
import golgi.*;
import golgi.meta.*;
import SubTestGolgi;

class TestApi implements Api<Req> {
   public var someVar : Int = 4;
   public function new () {}

   @:default
   public function defaultRoute() : String {
         return 'default';
      }
   public function error() : String {
      return 'yo';
   }

   public function vanilla() : String {
      return 'vanilla';
   }
   public function singlearg(x:Int) : String {
      return '$x';
   } public function multiarg(x:Int,y:Int) : String {
      return '$x$y';
   }
   public function interceptRoute(x : Int, y: String) : String {
      return '$x and $y were passed to me';
   }
   public function paramArgString(params : { msg : String} ) : String {
      return params.msg;
   }
   public function paramArgInt(params : { msg : Int} ) : String {
      return params.msg + '';
   }
   public function passToSub(arg : Int, arg2 : Int, params : { msg : Int }, subroute : Subroute<Req>) : String {
      var sub = new SubTest(arg);
      var golgi = new SubTestGolgi(sub);
      var res = subroute.route(golgi);
      switch(res){
         case Sub(msg)        : return '' + arg + arg2 + msg;
         case SubAlias(msg)   : return msg;
         case SubDefault(msg) : return 'default';
         default : return '';
      }
   }

   @intercept
   public function metagolgi() : String {
         return 'not intercepted';
      }

   @bang @intercept
   public function bang() : String {
         return 'not intercepted';
   }
}


