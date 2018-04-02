import golgi.*;

class TestApi extends Api<Req>  {
   public function foo() : String {
      return 'foo';
   }
   public function bar() : Int {
      return 4;
   }

   public function arg(x:Int){
      return x;
   }

   public function param(x : Int, params : {y : Int}){
      return x  + params.y;
   }
   public function request(request : Req){
      return request.header;
   }
   public function subroute(request : Req, subroute : Subroute<Req>) {
      var sub_api = new SubTestApi();
      var sub_glg = new SubTestApiGolgi(sub_api);
      var res = subroute.route(sub_glg);
      switch(res){
         case Foo(x) : return x;
         default : throw ('Invalid $res');
      }
   }
}
