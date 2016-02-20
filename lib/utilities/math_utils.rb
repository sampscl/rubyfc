module Paidgeeks
  module_function 
  TWOPI = 2.0*Math::PI
  TWOPI_OVER_360 = TWOPI/360.0
  TWOPI_UNDER_360 = 360.0/TWOPI

  def deg_to_rad(deg)
    deg * TWOPI_OVER_360
  end

  def rad_to_deg(rad)
    rad * TWOPI_UNDER_360
  end

  def is_near(value1, value2)
    (value1-value2).abs < 0.000001
  end

  def near_zero(value)
   is_near(value, 0.0)
  end

  def normalize_to_circle(radians)
    while(radians >= TWOPI)
      radians -= TWOPI
    end
    while(radians < 0.0)
      radians += TWOPI
    end
    radians
  end

  # Get relative angle in radians
  # Parameters:
  # - x => measure from this x coordinate
  # - y => measure from this y coordinate
  # - to_x => measure to this x coordinate
  # - to_y => measure to this y coordinate
  # Returns:
  # - Radians from <x,y> to <to_x,to_y>. Will be in the range [-PI,PI] with 0 being North
  def relative_angle(x,y,to_x,to_y)
    delta_x = to_x - x
    delta_y = to_y - y

    return 0.0 if Paidgeeks.near_zero(delta_x) && Paidgeeks.near_zero(delta_y)

    Math.atan2(delta_x, delta_y) # swapped because y is north/south (heading 0 is north) and x is east/west (heading 90 is east)
  end
end
