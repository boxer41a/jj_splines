note
	description: "[
	]"
	author: "Jimmy J Johnson"
	date: "4/26/20"

class
	CUBIC_SPLINE

inherit

	ANY
		redefine
			default_create
		end

create
	make_from_array,
	make_from_function

feature {NONE} -- Initialization

	default_create
			-- Set up Current
		do
			create a.make_filled (0.0, 0, 10)
			create b.make_filled (0.0, 0, 10)
			create c.make_filled (0.0, 0, 10)
			create d.make_filled (0.0, 0, 10)
			create x.make_filled (0.0, 0, 10)
		end

	make_from_array (a_array: ARRAYED_LIST [D2_POINT])
			-- Set up Current with the control points in `a_array'
		require
			points_sorted:  -- fix me
		local
			i: INTEGER
		do
--			default_create
			spline_count := a_array.count - 1
			create a.make_filled (0.0, 0, spline_count)
			create b.make_filled (0.0, 0, spline_count)
			create c.make_filled (0.0, 0, spline_count)
			create d.make_filled (0.0, 0, spline_count)
			create x.make_filled (0.0, 0, spline_count)
			from i := 1
			until i > a_array.count
			loop
				a[i-1] := a_array[i].y
				x[i-1] := a_array[i].x
				i := i + 1
			end
			calculate
		end

	make_from_function (a_function: FUNCTION [TUPLE [REAL_64], REAL_64];
						a_count: INTEGER; a_x: REAL_64; a_step: REAL_64)
			-- Make control points using `a_function' to create ` `a_count'
			-- number of points starting at `a_x' and incrementing the x value
			-- by `a_step'.
		require
			step_big_enough: a_step > 0.0
		local
			i: INTEGER
			temp_x: REAL_64
		do
--			default_create
			spline_count := a_count - 1
			create a.make_filled (0.0, 0, spline_count)
			create b.make_filled (0.0, 0, spline_count)
			create c.make_filled (0.0, 0, spline_count)
			create d.make_filled (0.0, 0, spline_count)
			create x.make_filled (0.0, 0, spline_count)
			temp_x := a_x
			from i := 1
			until i > a_count
			loop
				a[i-1] := a_function.item (temp_x)
				x[i-1] := temp_x
				temp_x := temp_x + a_step
				i := i + 1
			end
			check
				a_correct_count: a.count = a_count
				x_correct_count: x.count = a_count
			end
			calculate
		end

feature -- Access

	spline_count: INTEGER
			-- The number of cubic polynomials defined by Current.
			-- This is one less than the number of control points.

	control_points: ARRAYED_LIST [D2_POINT]
			-- A copy of Current's control points
		local
			i: INTEGER
		do
			create Result.make (spline_count + 1)
			from i := 0
			until i > spline_count
			loop
				Result.extend ([x[i], a[i], 0.0])
				i := i + 1
			end
		end

feature -- Query

	y_value (a_x: REAL_64): REAL_64
			-- The y-value of the point on Current corresponding to `a_x'.
		require
--			x_big_enough: a_x >= x[0]
--			x_small_enough: a_x <= x[spline_count + 1]
		local
			i, j: INTEGER
			found: BOOLEAN
			x_dif: REAL_64
			fd: FORMAT_DOUBLE
		do
				-- Find the correct interval.
				-- Coudd use binary search with a little work.
			from i := 0
			until i > spline_count or found
			loop
				found := x[i] >= a_x
				i := i + 1
			end
			check
				was_found: found
					-- because of precondition
--				before_next_point: a_x <= x[i]
			end
				-- Now we know which interval to use based on `i'.
			j := i - 1
			create fd.make (4, 2)
io.putstring ("For point 'a_x' = " + fd.formatted (a_x) + ", using interval number " + j.out + "%N")
			x_dif := a_x - x[j]
			Result := a[j] + b[j] * x_dif + c[j] * (x_dif^2) + d[j] * (x_dif^3)
		end


feature {NONE} -- Implementation

	calculate
			-- Find the remaining values for each spline (i.e. fill the `b',
			-- `c', and `d' arrays for use in spline equation.
		local
			i, j: INTEGER
			n: INTEGER
			h, alpha: ARRAY [REAL_64]
			l, mu, z: ARRAY [REAL_64]
		do
			n := spline_count
				-- 3) Find values for `h' array
			create h.make_filled (0.0, 0, n - 1)
			from i := 0
			until i > n - 1
			loop
				h[i] := x[i+1] - x[i]
				i := i + 1
			end
				-- 4) Find values for `alpha' array
			create alpha.make_filled (0.0, 0, n - 1)
			from i := 1
			until i > n - 1
			loop
				alpha[i] := (3/h[i] * (a[i+1] - a[i])) - (3/h[i-1] * (a[i] - a[i-1]))
				i := i + 1
			end
				-- 5) Create new arrays `c', `l', `mu', and `z' of size n + 1.
				-- 6) Set `l'[0] = 1 and set `mu'[0] and `z'[0] = 0.
			create l.make_filled (0.0, 0, n + 1)
			create mu.make_filled (0.0, 0, n + 1)
			create z.make_filled (0.0, 0, n + 1)
			l[0] := 1.0
				-- 7) For i = 1,...,n - 1  ... fill the above arrays
			from i := 1
			until i > n - 1
			loop
				l[i] := 2 * (x[i+1] - x[i-1]) - (h[i-1] * mu[i-1])
				mu[i] := h[i] / l[i]
				z[i] := (alpha[i] - h[i-1] * z[i-1]) / l[i]
				i := i + 1
			end
				-- 8) Set l[n] = 1
			l[n] := 1.0
				-- 8) and z[n], and c[n] = 0.  (Accomplished already)
				-- 9) For j = n - 1, n - 2, ... , 0 fill c, b, and d arrays
			from j := n - 1
			until j < 0
			loop
				c[j] := z[j] - mu[j] * c[j+1]
				b[j] := ((a[j+1] - a[j]) / h[j]) - (h[j] * (c[j+1] + 2 * c[j]) / 3)
				d[j] := (c[j+1] - c[j]) / (3 * h[j])
				j := j - 1
			end
		end

feature {NONE} -- Implemenation - https://en.wikipedia.org/wiki/Spline_(mathematics)

	a: ARRAY [REAL_64]
		-- Holds the a values used in spline equation.
		-- A copy of the "y" coordinates of the control points.

	b: ARRAY [REAL_64]
		-- Holds the "b" values used in spline equation

	c: ARRAY [REAL_64]
		-- Holds the "c" values used in spline equation

	d: ARRAY [REAL_64]
		-- Holds the "d" vales used in spline equation

	x: ARRAY [REAL_64]
		-- Holds the "x" values of the control points used in spline equation.

invariant

	c_array_size_correct: c.count = spline_count + 1
	d_array_size_correct: d.count = spline_count + 1

end
