package foo;
import adadt.Build;

@:build(adadt.Build.build(TestApi))
enum TestApiResult{
    Intercepted;
}
