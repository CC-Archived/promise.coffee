# [promise.coffee](http://github.com/CodeCatalyst/promise.coffee) v1.0.1
# Copyright (c) 2012-2103 [CodeCatalyst, LLC](http://www.codecatalyst.com/).
# Open source under the [MIT License](http://en.wikipedia.org/wiki/MIT_License).

nextTick = process?.nextTick or setImmediate or ( task ) -> setTimeout( task, 0 )

isFunction = ( value ) -> typeof value is 'function'

class Resolver
	constructor: ( onResolved, onRejected ) ->
		@promise = new Promise( @ )
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
		schedule = ( pendingResolver ) ->
			pendingResolvers.push( pendingResolver )
			propagate() if completed
			return
		complete = ( action, value ) ->
			onResolved = onRejected = null
			completionAction = action
			completionValue = value
			completed = true
			propagate()
			return
		completeResolved = ( result ) -> 
			complete( 'resolve', result )
			return
		completeRejected = ( reason ) -> 
			complete( 'reject', reason )
			return
		
		process = ( callback, value ) ->
			processed = true
			try
				value = callback( value ) if isFunction( callback )
				if value and isFunction( value.then )
					value.then( completeResolved, completeRejected )
				else
					completeResolved( value )
			catch error
				completeRejected( error )
			return
		
		@resolve = ( result ) ->
			process( onResolved, result ) if not processed
			return
		@reject = ( error ) ->
			process( onRejected, error ) if not processed
			return 
		@then = ( onResolved, onRejected ) ->
			if isFunction( onResolved ) or isFunction( onRejected )
				pendingResolver = new Resolver( onResolved, onRejected )
				nextTick( -> schedule( pendingResolver ) )
				return pendingResolver.promise
			return @promise

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