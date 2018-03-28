package;
import golgi.Api;
import foo.TestMeta;
class SubTest extends Api<Req> {
    var id : Int;
    override public function new(_id : Int){
        this.id = _id;
        super();
    }

    public function sub() : String {
        return 'sub_' + id;
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

