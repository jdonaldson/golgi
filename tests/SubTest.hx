package;
import golgi.Api;
class SubTest extends Api<Req> {
    public function sub() : String {
        return 'sub';
    }

    @:route('3')
    public function subAlias( params : {msg : Int}, request : Req) : String {
        return 'subAlias';
    }

    @:default
    public function subDefault(request : Req) : String {
        return 'subDefault';
    }
}
