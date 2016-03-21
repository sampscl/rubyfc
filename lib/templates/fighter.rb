require_relative 'base_mob'
module Paidgeeks
  module RubyFC
    module Templates
      class Fighter < BaseMob
        @@my_turn_rate = Paidgeeks.deg_to_rad(30.0)

        def self.max_turn_rate
          @@my_turn_rate
        end

        def self.max_velocity
          100.0
        end

        def self.can_fire_rockets
          true
        end

        def self.max_energy
          10
        end

        def self.energy_recovery_rate
          2 #  per second
        end

        def self.credit_cost
          100
        end
        
        def self.collision_size
          15.0
        end
      end
    end
  end
end
