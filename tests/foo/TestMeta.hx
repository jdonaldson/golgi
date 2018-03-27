package foo;
class TestMeta extends golgi.meta.MetaGolgi<Req, TestApiRoute>{
    public function new() super();
    public function intercept(req : Req, next : Req->TestApiRoute) : TestApiRoute {
        return Intercepted;
    }
    public function blahhh(req : Req, next : Req->TestApiRoute) : TestApiRoute {
        return next(req);
    }
    public function bang(req : Req, next : Req->TestApiRoute) : TestApiRoute {
        return next(req);
    }
}
