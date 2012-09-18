describe "TypeRighter", ->

	tr = undefined
	commitClass = undefined
	authorClass = undefined
	committerClass = undefined
	urlClass = undefined
	callback = undefined

	beforeEach ->
		tr = new TypeRighter()
		commitClass = class Commit
		authorClass = class Author
		committerClass = class Committer
		urlClass = class Url

	it "should instantiate", ->
		expect( tr ).toBeDefined()

	it "should clear path registry when reset is called", ->
		registry = tr._pathRegistry
		tr.reset()
		expect( registry ).not.toBe( tr._pathRegistry )

	describe "registering paths", ->

		beforeEach ->
			tr.reset()
			callback = ->

		it "should add a single path", ->
			path = 'foo'
			tr.registerPath( path, callback )
			expect( tr.getCallbacksForPath( path ).length ).toBe( 1 )
			expect( tr.getCallbacksForPath( path )[ 0 ] ).toBe( callback )

		it "should add an array of paths", ->
			paths = [ 'foo', 'bar' ]
			tr.registerPath( paths, callback )
			expect( tr.getCallbacksForPath( paths[ 0 ] ).length ).toBe( 1 )
			expect( tr.getCallbacksForPath( paths[ 0 ] ) ).toContain( callback )
			expect( tr.getCallbacksForPath( paths[ 1 ] ).length ).toBe( 1 )
			expect( tr.getCallbacksForPath( paths[ 1 ] ) ).toContain( callback )

		it "should add a comma separated list of paths", ->
			paths = 'foo, bar'
			tr.registerPath( paths, callback )
			expect( tr.getCallbacksForPath( 'foo' ).length ).toBe( 1 )
			expect( tr.getCallbacksForPath( 'foo' ) ).toContain( callback )
			expect( tr.getCallbacksForPath( 'bar' ).length ).toBe( 1 )
			expect( tr.getCallbacksForPath( 'bar' ) ).toContain( callback )

	describe "calling callbacks", ->

		it "should pass proper values to callbacks", ->
			target = {}
			target.callback = ( value, key, scope ) ->
			spyOn target, 'callback'
			tr.registerPath( 'commit.committer.name', target.callback )
			tr.parse( commits )
			expect( target.callback ).toHaveBeenCalledWith( commits[ 0 ].commit.committer.name, 'name', commits[ 0 ].commit.committer )

	describe "TypeRighter.replaceWith()", ->

		it "should replace a value with the value passed to replaceWith", ->
			newName = 'Willy Wonka'
			tr.registerPath( 'commit.committer.name', TypeRighter.replaceWith( newName ) )
			tr.parse( commits )
			expect( commits[ 0 ].commit.committer.name ).toBe( newName )

		it "should invoke a function passed to replaceWith", ->
			target = {}
			target.replaceFunc = ( value, key, scope ) ->
				return 'Santa Claus'
			spyOn( target, 'replaceFunc').andCallThrough()
			tr.registerPath( 'commit.committer.name', TypeRighter.replaceWith( target.replaceFunc ) )
			tr.parse( commits )
			expect( commits[ 0 ].commit.committer.name ).toBe( 'Santa Claus' )

	describe "TypeRighter.type() and path matching", ->

		it "should match an empty string to root array members", ->
			tr.registerPath( '', TypeRighter.type( commitClass ) )
			tr.registerPath( 'address', TypeRighter.type( commitClass ) )
			tr.parse( commits )
			expect( commits[ 0 ] instanceof commitClass ).toBeTruthy()

		it "should match a simple property name to all occurrences in hierarchy", ->
			tr.registerPath( 'author', TypeRighter.type( authorClass ) )
			tr.parse( commits )
			expect( commits[ 0 ].author instanceof authorClass ).toBeTruthy()
			expect( commits[ 0 ].commit.author instanceof authorClass ).toBeTruthy()

		it "should match a dot notated path name", ->
			tr.registerPath( 'commit.committer', TypeRighter.type( committerClass ) )
			tr.parse( commits )
			expect( commits[ 0 ].committer instanceof committerClass ).toBeFalsy()
			expect( commits[ 0 ].commit.committer instanceof committerClass ).toBeTruthy()

		it "should match a set of paths", ->
			tr.registerPath( [ 'avatar_url', 'url' ], TypeRighter.type( urlClass ) )
			tr.parse( commits )
			expect( commits[ 0 ].author.avatar_url instanceof urlClass ).toBeTruthy()
			expect( commits[ 0 ].author.url instanceof urlClass ).toBeTruthy()
			expect( commits[ 0 ].commit.url instanceof urlClass ).toBeTruthy()
			expect( commits[ 0 ].committer.avatar_url instanceof urlClass ).toBeTruthy()

