[
// To process with sphinxifier.lasso, run:
// LASSO9_RETAIN_COMMENTS=1 LASSO9_NO_INTERPRETER=1 lasso9 sphinxifier.lasso doccomment.lasso

/**!
	This is a test doc comment for unbound methods
	@param in1 can only be string
	@param in2 can be anything
	@param more other parameters
	@return a value
	@see www.example.com
	@note Arbitrary tags are also supported
*/
define test_method(in1::string, in2, ...more)::string => {return #in1}

/**!
	This is a test doc comment for traits
	@see www.example.com
*/
define test_trait => trait {
	import trait_asString
	import trait_frontEnded

	/**!
		This is a test doc comment for requires
		@param in1 can only be string
		@param in2 can be anything
		@param ... other parameters
		@return a value
		@see www.example.com
	*/
	require test_require(in1::string, in2, ...)

	/**!
		This is a test doc comment for provides
		@param in1 can only be string
		@param in2 can be anything
		@param rest other parameters
		@return a value
		@see www.example.com
	*/
	provide test_provide(in1::string, in2, ...) => {}
}


/**!
	This is a test doc comment for types
	@see www.example.com
*/
define test_type => type {
	parent tree_base
	trait {
		import trait_map, trait_queriable, trait_serializable
		/**!
			This is a test doc comment for provides inside a trait block
			@param in1 can only be string
			@param in2 can be anything
			@return a value
			@see www.example.com
		*/
		provide test_provide2(in1::string, in2) => ''
	}

	data private sa, private size
	
	/**!
		This is a test doc comment for member methods
		@param in1 optional, can only be string
		@param in2 optional, can be anything
		@param in3 optional keyword param
		@return a value
		@see www.example.com
	*/
	public onCreate(in1::string='anything', in2='anything', -in3=false)::any => {
		return #in2
	}
	
	public asString::string => ''
}

/**!
	This is a test doc comment for member methods added later
	@param in1 can only be string
	@param in2 can be anything
	@param -in3 required keyword param
	@return a value
	@see www.example.com
*/
define test_type->addedLater(in1::string, in2, -in3) => (:)

]