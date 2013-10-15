# [promise.coffee](http://github.com/CodeCatalyst/promise.coffee) v1.0.4
# Copyright (c) 2012-2103 [CodeCatalyst, LLC](http://www.codecatalyst.com/).
# Open source under the [MIT License](http://en.wikipedia.org/wiki/MIT_License).

nextTick = if process?.nextTick? then process.nextTick else if setImmediate? then setImmediate else ( task ) -> setTimeout( task, 0 )

class CallbackQueue
	constructor: ->
		queuedCallbacks = new Array(1e4)
		queuedCallbackCount = 0
		execute = ->
			index = 0
			while index < queuedCallbackCount
				queuedCallbacks[ index ]()
				queuedCallbacks[ index ] = null
				index++
			queuedCallbackCount = 0
			return
		@schedule = ( callback ) ->
			queuedCallbacks[ queuedCallbackCount++ ] = callback
			nextTick( execute ) if queuedCallbackCount is 1
			return

callbackQueue = new CallbackQueue()
enqueue = ( task ) -> callbackQueue.schedule( task )

isFunction = ( value ) -> value and typeof value is 'function'
isObject = ( value ) -> value and typeof value is 'object'

class Consequence
	constructor: ( @resolve, @reject ) ->
		@resolver = new Resolver()
		@promise = @resolver.promise
	
	trigger: ( action, value ) ->
		resolver = @resolver
		callback = @[ action ]
		if isFunction( callback )
			enqueue( ->
				try
					resolver.resolve( callback( value ) )
				catch error
					resolver.reject( error )
				return
			)
		else
			resolver[ action ]( value )
		return

class Resolver
	constructor: ->
		@promise = new Promise( @ )
		@consequences = []
		@completed = false
		@completionAction = null
		@completionValue = null
	
	then: ( onFulfilled, onRejected ) ->
		consequence = new Consequence( onFulfilled, onRejected )
		if @completed
			consequence.trigger( @completionAction, @completionValue )
		else
			@consequences.push( consequence )
		return consequence.promise
	
	resolve: ( value ) ->
		if @completed
			return
		try
			if value is @promise
				throw new TypeError( 'A Promise cannot be resolved with itself.' )
			if ( isObject( value ) or isFunction( value ) ) and isFunction( thenFn = value.then )
				isHandled = false
				try
					self = @
					thenFn.call(
						value
						( value ) ->
							if not isHandled
								isHandled = true
								self.resolve( value )
							return
						( error ) ->
							if not isHandled
								isHandled = true
								self.reject( error )
							return
					)
				catch error
					@reject( error ) if not isHandled
			else
				@complete( 'resolve', value )
		catch error
			@reject( error )
		return
	
	reject: ( error ) ->
		if @completed
			return
		@complete( 'reject', error )
		return
	
	complete: ( action, value ) ->
		@completionAction = action
		@completionValue = value
		@completed = true
		for consequence in @consequences
			consequence.trigger( @completionAction, @completionValue )
		@consequences = null
		return

class Promise
	constructor: ( resolver ) ->
		@then = ( onFulfilled, onRejected ) -> resolver.then( onFulfilled, onRejected )

class Deferred
	constructor: ->
		resolver = new Resolver()
		
		@promise = resolver.promise
		@resolve = ( value ) -> resolver.resolve( value )
		@reject = ( error ) -> resolver.reject( error )

target = exports ? window
target.Deferred = Deferred
target.defer = -> new Deferred()