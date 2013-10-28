<img src="https://raw.github.com/CodeCatalyst/promise.coffee/master/promise_coffee-logo.png" width="580" height="115">
<a href="http://promisesaplus.com/"><img src="http://promisesaplus.com/assets/logo-small.png" alt="Promises/A+ logo" title="Promises/A+ 1.1 compliant" align="right" /></a>

[![Build Status](https://travis-ci.org/CodeCatalyst/promise.coffee.png?branch=master)](https://travis-ci.org/CodeCatalyst/promise.coffee)

## About

promise.coffee is an ultra-lean (~100 lines) object-oriented [CoffeeScript](http://coffeescript.org/) implementation of the [Promises/A+ Specification](https://github.com/promises-aplus/promises-spec) that passes the [Promises/A+ Compliance Test Suite](https://github.com/promises-aplus/promises-tests).

Inspired by [avow.js](https://github.com/briancavalier/avow), promise.coffee differs by providing a reference implementation that decomposes Promise/A+ functionality into object-oriented classes.  The approach demonstrated here offers a model for how Promises might be implemented in stricter class oriented languages.

It is fully asynchronous, ensuring that the `onFulfilled` and `onRejected` callbacks are not executed in the same turn of the event loop as the call to `then()` with which they were registered.  To schedule execution of these callbacks, it uses `process.nextTick()` or `setImmediate()` if available (see [NobleJS's setImmediate() polyfill](https://github.com/NobleJS/setImmediate)) and will otherwise fall back to `setTimeout()`.

It supports foreign promises returned by callbacks as long as they support the standard Promise `then()` method signature.

## API

Create a deferred:

	var deferred = new Deferred();

Resolve that deferred:
	
	deferred.resolve( value );

Or, reject that deferred:

	deferred.reject( reason );

Obtain the promise linked to that deferred to pass to external consumers:

	var promise = deferred.promise;

Add (optional) handlers to that promise:

	promise.then( onFulfilled, onRejected );

## Installation

### Node.js

Download, clone or:

	npm install promise.coffee
	
and then:

	var Deferred = require( 'promise.coffee' ).Deferred;

### AMD:

Assuming you have configured your loader to map the promise.coffee files to the 'promise' module identifier.

	define( function ( require, exports, module ) {
		var Deferred = require( 'promise' ).Deferred;
		
		...
	});

### &lt;script&gt; tag:

Reference the appropriate script file from your HTML file:

	<script src="promise.js"></script>

or, for the minified version of the script:

	<script src="promise.min.js"></script>


or, in the unlikely case you are using the browser-based CoffeeScript compiler:

	<script type="text/coffeescript" src="promise.coffee"></script>

## Internal Anatomy

This implementation decomposes Promise functionality into four classes:

### Promise

Promises represent a future value; i.e., a value that may not yet be available.

A Promise's `then()` method is used to specify `onFulfilled` and `onRejected` callbacks that will be notified when the future value becomes available.  Those callbacks can subsequently transform the value that was fulfilled or the reason that was rejected.  Each call to `then()` returns a new Promise of that transformed value; i.e., a Promise that is fulfilled with the callback return value or rejected with any error thrown by the callback.

### Deferred

A Deferred is typically used within the body of a function that performs an asynchronous operation.  When that operation succeeds, the Deferred should be resolved; if that operation fails, the Deferred should be rejected.

A Deferred is resolved by calling its `resolve()` method with an optional value, and is rejected by calling its `reject()` method with an optional reason.  Once a Deferred has been fulfilled or rejected, it is considered to be complete and subsequent calls to `resolve()` or `reject()` are ignored.

Deferreds are the mechanism used to create new Promises.  A Deferred has a single associated Promise that can be safely returned to external consumers to ensure they do not interfere with the resolution or rejection of the deferred operation.

### Resolver

Resolvers are used internally by Deferreds to create, resolve and reject Promises, and to propagate fulfillment and rejection.

Developers never directly interact with a Resolver.

Each Deferred has an associated Resolver, and each Resolver has an associated Promise.  A Deferred delegates `resolve()` and `reject()` calls to its Resolver's `resolve()` and `reject()` methods.  A Promise delegates `then()` calls to its Resolver's `then()` method.  In this way, access to Resolver operations are divided between producer (Deferred) and consumer (Promise) roles.

When a Resolver's `resolve()` method is called, it fulfills with the optionally specified value.  If `resolve()` is called with a then-able (i.e. a Function or Object with a `then()` function, such as another Promise) it assimilates the then-able's result; the Resolver provides its own `resolve()` and `reject()` methods as the `onFulfilled` or `onRejected` arguments in a call to that then-able's `then()` function.  If an error is thrown while calling the then-able's `then()` function (prior to any call back to the specified `resolve()` or `reject()` methods), the Resolver rejects with that error.  If a Resolver's `resolve()` method is called with its own Promise, it rejects with a `TypeError`.

When a Resolver's `reject()` method is called, it rejects with the optionally specified reason.

Each time a Resolver's `then()` method is called, it captures a pair of optional `onFulfilled` and `onRejected` callbacks and returns a Promise of the Resolver's future value as transformed by those callbacks.

### Consequence

Consequences are used internally by Resolvers to capture and notify callbacks, and propagate their transformed results as fulfillment or rejection.

Developers never directly interact with a Consequence.

A Consequence forms a chain between two Resolvers, where the result of the first Resolver is transformed by the corresponding callback before being applied to the second Resolver.

Each time a Resolver's `then()` method is called, it creates a new Consequence that will be triggered once its originating Resolver has been fulfilled or rejected.  A Consequence captures a pair of optional `onFulfilled` and `onRejected` callbacks. 

Each Consequence has its own Resolver (which in turn has a Promise) that is resolved or rejected when the Consequence is triggered.  When a Consequence is triggered by its originating Resolver, it calls the corresponding callback and propagates the transformed result to its own Resolver; resolved with the callback return value or rejected with any error thrown by the callback.

## Running the Promises/A+ Test Suite

1. `npm install`
2. `npm test`

## Reference and Reading

* [Common JS Promises/A Specification](http://wiki.commonjs.org/wiki/Promises/A)
* [Promises/A+ Specification](https://github.com/promises-aplus/promises-spec)
* [You're Missing the Point of Promises](https://gist.github.com/3889970)


## Acknowledgements

* [Kris Zyp](https://github.com/kriszyp), who proposed the original [Common JS Promises/A Specification](http://wiki.commonjs.org/wiki/Promises/A) and created [node-promise](https://github.com/kriszyp/node-promise) and [promised-io](https://github.com/kriszyp/promised-io),
* [Domenic Denicola](https://github.com/domenic) for the [Promises/A+ Specification](https://github.com/promises-aplus/promises-spec) and [Promises/A+ Compliance Test Suite](https://github.com/promises-aplus/promises-tests), and for his work with:
* [Kris Kowal](https://github.com/kriskowal), who created [q](https://github.com/kriskowal/q), a JavaScript promise library that pioneered many of the practices now codified in the [Promises/A+ Specification](https://github.com/promises-aplus/promises-spec),
* [Brian Cavalier](https://github.com/briancavalier) for his contributions to the [Promises/A+ Specification](https://github.com/promises-aplus/promises-spec) and [Promises/A+ Compliance Test Suite](https://github.com/promises-aplus/promises-tests), and the inspiration that [avow.js](https://github.com/briancavalier/avow) and [when.js](https://github.com/cujojs/when) (with [John Hann](https://github.com/unscriptable)) and [past GitHub issue discussions](https://github.com/cujojs/when/issues/60) have provided; and
* [Yehor Lvivski](http://lvivski.com/), whose [Davy Jones](https://github.com/lvivski/davy) Promises/A+ implementation and our discussion around optimizing its performance inspired improvements to promise.coffee's implementation; and
* [Jason Barry](http://dribbble.com/artifactdesign), who designed the promise.coffee logo.

## License

Copyright (c) 2012-2013 [CodeCatalyst, LLC](http://www.codecatalyst.com/)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
