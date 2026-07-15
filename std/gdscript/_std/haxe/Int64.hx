/*
 * Copyright (C)2005-2019 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package haxe;

using haxe.Int64;

import haxe.Int64Helper;

/*
 * GDScript's `int` is a native 64-bit signed integer, so `haxe.Int64` maps
 * directly onto it — no high/low emulation. The stock cross-platform Int64
 * emulates 64-bit words with two 32-bit Haxe `Int`s and relies on Int being
 * 32-bit (arithmetic wrapping, `>>>` as a 32-bit unsigned shift). On GDScript
 * `Int` is already 64-bit, so that emulation silently drifts out of its 32-bit
 * lanes and produces wrong results. This override replaces it with native
 * 64-bit arithmetic, mirroring the C#/Java/HL `_std` overrides that use their
 * platform's native 64-bit integer.
 *
 * The underlying is exposed through a `typedef __Int64`, matching the private
 * name the stock `haxe.Int64` gives its own underlying (`typedef __Int64 =
 * ___Int64`). `@:coreApi` compares an instance method's receiver (`this`) type
 * by the *typedef's* module path, so the HL/C#/Java overrides all alias their
 * native type to a `typedef __Int64` to "fool" the check (see the comment in the
 * stock file); a plain abstract named `__Int64` is a different kind of type and
 * fails to unify. So the real backing is a distinct abstract over `Int` (not
 * `Int` itself, so the abstract's implicit `from Int` does not collide with the
 * `@:from ofInt(Int)` conversion — same reason the native targets use a
 * dedicated `hl.I64` / `java.StdTypes.Int64`), surfaced via `typedef __Int64`.
 */
private abstract Native64(Int) from Int to Int {
	public inline function new(x:Int)
		this = x;
}

private typedef __Int64 = Native64;

