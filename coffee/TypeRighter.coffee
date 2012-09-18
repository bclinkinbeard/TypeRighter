
class TypeRighter

	constructor: ->
		@_pathRegistry = {}

	reset: =>
		@_pathRegistry = {}

	registerPath: ( path, callback ) =>
		# accepts array or comma separated (with optional spaces) string for path arg
		paths = if _.isArray( path ) then path else path.split( ', ' ).join( ',' ).split( ',' )
		for _path in paths
			# each path gets an array to allow multiple callbacks
			@_pathRegistry[ _path ] = @_pathRegistry[ _path ] || []
			@_pathRegistry[ _path ].push( callback )

	getCallbacksForPath: ( path ) =>
		results = []
		for k, v of @_pathRegistry
			if path.substr( -( k.length ) ) == k
				results = v
				break

		return results

	parse: ( data, path = '', pathList = [] ) =>

		_.each data, ( value, key, list ) =>

			_path = path
			_path += '.' if path isnt '' and !_.isArray( list )
			_path += key if !_.isArray( list )
			pathList.push( _path ) if pathList.indexOf( _path ) < 0

			if !_.isArray( value )
				for callback in @getCallbacksForPath( _path )
					( callback ).call( value, list[ key ], key, list )

			if _.isObject( value )
				@parse( list[ key ], _path, pathList )

		@pathList = pathList
		return data

	@type: ( type ) =>
		return ( value, key, scope ) ->
			scope[ key ] = _.extend new type(), value

	@replaceWith: ( f ) =>
		if _.isFunction( f )
			return ( value, key, scope ) ->
				scope[ key ] = f.apply( value, arguments )
		else
			return ( value, key, scope ) ->
				scope[ key ] = f
