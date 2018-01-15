# ![golgi logo](https://vectr.com/omgjjd/aabjEN2Z9.png?width=64&height=64&select=aabjEN2Z9page0) golgi
[![Build Status](https://travis-ci.org/jdonaldson/golgi.svg?branch=master)](https://travis-ci.org/jdonaldson/golgi)

A composable routing library for Haxe.

Golgi is a generic routing library for Haxe. Golgi does not try to be a web
routing library on its own, but it can be used as the basis for one.

It follows these design guidelines:

1. Routes should be simple, fast, and composable.
2. Routing should avoid allocation and unnecessary overhead.
3. Route handling shouldn't presuppose a specific implementation (e.g. Http).
4. Routing should avoid boilerplate and excessive code duplication.


Despite these restrictions, Golgi makes very few tradeoffs for common feature
support.

# Golgi Speed
Golgi is *fast*.  The macro-based route generation eliminates common runtime and
reflection overhead required in other routing libraries.  Raw
throughput can reach 1 Million requests per second on some targets.

A brief speed comparison of Golgi vs. haxe.web.Dispatch for equivalent routing
tasks on a sample of Haxe targets.

![plot](https://i.imgur.com/erHufxP.png)

# Intro
We'll start with a simplified version of the Golgi API in the golgi.basic
module.  Here's a small example of a small route class:

```haxe
import golgi.basic.Api;

class Router extends Api<Any,String>  {
    public function foo() : String {
        return 'foo';
    }
}
```

This Api creates a single route called "foo".  We can route to this function
with the special Golgi class (using a basic version of this here as well):

```haxe
import golgi.Golgi;

class Main {
    static function main() {
        var path = "foo";
        var params = {};
        var api  = new Router();
        var req = null;

        Golgi.run(path, params, req, api);
    }
}
```

Here we're running the Golgi router on the path "foo", using the Api defined by
`Router` (other arguments will be discussed shortly).    This method manages the
lookup of the right function on Router, and invokes the function there.

# Fully Typed Path Arguments

The next step is to do something useful with the API, such as accepting
arguments from the parsed path:

```haxe
class Router extends Api<Any,String>  {
    public function foo(x:Int){
        trace('x + 1 is  ${x + 1}');
        return 'foo';
    }
}
```

The Router class now has a ``foo`` function that accepts an integer. We can
invoke it with the following call:

```haxe
class Main {
    static function main() {
        Golgi.run( "foo/1", {}, new Router());
    }
}
```

Note that the argument ``x`` inside the function body is typed as an ``Int``.
Golgi reads the type information on the``Router`` method interface, and then
makes the appropriate conversion on the corresponding path segment.  If the
``x`` argument is missing, a ``NotFound(path:String)`` error is thrown.  If the
argument can not be converted to an ``Int``, then an ``InvalidValue`` error is
thrown.  All `Float`, `Int`, and `Bool` are all converted directly from strings.
Any `String` arguments are url-escaped.

We can add as many typed arguments as we want, but the argument types are
somewhat limited.  They can only be value types that are able to be converted
from ``String``, such as ``Float``, ``Int``, and ``Bool``.  *More types are
available via abstract typing which is described later on*.

# Route Parameter Support

We can also pass in query parameters using a special ``params`` argument:

```haxe
class Router implements Api<String>  {
    public function foo(x:Int, params : {y : Int}){
        trace('x + 1 is  ${x + 1}');
        trace('params.y + 1 is ${params.y + 1}');
        return 'foo';
    }
}
```

The params are passed in using the second argument of the ``Golgi.run`` method:

```haxe
class Main {
    static function main() {
        Golgi.run("foo/1", {y : 4}, null, new Router());
    }
}
```

The ``params`` argument name is *reserved*.  That is, you can only use that
argument name to specify url parameters, and it must be typed as an anonymous
object.  Also, all param fields must be simple value types, just like the typed
path arguments.


Note that params are not automatically parsed from the path.  They must be
provided separately, or omitted.

# Additional request context
It's common to utilize a *request* argument for route handling.
This is often necessary for web routing, when certain routing logic involves
checking headers, etc.  In Golgi this is called the `request` argument.  It can be
of any type, so once again `request` is a reserved argument name:

```haxe
typedef Request = { header : String };

class Router implements Api<Request, String>  {
    public function foo(x:Int, params : {y : Int}, request : Request){
        trace('x + 1 is  ${x + 1}');
        trace('params.y + 1 is ${params.y + 1}');
        trace('the dummmy request is $request');
        return 'foo';
    }
}
```

```haxe
class Main {
    static function main() {
        Golgi.run("foo/1", {y : 4}, {header : "dummy"}, new Router());
    }
}
```

Here we're using another structural type for our request.  The request type here
will likely be based on the network api provided by the platform, or some cross
platform abstraction.

# Sub-Routing

It's also possible to do sub-routing in Golgi.  This process involves using a
secondary Golgi Api to process additional url parameters, common in hierarchical
routing scenarios.

```haxe
class Router implements golgi.BasicApi<String,String>  {
    public function foo(x:Int, request : Request, subroute : Subroute<String>){
        var result = subroute.run(new SubRouter());

        return result != null ? result : 'foo';
    }
}
```

Like the params and request argument, subroute is a reserved argument name.

# Golgi Type Parameters Explained

We can see that the type parameters of the Golgi Api ``Router<Request,String>``
include the type for the request (``Request``).  The second type parameter
(``String``) indicates the return value that *every* function in the Api must
satisfy.  With this constraint, it's possible to get a statically typed results
from an arbitrary route request:

```haxe
class Main {
    static function main() {
        var result = Golgi.run("foo/1", {y : 4}, {header : "dummy"} , new Router());
        trace('The result is always a string for Router: $result');
    }
}
```

With a consistent return value type retrieved from the route request, it becomes
easier to write a flexible response.  Note that Strings are used here for
illustration purposes only.  Proper return types such as class instances, enums,
and abstract types enable much more control over how information is returned
from the API.



# Path Metadata

It's common for certain paths to include characters and words that are not
valid function names.  Golgi handles this with special path metadata which can
be applied to a route.  Here's how one would handle an *empty* path:

```haxe
class Router implements Api<Request,String>  {
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

Any additional route paths given in `@:alias` or `@:route` should be given as
anonymous strings.  Only one type of path metadata is allowed per route, so if
you're combining a lot of cases together, use the more general `@:route`
specification.

# MetaGolgi

It's common for certain routes to share common handling patterns.  E.g., some
routes are authenticated, others are only applicable for certain Http methods.

It's painful to have to manage these pattern manually on a per-route basis.
Golgi addresses this with a powerful metadata-driven middleware system.

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
class MetaRouter<Request,String> extends golgi.meta.MetaGolgi {
   public function bar(req : Request, next : Request->String) : String {
      return next(req) + "!";
   }
}
```

When you have an appropriate class declared, you may use it in your Api
declarations.  Just use it as simple metadata, with no colon:

```haxe
class Router extends Api<Request,String,MetaRouter> {
    @bar
    public function foo(x:Int, request : Request, subroute : Subroute<String>){
        subroute.run(new SubRouter());
        return 'foo';
    }
}
```

The presence of the `@bar` metadata tells Golgi to apply the corresponding
middleware to this route.

Any unknown simple metadata that is not handled by the MetaGolgi instance will
throw a compile error, ensuring that your middleware behavior is completely
understood by the compiler.

You may also apply metadata at a class level, which will apply the metadata to
all routes defined by the API:

Finally, the base MetaGolgi instance comes with a pass through middleware called
`_golgi_pass`.  You can use this metadata to pass runtime information without
triggering a middleware function.

```haxe
@bar
class Router extends Api<Request,String,MetaRouter> {
    public function foo(x:Int, request : Request, subroute : Subroute<Request>){
        subroute.run(new SubRouter());
        return 'foo';
    }
}
```

Using MetaGolgi for middleware lets you flexibly define complex shared
behaviors, while still adhering to the input and output type parameters defined
by your API.

# Additional features

## Abstract type route arguments
It's possible for routes to accept *abstract* types(!) The abstract type must unify
with one of the four basic value types.  This opens up a lot of
possibilities for automated instantiation and reduction of boilerplate:


```haxe
class Router implements golgi.BasicApi<String,String>  {
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
## Pre-segmented paths

Golgi segments paths by splitting on forward slash characters.  It's possible
to route on pre-segmented paths.  Simply pass an array of strings,
rather than a single string path.

```haxe

        Golgi.run( ["foo","1"], {}, "", new Router());
```

This is useful in situations where the path is already segmented, or when a
specific non-standard delimiter is required.


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