@:coreApi
@:transitive
abstract Int64(__Int64) from __Int64 to __Int64 {
	private inline function new(x:__Int64)
		this = x;

	private var val(get, set):__Int64;

	inline function get_val():__Int64
		return this;

	inline function set_val(x:__Int64):__Int64
		return this = x;

	public var high(get, never):Int32;

	// Arithmetic shift of the native 64-bit value yields the signed high word.
	inline function get_high():Int32
		return (this : Int) >> 32;

	// Replace the high 32 bits, preserving the low 32. Only used by
	// `haxe.io.FPHelper` (via @:privateAccess) when building an Int64 out of a
	// double's bit pattern. The low-word mask must be a real 0xffffffff; written
	// in Haxe it folds to -1 (32-bit Int), so inject the GDScript expression.
	inline function set_high(x:Int32):Int32 {
		this = (untyped __gdscript__("(({0}) << 32) | (({1}) & 0xffffffff)", x, (this : Int)) : Int);
		return x;
	}

	public var low(get, never):Int32;

	// Isolate the low 32 bits as a *signed* Int32: shift them up to the top of
	// the 64-bit word, then arithmetic-shift back down to sign-extend from bit
	// 31. Uses only native 64-bit shifts (no 0xffffffff literal, which Haxe's
	// 32-bit frontend would fold to -1).
	inline function get_low():Int32
		return ((this : Int) << 32) >> 32;

	// Replace the low 32 bits, preserving the high 32. See `set_high`.
	inline function set_low(x:Int32):Int32 {
		this = (untyped __gdscript__("((({0}) >> 32) << 32) | (({1}) & 0xffffffff)", (this : Int), x) : Int);
		return x;
	}

	public inline function copy():Int64
		return new Int64(this);

	// (high << 32) | (low & 0xffffffff). The low-word mask must be a real
	// 0xffffffff; written in Haxe it folds to -1 (32-bit Int), so inject the
	// GDScript expression directly to keep the mask 64-bit-correct.
	public static inline function make(high:Int32, low:Int32):Int64
		return new Int64((untyped __gdscript__("(({0}) << 32) | (({1}) & 0xffffffff)", high, low) : Int));

	@:from public static inline function ofInt(x:Int):Int64
		return new Int64(x);

	public static inline function toInt(x:Int64):Int {
		if (x.high != x.low >> 31)
			throw "Overflow";
		return x.low;
	}

	@:deprecated('haxe.Int64.is() is deprecated. Use haxe.Int64.isInt64() instead')
	inline public static function is(val:Dynamic):Bool
		return isInt64(val);

	inline public static function isInt64(val:Dynamic):Bool
		return Std.isOfType(val, Int);

	public static inline function getHigh(x:Int64):Int32
		return x.high;

	public static inline function getLow(x:Int64):Int32
		return x.low;

	public static inline function isNeg(x:Int64):Bool
		return (x.val : Int) < 0;

	public static inline function isZero(x:Int64):Bool
		return (x.val : Int) == 0;

	public static inline function compare(a:Int64, b:Int64):Int {
		if ((a.val : Int) < (b.val : Int))
			return -1;
		if ((a.val : Int) > (b.val : Int))
			return 1;
		return 0;
	}

	public static inline function ucompare(a:Int64, b:Int64):Int {
		if ((a.val : Int) < 0)
			return (b.val : Int) < 0 ? compare(a, b) : 1;
		return (b.val : Int) < 0 ? -1 : compare(a, b);
	}

	public static inline function toStr(x:Int64):String
		return '${(x.val : Int)}';

	public static inline function divMod(dividend:Int64, divisor:Int64):{quotient:Int64, modulus:Int64}
		return {quotient: dividend / divisor, modulus: dividend % divisor};

	private inline function toString():String
		return '${(this : Int)}';

	public static function parseString(sParam:String):Int64 {
		return Int64Helper.parseString(sParam);
	}

	public static function fromFloat(f:Float):Int64 {
		return Int64Helper.fromFloat(f);
	}

	@:op(-A) public static inline function neg(x:Int64):Int64
		return new Int64(-(x.val : Int));

	@:op(++A) private inline function preIncrement():Int64
		return this = new Int64((this : Int) + 1);

	@:op(A++) private inline function postIncrement():Int64 {
		final ret = new Int64(this);
		this = new Int64((this : Int) + 1);
		return ret;
	}

	@:op(--A) private inline function preDecrement():Int64
		return this = new Int64((this : Int) - 1);

	@:op(A--) private inline function postDecrement():Int64 {
		final ret = new Int64(this);
		this = new Int64((this : Int) - 1);
		return ret;
	}

	@:op(A + B) public static inline function add(a:Int64, b:Int64):Int64
		return new Int64((a.val : Int) + (b.val : Int));

	@:op(A + B) @:commutative private static inline function addInt(a:Int64, b:Int):Int64
		return new Int64((a.val : Int) + b);

	@:op(A - B) public static inline function sub(a:Int64, b:Int64):Int64
		return new Int64((a.val : Int) - (b.val : Int));

	@:op(A - B) private static inline function subInt(a:Int64, b:Int):Int64
		return new Int64((a.val : Int) - b);

	@:op(A - B) private static inline function intSub(a:Int, b:Int64):Int64
		return new Int64(a - (b.val : Int));

	@:op(A * B) public static inline function mul(a:Int64, b:Int64):Int64
		return new Int64((a.val : Int) * (b.val : Int));

	@:op(A * B) @:commutative private static inline function mulInt(a:Int64, b:Int):Int64
		return new Int64((a.val : Int) * b);

	@:op(A / B) public static inline function div(a:Int64, b:Int64):Int64
		return new Int64(Std.int((a.val : Int) / (b.val : Int)));

	@:op(A / B) private static inline function divInt(a:Int64, b:Int):Int64
		return new Int64(Std.int((a.val : Int) / b));

	@:op(A / B) private static inline function intDiv(a:Int, b:Int64):Int64
		return new Int64(Std.int(a / (b.val : Int)));

	@:op(A % B) public static inline function mod(a:Int64, b:Int64):Int64
		return new Int64((a.val : Int) % (b.val : Int));

	@:op(A % B) private static inline function modInt(a:Int64, b:Int):Int64
		return new Int64((a.val : Int) % b);

	@:op(A % B) private static inline function intMod(a:Int, b:Int64):Int64
		return new Int64(a % (b.val : Int));

	@:op(A == B) public static inline function eq(a:Int64, b:Int64):Bool
		return (a.val : Int) == (b.val : Int);

	@:op(A == B) @:commutative private static inline function eqInt(a:Int64, b:Int):Bool
		return (a.val : Int) == b;

	@:op(A != B) public static inline function neq(a:Int64, b:Int64):Bool
		return (a.val : Int) != (b.val : Int);

	@:op(A != B) @:commutative private static inline function neqInt(a:Int64, b:Int):Bool
		return (a.val : Int) != b;

	@:op(A < B) private static inline function lt(a:Int64, b:Int64):Bool
		return (a.val : Int) < (b.val : Int);

	@:op(A < B) private static inline function ltInt(a:Int64, b:Int):Bool
		return (a.val : Int) < b;

	@:op(A < B) private static inline function intLt(a:Int, b:Int64):Bool
		return a < (b.val : Int);

	@:op(A <= B) private static inline function lte(a:Int64, b:Int64):Bool
		return (a.val : Int) <= (b.val : Int);

	@:op(A <= B) private static inline function lteInt(a:Int64, b:Int):Bool
		return (a.val : Int) <= b;

	@:op(A <= B) private static inline function intLte(a:Int, b:Int64):Bool
		return a <= (b.val : Int);

	@:op(A > B) private static inline function gt(a:Int64, b:Int64):Bool
		return (a.val : Int) > (b.val : Int);

	@:op(A > B) private static inline function gtInt(a:Int64, b:Int):Bool
		return (a.val : Int) > b;

	@:op(A > B) private static inline function intGt(a:Int, b:Int64):Bool
		return a > (b.val : Int);

	@:op(A >= B) private static inline function gte(a:Int64, b:Int64):Bool
		return (a.val : Int) >= (b.val : Int);

	@:op(A >= B) private static inline function gteInt(a:Int64, b:Int):Bool
		return (a.val : Int) >= b;

	@:op(A >= B) private static inline function intGte(a:Int, b:Int64):Bool
		return a >= (b.val : Int);

	@:op(~A) private static inline function complement(x:Int64):Int64
		return new Int64(~(x.val : Int));

	@:op(A & B) public static inline function and(a:Int64, b:Int64):Int64
		return new Int64((a.val : Int) & (b.val : Int));

	@:op(A | B) public static inline function or(a:Int64, b:Int64):Int64
		return new Int64((a.val : Int) | (b.val : Int));

	@:op(A ^ B) public static inline function xor(a:Int64, b:Int64):Int64
		return new Int64((a.val : Int) ^ (b.val : Int));

	@:op(A << B) public static inline function shl(a:Int64, b:Int):Int64
		return new Int64((a.val : Int) << (b & 63));

	@:op(A >> B) public static inline function shr(a:Int64, b:Int):Int64
		return new Int64((a.val : Int) >> (b & 63));

	// Logical (zero-fill) 64-bit right shift. GDScript has no `>>>`; mask off the
	// bits arithmetic shift would sign-extend. `b & 63` normalizes the amount and
	// keeps it runtime (not a folded constant), so `1 << (64 - b)` is evaluated
	// as native 64-bit at runtime rather than folded by the 32-bit frontend.
	@:op(A >>> B) public static inline function ushr(a:Int64, b:Int):Int64 {
		final n = b & 63;
		return new Int64(n == 0 ? (a.val : Int) : (((a.val : Int) >> n) & ((1 << (64 - n)) - 1)));
	}
}
