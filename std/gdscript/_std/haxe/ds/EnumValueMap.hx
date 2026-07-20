package haxe.ds;

/**
	GDScript implementation of `haxe.ds.EnumValueMap`.

	The shared implementation compares keys through `EnumValue.getIndex()` and
	`EnumValue.getParameters()`, which are `haxe.EnumTools` sugar for `Type`.
	GDScript has no `Type` global and reflaxe.GDScript emits no runtime for it,
	so the shared version generates `Type.enumIndex(...)` and a parameter of type
	`EnumValue` — neither of which exists in GDScript, and the whole script then
	fails to parse.

	It does not need reflection here, because the compiled representation is
	directly inspectable. `EnumCompiler` emits an enum constructor that carries
	arguments as a Dictionary — `{ "_index": N, "argName": value, … }` — and a
	data-less enum as a plain GDScript `enum`, i.e. an int. So:

	- two Dictionaries compare on `_index` first, then argument-wise in
	  declaration order (Dictionary preserves insertion order in GDScript, and
	  `EnumCompiler` emits arguments in declaration order);
	- anything else is an int and falls through to `Reflect.compare`.

	This preserves the documented contract — keys compared by value, recursively
	over their parameters, with `Reflect.compare` for non-enum parameters.
**/
class EnumValueMap<K:EnumValue, V> extends haxe.ds.BalancedTree<K, V> implements haxe.Constraints.IMap<K, V> {
	override function compare(k1:K, k2:K):Int {
		return compareValues(k1, k2);
	}

	/**
		Orders two compiled enum values.

		@param v1 The left value; a Dictionary for constructors with arguments,
		otherwise an int.
		@param v2 The right value.
		@return A negative number, zero, or a positive number as `v1` sorts
		before, equal to, or after `v2`.
	**/
	static function compareValues(v1:Dynamic, v2:Dynamic):Int {
		if (!isDict(v1) || !isDict(v2)) {
			return Reflect.compare(v1, v2);
		}

		var d = (untyped __gdscript__("{0}[\"_index\"]", v1) : Int) - (untyped __gdscript__("{0}[\"_index\"]", v2) : Int);
		if (d != 0) {
			return d;
		}

		var a1:Array<Dynamic> = untyped __gdscript__("Array({0}.values())", v1);
		var a2:Array<Dynamic> = untyped __gdscript__("Array({0}.values())", v2);
		return compareArgs(a1, a2);
	}

	/**
		Orders two argument lists element-wise, shorter list first on a length
		mismatch. The `_index` entry sits at position 0 of both and has already
		been compared, so it always ties.
	**/
	static function compareArgs(a1:Array<Dynamic>, a2:Array<Dynamic>):Int {
		var ld = a1.length - a2.length;
		if (ld != 0) {
			return ld;
		}
		for (i in 0...a1.length) {
			var d = compareArg(a1[i], a2[i]);
			if (d != 0) {
				return d;
			}
		}
		return 0;
	}

	static function compareArg(v1:Dynamic, v2:Dynamic):Int {
		return if (isDict(v1) && isDict(v2)) {
			compareValues(v1, v2);
		} else if (isArray(v1) && isArray(v2)) {
			compareArgs(v1, v2);
		} else {
			Reflect.compare(v1, v2);
		}
	}

	static inline function isDict(v:Dynamic):Bool {
		return untyped __gdscript__("({0} as Variant) is Dictionary", v);
	}

	static inline function isArray(v:Dynamic):Bool {
		return untyped __gdscript__("({0} as Variant) is Array", v);
	}

	override function copy():EnumValueMap<K, V> {
		var copied = new EnumValueMap<K, V>();
		copied.root = root;
		return copied;
	}
}
