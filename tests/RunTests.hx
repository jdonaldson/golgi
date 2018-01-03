package ;
import haxe.unit.*;


class RunTests {
  static var tests:Array<TestCase> = [
    new Paths(),
  ];

  static function main() {
    var r = new TestRunner();
    for (t in tests) r.add(t);
#if !js
    Sys.exit(r.run() ? 0 : 500);
#end
  }

}
