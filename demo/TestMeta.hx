class TestMeta extends golgi.MetaGolgi<Req, TestApiResult> {
   public function baz(req : Req, next : Req->TestApiResult) : TestApiResult {
      if (req.header == "Invalid") throw "Invalid";
      else return next(req);
   }
}
