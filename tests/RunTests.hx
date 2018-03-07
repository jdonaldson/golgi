package ;
import haxe.unit.*;
import foo.TestApi.TestApiRoute;


class RunTests {
  static var tests:Array<TestCase> = [
    new TestPaths(),
  ];

  static function main() {
    var k : TestApiRoute;
    var r = new TestRunner();
    for (t in tests) r.add(t);
    travix.Logger.exit(r.run() ? 0 : 500);
  }

}
