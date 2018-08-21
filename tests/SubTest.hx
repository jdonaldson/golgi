package;
import golgi.Api;
import foo.TestMeta;

class SubTest implements Api<Req> {
    var id : Int;
    public function new(_id : Int){
        this.id = _id;
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

