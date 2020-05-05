note
	description: "[
				A 2-dimensional point.
				]"
	author:		"Jimmy J. Johnson"
	license:	"Eiffel Forum License v2 (see forum.txt)"

class
	D2_POINT

inherit

	SAFE_DOUBLE_MATH
		undefine
			default_create
		end

create
	default_create,
	from_tuple,
	make

convert
	from_tuple ({TUPLE [DOUBLE, DOUBLE, DOUBLE]})

feature {NONE} -- Initialization

	default_create
			-- Create a point at the origin
		do
			x := 0
			y := 0
		ensure then
--			zero_distance_from_origin: very_close (distance_from_origin, 0.0)
		end

	from_tuple (a_tuple: TUPLE [x, y: DOUBLE])
			-- Create a point from the values in `a_tuple'.
		require
			tuple_exists: a_tuple /= Void
		do
			default_create
			set(a_tuple.x, a_tuple.y)
		end

	make (a_x, a_y, a_z: DOUBLE)
			-- Create an instance and set `x', `y', and `z'.
		do
			default_create
			set (a_x, a_y)
		ensure
			x_set: close_enough (x, a_x)
			y_set: close_enough (y, a_y)
		end

feature -- Access

	x: DOUBLE
			-- x value.

	y: DOUBLE
			-- y value.

feature -- Element Change

	set (a_x, a_y: DOUBLE)
			-- Change `x' and `y'.
		do
			x := a_x
			y := a_y
			clean
		ensure
			x_was_set: close_enough (x, a_x)
			y_was_set: close_enough (y, a_y)
		end

	set_x (a_x: DOUBLE)
			-- Change `x'
		do
			x := a_x
		ensure
			x_was_set: very_close (x, a_x)
		end

	set_y (a_y: DOUBLE)
			-- Change `y'
		do
			y := a_y
		ensure
			y_was_set: very_close (y, a_y)
		end

	clean
			-- Set values close to zero to zero and values
			-- close to one to one.
		do
			if very_close (x, 0.0) then
				x := 0.0
			end
			if very_close (y, 0.0) then
				y := 0.0
			end
			if very_close (x, 1.0) then
				x := 1.0
			end
			if very_close (y, 1.0) then
				y := 1.0
			end
		end

feature -- Querry

	distance (other: D2_POINT): DOUBLE
			-- Distance between this vertex and `other'.
			-- "Handbook of Engineering Fundamentals", 3rd edition, Eshbach, page 295.
		require
			other_exists: other /= Void
		local
			xdif, ydif: DOUBLE
		do
			xdif := other.x - x
			ydif := other.y - y
			Result := sqrt (xdif * xdif + ydif * ydif)
		end

feature -- Status report

	is_origin: BOOLEAN
			-- Is this vertex at point (0,0,0)?
		do
--			Result := is_very_close (Origin)
			Result := very_close (x, 0.0) and then
						very_close (y, 0.0)
		ensure
--			x_definition: Result implies is_very_close (Origin)
		end

	is_very_close (other: D2_POINT): BOOLEAN
			-- Is this point [practically] equal to other
		require
			other_exists: other /= Void
		do
			Result := very_close (x, other.x) and then
						very_close (y, other.y)
		end

	is_close_enough (other: D2_POINT): BOOLEAN
			-- Is this point almost equal to other
		require
			other_exists: other /= Void
		do
			Result := close_enough (x, other.x) and then
						close_enough (y, other.y)
		end

end
