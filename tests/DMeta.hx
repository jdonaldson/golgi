import Main.Bar;

class DMeta extends golgi.meta.MetaGolgi<String, BarRoute> {
    public function intercept<String>(req : String, next : String->BarRoute) : BarRoute {
        return next(req);
    }
    public function bang<String>(req : String, next : String->BarRoute) : BarRoute {
        return next(req);
    }
}
