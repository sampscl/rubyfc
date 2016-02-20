require_relative 'math_utils'
require_relative '../templates/all'

module Paidgeeks
  module RubyFC
    class Mob
      attr_accessor :x_pos, :y_pos, :heading, :velocity, :turn_rate
      attr_accessor :valid_time

      attr_accessor :turn_start_time, :turn_stop_time

      attr_accessor :turn_stop # heading (radians)

      attr_accessor :mob_template

      def initialize(template)
        # integration base
        @x_pos=@y_pos=@heading=@velocity=@turn_rate=0.0
        @valid_time=0.0

        @turn_start_time=@turn_stop_time=0.0
        @turn_stop=0.0

        @mob_template = template
      end

      def turn_to(new_heading_radians, direction=:clockwise)
        new_heading_radians = Paidgeeks.normalize_to_circle(new_heading_radians)
        delta_radians = 0.0
        max_turn_rate = self.mob_template.max_turn_rate
        if :clockwise == direction
          self.turn_rate = max_turn_rate
          if new_heading_radians < self.heading
            # this is the long way around
            delta_radians = TWOPI - self.heading + new_heading_radians 
          else
            # this is the short way around
            delta_radians = self.heading - new_heading_radians
          end
        else
          self.turn_rate = -max_turn_rate
          if new_heading_radians > self.heading
            # this is the long way around
            delta_radians = TWOPI - new_heading_radians + self.heading
          else
            # this is the short way around
            delta_radians = self.heading - new_heading_radians
          end
        end

        delta_time = delta_radians.abs / max_turn_rate
        self.turn_stop = new_heading_radians
        self.turn_stop_time = (self.valid_time + delta_time)        
      end

      def integrate(to_time)
        turning = !Paidgeeks.near_zero(turn_rate)

        if turning and turn_stop_time < to_time
          integrate(turn_stop_time)
          turning = !Paidgeeks.near_zero(turn_rate)
        end

        delta_time = to_time - self.valid_time

        delta_pos = delta_time * velocity
        initial_heading = heading
        delta_heading = 0.0

        delta_x = 0.0
        delta_y = 0.0

        moved = !Paidgeeks.near_zero(delta_pos)

        if turning
          delta_heading = delta_time * turn_rate
          self.heading += delta_heading
          self.heading = Paidgeeks.normalize_to_circle(self.heading)
        end

        if moved
          if turning
            radius_of_curvature = delta_pos / delta_heading
            delta_x = radius_of_curvature * (Math::cos(initial_heading) - Math::cos(self.heading))
            delta_y = radius_of_curvature * (Math::sin(self.heading) - Math::sin(initial_heading))
          else
            delta_x = delta_pos * Math::sin(self.heading)
            delta_y = delta_pos * Math::cos(self.heading)
          end
        end

        if turning && Paidgeeks.is_near(to_time, self.turn_stop_time)
          self.heading = self.turn_stop
          self.turn_rate = 0.0
        end

        self.x_pos += delta_x
        self.y_pos += delta_y
        self.valid_time = to_time
      end
    end
  end
end
