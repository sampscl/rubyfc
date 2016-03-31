module Paidgeeks
  module_function 

  # handy constants
  TWOPI = 2.0*Math::PI
  TWOPI_OVER_360 = TWOPI/360.0
  TWOPI_UNDER_360 = 360.0/TWOPI

  # convert degrees to radians
  def deg_to_rad(deg)
    deg * TWOPI_OVER_360
  end

  # convert radians to degrees
  def rad_to_deg(rad)
    rad * TWOPI_UNDER_360
  end

  # Check if a value is near another (floating point math is imprecise, this is a 'close enough' test)
  def is_near(value1, value2)
    (value1-value2).abs < 0.000001
  end

  # Check if a value is near zero (floating point math is imprecise, this is a 'close enough' test)
  def near_zero(value)
   is_near(value, 0.0)
  end

  # Ensure that the angle given is >=0 and <= 2PI
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

    return 0.0 if near_zero(delta_x) && near_zero(delta_y)

    Math.atan2(delta_x, delta_y) # swapped because y is north/south (heading 0 is north) and x is east/west (heading 90 is east)
  end

  # Get the square of the relative range
  # Parameters:
  # - x => measure from this x coordinate
  # - y => measure from this y coordinate
  # - to_x => measure to this x coordinate
  # - to_y => measure to this y coordinate
  # Returns:
  # - Square of the range from x,y to to_x,to_y
  def range2(x, y, to_x, to_y)
    delta_x = to_x - x
    delta_y = to_y - y
    ((delta_x*delta_x) + (delta_y*delta_y))
  end

  # Get the relative range
  # Parameters:
  # - x => measure from this x coordinate
  # - y => measure from this y coordinate
  # - to_x => measure to this x coordinate
  # - to_y => measure to this y coordinate
  # Returns:
  # - Range from x,y to to_x,to_y
  def range(x, y, to_x, to_y)
    Math.sqrt(range2(x,y,to_x,to_y))
  end

  # Calculate time to go until one
  # kinematic entity will be at its point of
  # closest approach to another. This assumes that
  # the each mob data was updated at the same time.
  # Parameters:
  # - m1 => mob1
  # - m2 => mob2
  # Returns:
  # - Float => Time until point of closest approach. Will be negative
  #   if in the past. Units are same as denominator of velocity.
  def ttg_pca_mobs(m1,m2)
    ttg_pca_angles(m1.x_pos,m1.y_pos,m1.heading,m1.velocity,m2.x_pos,m2.y_pos,m2.heading,m2.velocity)
  end

  # Calculate time to go until one
  # kinematic entity will be at its point of
  # closest approach to another
  # Parameters:
  # - x1 => entity1 x position
  # - y1 => entity1 y position
  # - hdg1 => entity1 heading (radians)
  # - vel1 => entity1 velocity
  # - x2 => entity2 x position
  # - y2 => entity2 y position
  # - hdg2 => entity2 heading (radians)
  # - vel2 => entity2 velocity
  # Returns:
  # - Float => Time until point of closest approach. Will be negative
  #   if in the past. Will return Float::INFINITY if the mobs are not
  #   mobing or are parallel to each other, 
  #   Units are same as deniminator of velocity.
  def ttg_pca_angles(x1,y1,hdg1,vel1,x2,y2,hdg2,vel2)
    v1x = Math.sin(hdg1) * vel1
    v1y = Math.cos(hdg1) * vel1
    v2x = Math.sin(hdg2) * vel2
    v2y = Math.cos(hdg2) * vel2

    ttg_pca(x1,y1,v1x,v1y,x2,y2,v2x,v2y)
  end

  # Calculate time to go as in ttg_pca_angles, only with all the cartesian
  # coordinates calculated first.
  def ttg_pca(x1,y1,v1x,v1y,x2,y2,v2x,v2y)
    # D(t) === separation distance
    # define A(t) === D^2(t)
    # solve for t where A(t) is minimum, this minimum occurs when
    # dA/dt = 0
    v1x_minus_v2x = v1x - v2x
    v1y_minus_v2y = v1y - v2y
    
    numerator = 
      (-( x1 - x2 ) * v1x_minus_v2x ) - 
      ( ( y1 - y2 ) * v1y_minus_v2y )
        
    denominator = 
      (v1x_minus_v2x * v1x_minus_v2x) +
      (v1y_minus_v2y * v1y_minus_v2y)
    
    if near_zero(denominator) # denominator is zero, so ttg is infinite
      return Float::INFINITY
    end
        
    # return the time to go
    return numerator / denominator;
  end

  # Calculate the course (aka heading) in radians needed for
  # m1 to intercept m2 in the shortest possible time. This 
  # ignores acceleration by assuming m1 can instantly change
  # heading and that m2 will not accelerate. If this is not
  # the case (and it almost never is), then call this method
  # repeatedly to recalculate.
  # Parameters:
  # - m1 => mob 1 (assumed to be integrated to same time as mob2)
  # - m2 => mob 2 (assumed to be integrated to same time as mob1)
  # Returns:
  # - possible => true/false  indicates whether an intercept is possible or not
  # - intercept_course => Angle (radians) that m1 should steer to intercept m2
  #     in the shortest amount of time.
  # - ttg => time to go before point of closest possible approach if
  #     m1 is at intercept_course.
  def calc_intercept_mobs(m1, m2)
    if near_zero(m1.velocity)
      return [false, 0.0, ttg_pca_mobs(m1,m2)]
    end

    v2x = Math.sin(m2.heading) * m2.velocity
    v2y = Math.cos(m2.heading) * m2.velocity
    calc_intercept(m1.x_pos,m1.y_pos,m1.velocity,m2.x_pos,m2.y_pos,v2x,v2y)
  end
  
  # See calc_intercept_mobs for what this does. v1 MUST be > 0
  def calc_intercept(x1,y1,v1,x2,y2,v2x,v2y)

    # Without acceleration terms:
    # Vt === target velocity vector
    # Vg === interceptor velocity vector
    # Pti === target initial position at t=0; in relative coordinates to interceptor
    # t === time to go, the quantity to be solved for
    # ((Vt*Vt - Vg^2) t^2) + ((Pti*Vt) 2t) + Pti*Pti = 0

    p2x_minus_p1x = x2 - x1
    p2y_minus_p1y = y2 - y1
    ttg = 0.0
    
    a = 
    ( v2x * v2x ) + 
    ( v2y * v2y ) -
    ( v1 * v1 )
    
    b = 
      2.0 * ( ( p2x_minus_p1x * v2x ) +
              ( p2y_minus_p1y * v2y ) )
    
    c = 
      ( p2x_minus_p1x * p2x_minus_p1x ) +
      ( p2y_minus_p1y * p2y_minus_p1y ) 
    
    b_squared = b * b;
    b_squared_minus_4ac = b_squared - (4.0*a*c);

    if b_squared_minus_4ac < 0.0
      # b^2 - 4ac < 0, no intercept
      return [false,0.0,0.0]
    end

    #puts("a:#{a} b:#{b} c:#{c} b_squared_minus_4ac:#{b_squared_minus_4ac}")
    
    # check for no solution or degenerate  
    # case of target (P2) standing still
    if near_zero(a) # relative velocity is zero (target and interceptor have same speed)
      if near_zero(v1) # no solution: interceptor is not moving
        return [false,0.0,0.0]
      else # interceptor and target moving at same speed
        #
        # course
        #
        numerator2 = ((p2x_minus_p1x * v2y * p2x_minus_p1x * v2y) - (p2y_minus_p1y * v2x * p2y_minus_p1y * v2x)).abs # abs to correct for tiny but slightly negative numbers that should actually be zero
        denominator = (Math::sqrt((p2x_minus_p1x*p2x_minus_p1x) + (p2y_minus_p1y*p2y_minus_p1y)) * Math::sqrt((v2x*v2x) + (v2y*v2y)))
        sin_alpha = Math::sqrt(numerator2) / denominator
          

        intercept_course = normalize_to_circle(
          relative_angle(0.0,0.0,p2x_minus_p1x,p2y_minus_p1y) + Math::asin(sin_alpha))
        #
        # time to intercept
        #
        tgt_course = normalize_to_circle(Math::atan2(v2x,v2y))
        ttg = ttg_pca_angles(x1,y1,intercept_course,v1,x2,y2,tgt_course,v1)
      end
    else # delta v != 0
      t_plus = 
        ( -b + Math::sqrt( b_squared_minus_4ac ) ) /
                    ( 2.0 * a )
        
      t_minus = 
        ( -b - Math::sqrt( b_squared_minus_4ac ) ) /
                    ( 2.0 * a )

      #
      # time to intercept
      #
      if t_minus < 0.0
        ttg = t_plus
      elsif t_plus < 0.0
        ttg = t_minus
      else
        ttg = [t_plus,t_minus].min
      end
      #
      # course
      #
      intercept_course = normalize_to_circle(
        Math::atan2(p2x_minus_p1x + (v2x * ttg), p2y_minus_p1y + (v2y * ttg)))
    end # end else target and/or interceptor are moving
    
    #
    # done
    #
    [Float::INFINITY == ttg ? false : true , intercept_course, ttg]
  end
end
