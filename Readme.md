# ![golgi logo](https://vectr.com/omgjjd/aabjEN2Z9.png?width=64&height=64&select=aabjEN2Z9page0) golgi
A composable routing library for Haxe.

Golgi is an opinionated routing library for Haxe. It does not try to be a web
routing library, but can be used as the basis for one.  

It follows design decisions based on these priorities:

1. Route resolution should be simple fast  (rather than flexible and slow)
2. Routes should be composable and configurable (rather than global and static) 
3. Route handling should support common cases (web routing), but be adaptable
to other use cases. (rather than web specific routing)
4. Routes should avoid annoying repetition. (rather than duplicating
   functionality in many places).


# Intro
Here's a small example of a small route class:

```haxe
class Router implements golgi.Api<String,String>  {
    public function foo() : String {
        trace('hi');
        return 'foo';
    }
}
```

This Api creates a single route called "foo".  Here's how to route to this
function:

```haxe
class Main {
    static function main() {
        Golgi.run("foo", {}, "", new Router()); 
    }
}
```

Here we're running the Golgi router on the path ``"foo"``, using the Api defined
by ``Router``.  This method manages the lookup of the right function on Router,
and invokes the function there.  *The Golgi ``run`` method requires some other
parameters which we'll get in to soon.*

The next step is to do something useful with the API, such as accept typed
arguments:

```haxe
class Router implements golgi.Api<String,String>  {
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
        Golgi.run("foo/1", {}, "", new Router()); 
    }
}
```

Note that the argument ``x`` inside the function body is typed as an ``Int``.
Golgi splits the paths into chunks, reads the type information on the``Router`` 
method interface, and then makes the appropriate conversion.  If the ``x`` 
argument is missing, a ``NotFound(path:String)`` error is thrown.  If the
argument can not be converted to an ``Int``, then a ``InvalidValue`` error is
thrown. 

We can add as many typed arguments as we want, but the argument types are
somewhat limited.  They can only be value types that are able to be converted 
from ``String``, such as ``Float``, ``Int``, and ``Bool``.  *More types are
available via ``abstract`` typing which is described later on*.


We can also pass in URL parameters using a special ``params`` argument:

```haxe
class Router implements golgi.Api<String,String>  {
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
        Golgi.run("foo/1", {y : 4}, "", new Router()); 
    }
}
```

The ``params`` argument is *reserved*.  That is, you can only use that argument 
name to specify url parameters, and it must be typed as an anonymous object.
Also, all param fields must be simple value types (``String``,``Bool``,``Int``, etc). 

Last but not least, it's common to utilize a *request* argument for route handling.
This is often necessary for web routing, when certain routing logic involves 
checking headers, etc:

```haxe
class Router implements golgi.Api<String,String>  {
    public function foo(x:Int, params : {y : Int}, context : String){
        trace('x + 1 is  ${x + 1}');
        trace('params.y + 1 is ${params.y + 1}');
        trace('the dummmy context is $context');
        return 'foo';
    }
}
```

```haxe
class Main {
    static function main() {
        Golgi.run("foo/1", {y : 4}, "dummy", new Router()); 
    }
}
```

Here we're using a string type for our context.  Web routers will typically pass
in a structural type, or some sort of class.

We can see that the type parameters of the Golgi Api include the type for the
context (``String``).  The second type parameter (also ``String``) indicates 
the return value that *every* function in the Api must satisfy.  With this
constraint, it's possible to get a statically typed results from an arbitrary
route request:

```haxe
class Main {
    static function main() {
        var result = Golgi.run("foo/1", {y : 4}, "dummy", new Router()); 
        trace('The result is always a string for Router: $result');
    }
}
```

With a consistent return value type retrieved from the route request, it becomes
easier to write a flexible response.

# Extra Features

## Default

Route functions marked with ``@default`` are handled during empty route
requests:

```haxe
class Router implements golgi.Api<String,String>  {
    @default
    public function foo() : String{
        return 'foo';
    }
}
```

```haxe
class Main {
    static function main() {
        Golgi.run("", {}, "", new Router()); 
    }
}
```

## Abstract type route arguments
It's possible for routes to accept *abstract* types! The abstract type must unify 
with one of the four basic value types.  This opens up a lot of
possibilities for automated instantiation and reduction of boilerplate:


```haxe
class Router implements golgi.Api<String,String>  {
    @default
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
        return new Wat(str);
    }
}
```

