require 'pathname'
require_relative '../utilities/math_utils'
module Paidgeeks
  module RubyFC
    module Templates
      class BaseMob

        @@default_turn_rate = Paidgeeks.deg_to_rad(15.0) # just do this computation once

        def self.max_turn_rate
          @@default_turn_rate
        end

        def self.max_velocity
          50.0
        end

        def self.can_fire_rockets
          false
        end

        def self.can_fire_missiles
          false
        end

        def self.can_create_others
          false
        end

        def self.max_energy
          100
        end

        def self.energy_recovery_rate
          5 #  per second
        end

        def self.credit_cost
          500 # 500 credits to create me
        end

        def self.energy_cost
          100
        end

        def self.hit_points
          1
        end

        def self.damage_caused
          0 # most mobs don't cause damage
        end

        def self.can_scan
          true
        end

        def self.collision_size
          0.0 # from original AI fleet commander: the collision size is a square around each mob
        end

        def self.munition?
          false
        end

        def self.max_scan_range
          1500.0
        end

        def self.png_file_path
          nil # full path to the png file used to display this mob flying north or nil to use default
        end

        def self.scanned_area
          75.0 # square units, the amount of space scanned by any given scan.
               # The width scanned is: width_in_radians = scanned_area / range
               # at 75.0, a scan at 3600 units distance will be 1.1 degrees wide
        end
      end
    end
  end
end
