require_relative 'base_mob'
module Paidgeeks
  module RubyFC
    module Templates
      class Gunship < BaseMob
        @@my_turn_rate = Paidgeeks.deg_to_rad(10.0)

        def self.max_turn_rate
          @@my_turn_rate
        end

        def self.max_velocity
          75.0
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
          300
        end

        def self.hit_points
          3
        end

        def self.collision_size
          15.0
        end

        def self.png_file_path
          Pathname.new(File.join(File.expand_path('..', __FILE__), "..", "images", "gunship.png")).realpath.to_s
        end

      end
    end
  end
end
