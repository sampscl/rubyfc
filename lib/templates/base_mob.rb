require_relative '../utilities/math_utils'
module Paidgeeks
  module RubyFC
    module Templates
      class BaseMob

        @@default_turn_rate = Paidgeeks.deg_to_rad(5.0) # just do this computation once

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
      end
    end
  end
end
