package foo;
import golgi.Api;
class AnotherApi extends Api<String>{
    public function new() { super(); }
    public function another() : String {
        return 'another';
    }
}
