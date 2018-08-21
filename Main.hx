import bar.Foo;
import adadt.ADADT;

class Main {
    static function blah() : ADADT<Foo> {
        return Bar('hi');
    }
    static function main() {
        var k = blah();
        trace(k + " is the value for k");
        trace("HI");
    }
}

