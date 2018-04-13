package foo;
class TestMeta extends golgi.meta.MetaGolgi<Req, TestApiResult>{
    public function new() super();
    public function intercept(req : Req, next : Req->TestApiResult) : TestApiResult {
        return Intercepted;
    }
    public function blahhh(req : Req, next : Req->TestApiResult) : TestApiResult {
        return next(req);
    }
    public function bang(req : Req, next : Req->TestApiResult) : TestApiResult {
        return next(req);
    }
}
