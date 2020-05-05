note
	description: "[
		Routines for finding the numerical precision of a platform and routines
		for comparing DOUBLEs to acount for rounding errors, and overflow.
		These features were adapted from "Object-Oriented Implementation of
		Numerical Methods" by Didier H. Besset; ISBN: 1-55860-679-3" as inspired
		by Steven M. Wurster.

		The equations for the comparison features are from "The Art of Computer
		Programming (Vol II), by Knuth.  Paraphasing "for given floating point
		values `u' and `v' and a tolerance `e':
			|u - v| <= e * |u| and |u - v| <= e * |v|		(1)
		describes a *very close* relationship;
		equation
			|u - v| <= e * |u| or |u - v| <= e * |v|		(2)
		describes a *close enough" relatinship."
		To prevent underflow (or overflow?) in the multiplication of the right side
		of the inequalities, features `very_close' and `close_enough' are
		modified by replacing the multiplication on the right with a division on
		the left.
			|u - v| / |u| <= e and |u - v| / |v| <= e		(1')
		and
			|u - v| / |u| <= e or |u - v| / |v| <= e		(2')

		It is tempting to try to use generic types for this class with constrained
		generic parameters, such as SAFE_MATH [G -> {NUMERIC, COMPARABLE}], but
		this does not work:  1) cannot use once features with anchored or generic
		types, 2) some numeric classes do not have all the required features (e.g.
		NATURAL_xx does not have feature `abs' or `negate').  Also, with 64-bit
		computing do we really need a REAL_32 version?
		]"
	date: "21 Apr 06"
	author:		"Jimmy J. Johnson"
	copyright:	"Copyright 2009, Jimmy J. Johnson"

class
	SAFE_DOUBLE_MATH

inherit

	DOUBLE_MATH

feature -- Access

	precision: DOUBLE
			-- Largest positive number that, when added to 1, yields 1.
		local
			tmp: DOUBLE
			test: DOUBLE
		once
			from
				Result := One
				tmp := One + Result
			until
				tmp - One = Zero
			loop
				Result := Result * inverse_radix
				tmp := One + Result
			end
			test := One + Result
			check
				definition_check: test = One
			end
		ensure
			positive: Result > 0
			definition: One + Result = One
		end

	negative_precision: DOUBLE
			-- Largest positive number that, when subtracted from 1, yields 1.
		local
			tmp: DOUBLE
			test: DOUBLE
		once
			from
				Result := One
				tmp := One - Result
			until
				tmp - One = Zero
			loop
				Result := Result * inverse_radix
				tmp := One - Result
			end
			test := One - Result
		ensure
			positive: Result > 0
			definition: One - Result = One
		end

	largest: DOUBLE
			-- Largest positive number representable by system.
		local
			tmp: DOUBLE
		once
			from
				tmp := full_mantissa
				Result := tmp
			until
				is_infinite (tmp)
			loop
				Result := tmp
				tmp := tmp * radix
			end
		ensure
			positive: Result > Zero
		end

	smallest: DOUBLE
			-- Smallest non-zero, positive number representable by system.
		local
			tmp: DOUBLE
		once
			from
				tmp := full_mantissa
				Result := full_mantissa
			until
				tmp = Zero
			loop
				Result := tmp
				tmp := tmp * inverse_radix
			end
		ensure
			positive: Result > Zero
		end

	small_number: DOUBLE
			-- Number that can be added to some value without noticably changing
			-- the result of the computation.
		once
			Result := sqrt (Smallest)
		ensure
			result_large_enough: Result > zero
			definition: very_close (zero + Result, zero)
		end

	default_tolerance: DOUBLE
			-- Relative precision that can be expected for a general numerical computation.
			-- Name changed from "default_precision" to "default_tolerance".
		once
			Result := sqrt (precision)
		ensure
			result_large_enough: Result > zero
		end

	limited_value (x: DOUBLE): DOUBLE
			-- The value `x', limited so that it is no less then a non-zero value that
			-- will not significantly change the result of numerical computations.
			-- Should be used as a protection against small factors.
			-- This feature supplied by Steven M. Wurster.
		do
			Result := x
			if x.abs < small_number then
				Result := small_number
				if x < 0 then
					Result := -Result
				end
			end
		ensure
			non_zero_result: not very_close (Result, zero)
			result_big_enough: Result.abs >= small_number
			too_small_definition: x.abs <= small_number implies very_close (Result, small_number)
			not_small_definition: x.abs > small_number implies very_close (Result, x)
			positive_sign_unchanged: x > zero implies Result > zero
			negative_sign_unchanged: x < zero implies Result < zero
		end

	one: DOUBLE = 1.0
			-- The double value 1.0

	zero: DOUBLE = 0.0
			-- The double value 0.0

	infinity: DOUBLE
			-- The floating point representation of a number too
			-- large to represent on this system.
		once
				-- Use a really big number to ensure an overflow.
				-- This number was obtained by trial and error using
				-- earlier versions of feature `largest'.
			Result := 8.9884656743115785e307 * 8.9884656743115785e307
				-- Do not be temped to use the following line; `largest' is
				-- defined in terms of `infinity', so it will not stop.
			-- Result := largest * largest
		end

	undefined: DOUBLE
			-- The floating point representation of a divide by zero error.
		local
			d: DOUBLE
		once
				-- Divide by zero.
			Result := d / d
		end

