require_relative 'base_mob'
module Paidgeeks
  module RubyFC
    module Templates
      class Cruiser < BaseMob
        @@my_turn_rate = Paidgeeks.deg_to_rad(5.0)

        def self.max_turn_rate
          @@my_turn_rate
        end

        def self.max_velocity
          50.0
        end

        def self.can_fire_rockets
          true
        end

        def self.can_fire_missiles
          true
        end

        def self.max_energy
          100
        end

        def self.energy_recovery_rate
          5 #  per second
        end

        def self.credit_cost
          1400
        end

        def self.hit_points
          10
        end

      end
    end
  end
end
