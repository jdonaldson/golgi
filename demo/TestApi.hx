class TestApi implements golgi.Api<Req>  {
   public function foo() : String {
      return 'foo';
   }
   @baz public function bar() : String {
      return 'foo';
   }
   public function arg(x:Int){
      return x;
   }
}
