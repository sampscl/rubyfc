require_relative 'math_utils'
require_relative '../templates/all'

module Paidgeeks
  module RubyFC
    class Mob
      attr_accessor :x_pos, 
      :y_pos, 
      :heading, 
      :velocity, 
      :turn_rate,
      :valid_time,
      :turn_start_time, 
      :turn_stop_time,
      :turn_stop, # heading (radians)
      :template,
      :create_time,
      :mid, 
      :fid,
      :energy,
      :hitpoints,
      :last_scan_tick
      
      KINEMATIC_ATTRS = ["x_pos", "y_pos", "heading", 
                         "velocity", "turn_rate", "valid_time", 
                         "turn_start_time", "turn_stop_time", "turn_stop"]
      IDENTIFIER_ATTRS = ["mid", "fid"]
      METADATA_ATTRS = ["template", "create_time"]
      OTHER_ATTRS = ["energy", "hitpoints", "last_scan_tick"]

      ALL_ATTRS = KINEMATIC_ATTRS + IDENTIFIER_ATTRS + METADATA_ATTRS + OTHER_ATTRS

      def self.from_msg(msg)
        mob = Mob.new
        ALL_ATTRS.each do |attr|
          mob.send("#{attr}=", msg[attr]) if msg.include?(attr)
        end
        mob
      end

      def self.copy(other_mob)
        mob = Mob.new
        ALL_ATTRS.each { |attr| mob.send("#{attr}=", other_mob.send(attr)) }
        mob
      end

      def is_turning?
        !Paidgeeks.near_zero(turn_rate)
      end

      # Get a new Mob copied from this mob, only with a turn-to set.
      # This method is non-mutating.
      def turn_to(new_heading_radians, direction=:clockwise)
        Mob::copy(self).do_turn_to(new_heading_radians, direction)
      end

      # Get a new mob copied from this mob, only integrated
      # This method is non-mutating.
      def integrate(to_time)
        Mob::copy(self).do_integrate(to_time)
      end

      protected
      # this is a mutating method, and it returns self
      def do_turn_to(new_heading_radians, direction)
        new_heading_radians = Paidgeeks.normalize_to_circle(new_heading_radians)
        delta_radians = 0.0
        max_turn_rate = self.template.max_turn_rate
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
        self
      end

      # This is a mutating method, and it returns self
      def do_integrate(to_time)
        turning = is_turning?

        # if we were supposed to stop turning before to_time, then
        # integrate to the turn stop time and then integrate
        if turning and turn_stop_time < to_time
          do_integrate(turn_stop_time)
          turning = is_turning?
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
        self
      end
    end
  end
end
