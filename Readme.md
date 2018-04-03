# ![golgi logo](https://vectr.com/omgjjd/aabjEN2Z9.png?width=64&height=64&select=aabjEN2Z9page0) golgi
[![Build Status](https://travis-ci.org/jdonaldson/golgi.svg?branch=master)](https://travis-ci.org/jdonaldson/golgi)

A composable routing library for Haxe.

Golgi is a macro-based generic routing library for Haxe.  It is intended to be
used as the basis for more complex and specific routing applications (e.g. Http
URL routing)

It follows these design guidelines:

1. Routes should be simple, fast, and composable.
2. Routing should avoid allocation and unnecessary overhead.
3. Route handling shouldn't presuppose a specific protocol (e.g. Http).
4. Routing should avoid boilerplate and excessive code duplication.
5. Routing should not include the rendering of results (e.g. to Json)


Despite these restrictions, Golgi makes very few tradeoffs for feature support.
Golgi relies heavily on macros, which can optimize routing in many cases, and
provides a unique macro-based class/ADT binding that enables fluent route
management with a minimum of coding.


# Golgi Speed
Golgi is *fast*.  The macro-based route generation eliminates common runtime and
reflection overhead required in other routing libraries.  Raw
throughput can reach 1 Million requests per second on some targets.

A brief speed comparison of Golgi vs. haxe.web.Dispatch for equivalent routing
tasks on a sample of Haxe targets.

![plot](https://i.imgur.com/erHufxP.png)

# Intro

We'll start with a simplified version of the Golgi API in the golgi.basic
module.  The golgi Api requires a type parameter for a request type, but we can
ignore that for now by passing a dummy type. Here's a small example of a small
route class:

```haxe
import golgi.Api;
typedef Req = Any;

class TestApi extends Api<Req>  {
    public function foo() : String {
        return 'foo';
    }
    public function bar() : Int {
        return 4;
    }
}
```

Conventional routing system functions don't have heterogeneous return types.
They will require that responses be written inside the handler, or they will
require returning a single type across all routes. Golgi differs radically from
this approach by enabling heterogeneous return values across the defined routes.
This enables greater flexibility in providing routing behavior, while also
maintaining a type safe interface for a routing result.

# Routers and ADT

Ideally, an algebraic data type (ADT) *enum* is used to specify
heterogeneous return values.  However, this enum must be maintained separately
from the actual routing logic, increasing the chances for bugs, and adding to
the maintenance overhead.  Golgi's approach is to build the enum for you, based
on the routing api you specify using a special `@:build` directive:

```haxe
@:build(golgi.Build.routes(TestApi))
enum TestApiRoute {}

```

The `@:build` metadata here instructs the Golgi macro method to build the full
specification for the `TestApiRoute` enum based on the api of `TestApi`.


If we look at the enum constructors from `TestApiRoute` we see that they include
`Foo(res:String)` and `Bar(res:Int)`, both according to the compiler and in the
runtime.  These enum states describe the public methods of `TestApi`, with a
single parameter providing the return type and value.

```haxe
 var ctors = TestApiRoute.getConstructors();
 trace(ctors + " is the value for ctors"); // [Foo, Bar]

```


Having a synchronized enum for our test api results is not enough though, we
still need to provide the logic for parsing a string into paths and parameters,
selecting the function to invoke, and capturing the return value in the enum.
Furthermore, we only want the ADT enum type when we *don't* know which function
is getting called.  In all other cases, we want to be able to use the plain
`TestApi` instance directly.

Golgi provides all of this functionality by extending a separate `Golgi` class.
This class is fully parameterized by the types we've defined previously.

```haxe
import golgi.Golgi;
typedef TestMeta = golgi.meta.MetaGolgi<Any,TestApiRoute>;

class TestApiGolgi extends Golgi<Req, TestApi, TestApiRoute, TestMeta>{}

```

The Golgi class we defined is also under the effect of a build macro.  This
macro builds a specialized `route` function that:

1. Separates the path arguments into function names and arguments
2. Applies relevant route metamethods defined in the MetaGolgi.
3. Applies the arguments on the route function.
4. Captures the result in the route enum.

The routing class requires references to the types we've defined previously.  (In
addition, it requires a `MetaGolgi` parameter that we will describe later.)


```haxe
import golgi.Golgi;

class Main {
    static function main() {
        var params = {};
        var req = {};

        var api  = new TestApi();
        var glg = new TestApiGolgi();

        var res = glg.route(["foo"], params, req);
    }
}
```

Here we're running the Golgi router on the path "foo", using the Api defined by
`TestApi` (other arguments will be discussed shortly).    This method manages the
lookup of the right function on TestApi, and invokes the function there.

Note : Golgi accepts its path argument as an array of simple strings.  Golgi
does not split or decode strings in urls, leaving that to be handled by upstream
libraries.

# Fully Typed Path Arguments

The next step is to do something useful with the API, such as accepting
arguments from the parsed path:

```haxe
class TestApi extends Api<Any>  {
    public function arg(x:Int){
        return x;
    }
}
```

The TestApi class now has a ``foo`` function that accepts an integer and returns
it as its result. We can invoke it with the following call:

```haxe
class Main {
    static function main() {
        glg.run( ["foo","1"], {}, req));
    }
}
```

Note that the argument ``x`` inside the function body is typed as an ``Int``.
Golgi reads the type information on the``TestApi`` method interface, and then
makes the appropriate conversion on the corresponding path segment in the
runtime.  If the ``x`` argument is missing, a ``NotFound(path:String)`` error is
thrown.  If the argument can not be converted to an ``Int``, then an
``InvalidValue`` error is thrown.  `Float`, `Int`, and `Bool` are all
converted directly from strings.

We can add as many typed arguments as we want, but the argument types are
somewhat limited.  They can only be value types that are able to be converted
from ``String``, such as ``Float``, ``Int``, and ``Bool``.  *More types are
available via abstract typing which is described later on*.

# Route Parameter Support

We can also pass in query parameters using a special ``params`` argument.
This simple example adds the `x` Integer argument to the `y` argument passed as
a param:

```haxe
class TestApi implements Api<Req>  {
   public function param(x : Int, params : {y : Int}){
      return x  + params.y;
   }
}
```

The params are passed in using the second argument of the ``Golgi.run`` method:

```haxe
class Main {
    static function main() {
      var param = glg.route(["param", "1"], {y : "2"}, {});
    }
}
```

The ``params`` argument name is *reserved*.  That is, you can only use that
argument name to specify path-derived parameters, and it must be typed as an
anonymous object.  Also, all param fields must be simple value types, just like
the typed path arguments.


Note that params are not automatically parsed from the path.  They must be
provided separately, or omitted.

# Additional request context
It's common to utilize a *request* argument for route handling.
This is often necessary for web routing, when certain routing logic involves
checking headers, etc.  In Golgi this is called the `request` argument.  It can be
of any type, so once again `request` is a reserved argument name:

```haxe
typedef Req = { header : String };

class TestApi implements Api<Req>  {
    public function foo(request : Req){

    }
}
```

```haxe
class Main {
    static function main() {
         var req = glg.route(["request"], {}, req);
    }
}
```

Here we're using another structural type for our request.  However, `request`
and `params` tend to have specialized purposes : The `params` argument *must* be
an anonymous object type that has simple string fields.  It is typically
constructed from the path content itself.  The `request` argument should refer
to internal application data that is available in the request context.


# Sub-Routing

It's also possible to perform sub-routing in Golgi.  This process involves using
a secondary Golgi Api to process additional path parameters, common in
hierarchical routing scenarios:

```haxe
import golgi.*;
class SubTestApi extends Api<Req> {
   public function foo(x: Int){
      return x;
   }
}

```

When we handle the subroute, we can use the special `subroute` argument to route
the leftover parts of the path on the relevant instance.



```haxe
class TestApi implements golgi.Api<Req>  {
   public function subroute(request : Req, subroute : Subroute<Req>) {
      var sub_api = new SubTestApi();
      var sub_glg = new SubTestApiGolgi(sub_api);
      vu res = subroute.route(sub_glg);
      switch(res){
         case Foo(x) : return x;
         default : throw ('Invalid $res');
      }
   }
}
```

Like the params and request argument, `subroute` is a reserved argument name. It
contains a simple method that will accept an appropriately typed Golgi instance,
and handle the leftover paths as a route there.

Routing to the subroute doesn't require anything special from the main router.
Simply pass in the path containing the extra parameters required by the
subroute.

```haxe
   var sub = glg.route(["subroute","foo","1"], {}, req);
```


# Golgi Type Parameters Explained

We can see that the type parameters of the Golgi Api ``TestApi<Req>``
includes the type for the request (``Req``).

The Golgi router itself accepts four parameters:

```haxe
class TestApiGolgi extends Golgi<Req, TestApi, TestApiRoute, TestMeta>{}
```
These parameters tell Golgi the relationships between the four types required
for routing :

1. Request parameter
2. Api parameter (which must have its own matching Request parameter)
3. Route parameter (which must match the Api parameter function/return values)
4. Path Metadata (meta) parameter, which must match the Route parameter as well
   as the Request parameter.


# Path Metadata

Sometimes paths must include characters that are not allowed as valid function
names.  Golgi handles this with special path metadata which can be applied to a
route.  Here's how one would handle an *empty* path:

```haxe
class TestApi implements Api<Request,String>  {
    @:default
    public function foo(){
        return 'foo';
    }
}
```

In this case, the `foo` route is activated for an empty path.  Here's the
full list of path metadata:

1. `@:default` : This route is triggered *only* for an empty path.
2. `@:alias('additional_path', 'additional_path2')` : The following paths will trigger
   the given route inclusive of the function name.
3. `@:route('route_path1', 'route_path2')` : The following list of paths trigger
   the route exclusive of the function name.
4. `@:helper`: This function is not treated as a path (useful for public helper
   functions).

Any additional route paths given in `@:alias` or `@:route` should be given as
anonymous strings.  Only one type of path metadata is allowed per route, so if
you're combining a lot of cases together, use the more general `@:route`
specification.

# MetaGolgi

It's common for certain routes to share common handling patterns.  E.g., some
routes require authentication, others are only applicable for certain Http
methods. It's painful to have to manage these pattern manually on a per-route
basis.  Golgi addresses this with a powerful metadata-driven middleware system.

The MetaGolgi instance expects a signature of `TReq->(TReq->TRet)->TRet`.  This
signature provides the request parameter, and a function that calls the next
middleware method.  Eventually, either a middlware function returns a `TRet`
type, or the route function itself is called.  This enables middleware methods
to intercept specific route traffic, and perform certain modifications
(modifying headers, or pre-emptively returning a given response).

In order to use a MetaGolgi, it's necessary to extend a base `MetaGolgi`
instance.  This special class will ensure that every public instance method has
the required signatures for its methods.


```haxe
class MetaTestApi extends golgi.meta.MetaGolgi<Request> {
   public function bar(req : Request, next : Request->String) : String {
      return next(req) + "!";
   }
}
```

When you have an appropriate class declared, you may use it in your Api
declarations.  Just use it as simple metadata, *with no colon*:

```haxe
class TestApi extends Api<Request,String,MetaTestApi> {
    @bar
    public function foo(request : Request){
        return 'foo';
    }
}
```

The presence of the `@bar` metadata tells Golgi to apply the corresponding
middleware to this route.  Note that a `request` argument must be accepted by
the function for the metagolgi method to work.

Any unknown simple metadata that is not handled by the MetaGolgi instance will
throw a compile error, ensuring that your middleware behavior is completely
understood by the compiler.

You may also apply metadata at a class level, which will apply the metadata to
all routes defined by the API:

```haxe
@bar
class TestApi extends Api<Request> {
    public function foo(x:Int, request : Request, subroute : Subroute<Request>){
        subroute.run(new SubTestApi());
        return 'foo';
    }
}
```
Finally, the base MetaGolgi instance comes with a pass through middleware called
`_golgi_pass`.  You can use this metadata to pass runtime information without
triggering a middleware function.

Using MetaGolgi for middleware lets you flexibly define complex shared
behaviors, while still adhering to the input and output type parameters defined
by your API.

# Additional features

## Abstract type route arguments
It's possible for routes to accept *abstract* types(!) The abstract type must unify
with one of the four basic value types.  This opens up a lot of
possibilities for automated instantiation and reduction of boilerplate:


```haxe
class TestApi implements golgi.BasicApi<Req>  {
    public function foo(x:Bar) : String{
        trace(x.toString());
        return 'foo';
    }
}

abstract Bar(String){
    public function new (str: String){
        this = str + '?';
    }
    public function toString() {
        return this + "!";
    }
    @:from
    static public function fromString(str:String){
        return new Bar(str);
    }
}
```

# Misc

## What the heck is a Golgi?

The Golgi apparatus is an
[organelle](https://en.wikipedia.org/wiki/Golgi_apparatus), or specialized
subunit within a biological cell.  It's involved with packaging proteins and
routing them to destinations within the cell's nucleus.  As important as the
Golgi apparatus is, it is still just part of a cell.  It doesn't stand on its
own.

A Golgi API is involved with packaging content and routing it to the appropriate
API.  As critical as this job is, Golgi doesn't stand on its own as a web
framework.  Instead, it seeks to serve as a flexible basis for numerous other
routing tasks.


Golgi is based heavily off of
[haxe.web.Dispatch](http://api.haxe.org/haxe/web/Dispatch.html).  Dispatch is
well loved, but it's older and its design was driven in part due to limitations
in the macro features of the time.  While certain Dispatch patterns will be
familiar, enough of the API and feature set has changed to merit a new name
rather than a new version.

