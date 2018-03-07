package;
import Req;
import golgi.meta.MetaGolgi;
import foo.TestApi.TestApiRoute;
class TestMeta extends MetaGolgi<Req, TestApiRoute>{
    public function new() super();
    public function intercept(req : Req, next : Req->TestApiRoute) : TestApiRoute {
        return next(req);
    }
    public function blahhh(req : Req, next : Req->TestApiRoute) : TestApiRoute {
        return next(req);
    }
    public function bang(req : Req, next : Req->TestApiRoute) : TestApiRoute {
        return next(req);
    }
}
