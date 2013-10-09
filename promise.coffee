# [promise.coffee](http://github.com/CodeCatalyst/promise.coffee) v1.0.2
# Copyright (c) 2012-2103 [CodeCatalyst, LLC](http://www.codecatalyst.com/).
# Open source under the [MIT License](http://en.wikipedia.org/wiki/MIT_License).

nextTick = if process?.nextTick? then process.nextTick else if setImmediate? then setImmediate else ( task ) -> setTimeout( task, 0 )

isFunction = ( value ) -> typeof value is 'function'
isObject = ( value ) -> value is Object( value )

class Resolver
	constructor: ( onResolved, onRejected ) ->
		promise = new Promise( @ )
		pendingResolvers = []
		processed = false
		completed = false
		completionValue = null
		completionAction = null
		
		if not isFunction( onRejected )
			onRejected = ( error ) -> throw error
		
		propagate = ->
			for pendingResolver in pendingResolvers
				pendingResolver[ completionAction ]( completionValue )
			pendingResolvers = []
			return
		complete = ( action, value ) ->
			onResolved = onRejected = null
			completionAction = action
			completionValue = value
			completed = true
			nextTick( -> propagate() ) if pendingResolvers.length > 0
			return
		completeResolved = ( result ) -> 
			complete( 'resolve', result ) if not completed
			return
		completeRejected = ( reason ) -> 
			complete( 'reject', reason ) if not completed
			return
		resolve = ( value ) ->
			try
				if value is promise
					throw new TypeError('A Promise cannot be resolved with itself.')
				if isObject( value ) or isFunction( value )
					thenFn = value.then
					if isFunction( thenFn )
						try
							resolver = new Resolver( resolve, completeRejected)
							thenFn.call( value, resolver.resolve, resolver.reject )
						catch error
							resolver.reject( error )
					else
						completeResolved( value )
				else
					completeResolved( value )
			catch error
				completeRejected( error )
			return
		process = ( value, callback ) ->
			processed = true
			if callback?
				nextTick( ->
					try
						value = callback( value ) if isFunction( callback )
						resolve( value )
					catch error
						completeRejected( error )
					return
				)
			else
				resolve( value )
			return
		
		@resolve = ( result ) ->
			process( result, onResolved ) if not processed
			return
		@reject = ( reason ) ->
			process( reason, onRejected ) if not processed
			return 
		@then = ( onResolved, onRejected ) ->
			if isFunction( onResolved ) or isFunction( onRejected )
				pendingResolver = new Resolver( onResolved, onRejected )
				pendingResolvers.push( pendingResolver )
				nextTick( -> propagate() ) if completed
				return pendingResolver.promise
			return promise
		@promise = promise

class Promise
	constructor: ( resolver ) ->
		@then = ( onFulfilled, onRejected ) -> resolver.then( onFulfilled, onRejected )

class Deferred
	constructor: ->
		resolver = new Resolver()
		
		@promise = resolver.promise
		@resolve = ( result ) -> resolver.resolve( result )
		@reject = ( error ) -> resolver.reject( error )

target = exports ? window
target.Deferred = Deferred
target.defer = -> new Deferred()