note
	description: "[
		Tester and demo for spline interpolation classes
		]"
	author: "Jimmy J Johnson"
	date: "4/26/20"

class
	SPLINE_TESTER

inherit

	DOUBLE_MATH

create
	make

feature {NONE} -- Initialization

	make
			-- Run application.
		do
			create spline.make_from_array (test_points)
--			create spline.make_from_function (agent function, 10, 1.0, 1.0)
			io.put_string ("%N%N%N%N%N%N%N%N")
			io.put_string ("Begin Cubic Spline demo/tester. %N")
			run_test
			find_points
			io.put_string ("End test. %N")
		end

feature -- Basic operations

	run_test
			-- Run a test
		local
			f: PLAIN_TEXT_FILE
			lin: LINEAR [D2_POINT]
		do
				-- Make and open the file for control points
			create f.make_open_write ("control_points.txt")
			lin := spline.control_points
			from lin.start
			until lin.exhausted
			loop
				io.put_string ("[" + lin.item.x.out + ", " + lin.item.y.out + "] %N")
				f.put_double (lin.item.x)
				f.put_string (" ")
				f.put_double (lin.item.y)
				f.put_string ("%N")
				lin.forth
			end
		end

	find_points
			-- Get a set of points for the curve
		local
			x, d, y: REAL_64
			f: PLAIN_TEXT_FILE
			fd: FORMAT_DOUBLE
		do
			create fd.make (4, 2)
			create f.make_open_write ("points.txt")
			d := 0.1
			from x := test_points.first.x
			until x > test_points.last.x
			loop
				y := spline.y_value (x)
				io.put_string ("[" + fd.formatted (x) + ", " + fd.formatted (y) + "]   ")
				f.put_string (fd.formatted (x))
				f.put_string ("    ")
				f.put_string (fd.formatted (y))
				f.put_string ("%N")
				x := x + d
			end
			io.put_string ("%N")
		end

feature {NONE} -- Implementation

	test_points: ARRAYED_LIST [D2_POINT]
		do
			create Result.make (10)
			Result.extend ([2.0, 2.0, 0.0])
			Result.extend ([4.0, 3.0, 0.0])
			Result.extend ([6.0, 5.0, 0.0])
			Result.extend ([7.0, 4.0, 0.0])
			Result.extend ([8.5, 6.0, 0.0])
		end

	function (a_x: REAL_64): REAL_64
			-- Test function for producing the control points for `spline'
		do
			Result := (a_x * a_x) - (4 * a_x) + 1
		end

	spline: CUBIC_SPLINE
			-- Object for testing

end
