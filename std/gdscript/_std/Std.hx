package;

extern class Std {
	@:deprecated('Std.is is deprecated. Use Std.isOfType instead.')
	@:runtime public inline static function is(v: Dynamic, t: Dynamic): Bool return isOfType(v, t);

	@:nativeFunctionCode("(({arg0} as Variant) is {arg1})")
	public static function isOfType(v: Dynamic, t: Dynamic): Bool;

	@:deprecated('Std.instance() is deprecated. Use Std.downcast() instead.')
	@:runtime public inline static function instance<T: {}, S: T>(value: T, c: Class<S>): S return downcast(value, c);

	@:nativeFunctionCode("({arg0} as {arg1})")
	public static function downcast<T: {}, S: T>(value: T, c: Class<S>): S;

	@:native("str")
	public static function string(s: Dynamic): String;

	@:native("int")
	public static function int(x: Float): Int;

	@:nativeFunctionCode("{arg0}.to_int()")
	public static function parseInt(x: String): Null<Int>;

	@:nativeFunctionCode("{arg0}.to_float()")
	public  static function parseFloat(x: String): Float;

	// `floori`, not `floor`: GDScript's `floor()` is Variant-typed and returns a
	// float, so `Std.random` handed back a float despite being declared `Int`.
	// Everything downstream then failed on a type it was told to expect as int —
	// `<<` rejects float operands outright, and an `Array[int]` refuses the
	// element. `floori` is the int-returning variant and matches Haxe's contract
	// of an Int in [0, x).
	@:nativeFunctionCode("floori(randf() * {arg0})")
	public static function random(x: Int): Int;
}
