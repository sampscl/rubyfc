require_relative 'base_mob'
module Paidgeeks
  module RubyFC
    module Templates
      class Missile < BaseMob
        @@my_turn_rate = Paidgeeks.deg_to_rad(45.0)

        def self.max_turn_rate
          @@my_turn_rate
        end

        def self.max_velocity
          150.0
        end

        def self.max_energy
          1
        end

        def self.energy_recovery_rate
          0 #  per second
        end

        def self.credit_cost
          10
        end
        
        def self.damage_caused
          1
        end
      end
    end
  end
end
