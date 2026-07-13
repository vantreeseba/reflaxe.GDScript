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

package haxe.ds;

// GDScript-specific override of `haxe.ds.Vector`.
//
// The cross-target implementation is backed by an `Array` and pre-sizes it in
// the constructor with `untyped this.length = length`. In GDScript, an array's
// `length` maps to the read-only native `size()`, so that assignment lowers to
// the invalid `this1.size() = length`. GDScript arrays are grown with the
// native `resize()` method instead, which is what this override uses.

private typedef VectorData<T> = Array<T>;

abstract Vector<T>(VectorData<T>) {
	/**
		Creates a new Vector of length `length`.
	**/
	public inline function new(length:Int) {
		this = [];
		this.resize(length);
	}

	/**
		Returns the value at index `index`.
	**/
	@:op([]) public inline function get(index:Int):T {
		return this[index];
	}

	/**
		Sets the value at index `index` to `val`.
	**/
	@:op([]) public inline function set(index:Int, val:T):T {
		return this[index] = val;
	}

	/**
		Returns the length of `this` Vector.
	**/
	public var length(get, never):Int;

	inline function get_length():Int {
		return this.length;
	}

	/**
		Copies `length` of elements from `src` Vector, beginning at `srcPos` to
		`dest` Vector, beginning at `destPos`.
	**/
	public static function blit<T>(src:Vector<T>, srcPos:Int, dest:Vector<T>, destPos:Int, len:Int):Void {
		if (src == dest) {
			if (srcPos < destPos) {
				var i = srcPos + len;
				var j = destPos + len;
				for (k in 0...len) {
					i--;
					j--;
					src[j] = src[i];
				}
			} else if (srcPos > destPos) {
				var i = srcPos;
				var j = destPos;
				for (k in 0...len) {
					src[j] = src[i];
					i++;
					j++;
				}
			}
		} else {
			for (i in 0...len) {
				dest[destPos + i] = src[srcPos + i];
			}
		}
	}

	/**
		Creates a new Array, copy the content from the Vector to it, and returns it.
	**/
	public function toArray():Array<T> {
		var a = new Array();
		var len = length;
		for (i in 0...len)
			a[i] = get(i);
		return a;
	}

	/**
		Extracts the data of `this` Vector.
	**/
	public inline function toData():VectorData<T>
		return cast this;

	/**
		Initializes a new Vector from `data`.
	**/
	static public inline function fromData<T>(data:VectorData<T>):Vector<T>
		return cast data;

	/**
		Creates a new Vector by copying the elements of `array`.
	**/
	static public function fromArrayCopy<T>(array:Array<T>):Vector<T> {
		var vec = new Vector<T>(array.length);
		for (i in 0...array.length)
			vec.set(i, array[i]);
		return vec;
	}

	/**
		Returns a shallow copy of `this` Vector.
	**/
	public function copy<T>():Vector<T> {
		var r = new Vector<T>(length);
		Vector.blit(cast this, 0, r, 0, length);
		return r;
	}

	/**
		Returns a string representation of `this` Vector, with `sep` separating
		each element.
	**/
	public function join<T>(sep:String):String {
		var b = new StringBuf();
		var len = length;
		for (i in 0...len) {
			b.add(Std.string(get(i)));
			if (i < len - 1) {
				b.add(sep);
			}
		}
		return b.toString();
	}

	/**
		Creates a new Vector by applying function `f` to all elements of `this`.
	**/
	public function map<S>(f:T->S):Vector<S> {
		var length = length;
		var r = new Vector<S>(length);
		for (i in 0...length) {
			var v = f(get(i));
			r.set(i, v);
		}
		return r;
	}

	/**
		Sorts `this` Vector according to the comparison function `f`.
	**/
	public inline function sort(f:T->T->Int):Void {
		this.sort(f);
	}
}