feature -- Query

	inverse_square_root (a_value: DOUBLE): DOUBLE
			-- Feature added to align with "Essential Mathimatics for Games,
			-- Verth & Bishop, 2004, p 27.
		require
			value_non_negative: a_value > 0.0
		do
			Result := 1.0 / sqrt (a_value)
		ensure
			definition: very_close (Result, 1.0 / sqrt (a_value))
		end

	very_close (a_first, a_second: DOUBLE): BOOLEAN
			-- Is `a_first' and `a_second' "very close" to each other
			-- with `Default_tolerence'?
		do
			Result := very_close_with_tolerance (a_first, a_second, Default_tolerance)
		ensure
			definition: Result implies very_close_with_tolerance (a_first, a_second, Default_tolerance)
		end

	close_enough (a_first, a_second: DOUBLE): BOOLEAN
			-- Is `a_first' and `a_second' "close enough" to each other
			-- with `Default_tolerence'?
		do
			Result := close_enough_with_tolerance (a_first, a_second, Default_tolerance)
		ensure
			definition: Result implies close_enough_with_tolerance (a_first, a_second, Default_tolerance)
		end

	very_close_with_tolerance (a_first, a_second: DOUBLE; a_epsilon: DOUBLE): BOOLEAN
			-- Is `a_first' and `a_second' "very close" to each other
			-- with `Default_tolerence'?
		do
			Result := first_quotient (a_first, a_second) <= a_epsilon and then
						second_quotient (a_first, a_second) <= a_epsilon
		ensure
			definition: Result implies first_quotient (a_first, a_second) <= a_epsilon and then
										second_quotient (a_first, a_second) <= a_epsilon
		end

	close_enough_with_tolerance (a_first, a_second: DOUBLE; a_epsilon: DOUBLE): BOOLEAN
			-- Is `a_first' and `a_second' "close enough" to each other
			-- with `a_epsilon' tolerence?
		do
			Result := first_quotient (a_first, a_second) <= a_epsilon or else
						second_quotient (a_first, a_second) <= a_epsilon
		ensure
			definition: Result implies first_quotient (a_first, a_second) <= a_epsilon or else
										second_quotient (a_first, a_second) <= a_epsilon
		end

	is_infinite (a_value: DOUBLE): BOOLEAN
			-- Does `a_value' represent a number that is infinite?
			-- Relies on the use of `a_value' in an expression to cause a
			-- "floating point exception" and if so returns True.
		do
			Result := a_value = Infinity
		end

feature {NONE} -- Implementation

	radix: INTEGER
			-- Radix used in machine's representation of floating-point numbers.
			-- A floating point number is represented as "Mantissa x Radix ^ Exponent".
		local
			a, b: DOUBLE
			tmp1, tmp2: DOUBLE
		once
			from
				a := One
			until
				tmp2 - One = Zero
			loop
				a := a + a
				tmp1 := a + One
				tmp2 := tmp1 - a
			end
			from
				b := One
			until
				Result /= Zero
			loop
				b := b + b
				tmp1 := a + b
				Result := (tmp1 - a).truncated_to_integer
			end
		ensure
			valid_result: Result >= 2
		end

	inverse_radix: DOUBLE
			-- The reciprocal of `radix'
		require
			valid_radix: radix >= 2
		once
			Result := One / radix
		ensure
			definition: Result = One / radix
		end

	full_mantissa: DOUBLE
			-- Helper function for some of the computations.
		once
			Result := One - radix * negative_precision
		end

	first_quotient (u, v: DOUBLE): DOUBLE
			-- The first quotient in equation (1') and (2').  (See header comments.)
		do
			if u = v then
				Result := Zero
			elseif v = Zero then
				Result := (Zero - u).abs
			else
				Result := (u - v).abs / u.abs
			end
		end

	second_quotient (u, v: DOUBLE): DOUBLE
			-- The first quotient in equation (1') and (2').  (See header comments.)
		do
			if u = v then
				Result := Zero
			elseif v = Zero then
				Result := (Zero - u).abs
			else
				Result := (u - v).abs / v.abs
			end
		end

--	safe_divide (a_dividend, a_divisor: DOUBLE): DOUBLE is
--			-- Divide `a_dividend' by `a_devisor' while preventing overflow.
--		local
--			a, b: DOUBLE
--		do
--			if a_divisor = 0 then
--				a := a_divisor
--				b := a_dividend
--			else
--				a := a_dividend
--				b := a_divisor
--			end
--			if b < 1 and then a > b * Largest then
--				Result := Largest
--			elseif (b > 1 and a < b * Smallest) or else
--					(a_dividend = 0) then
--				Result := 0
--			else
--				Result := a / b
--			end
--		end

end
