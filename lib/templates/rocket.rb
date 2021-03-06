require_relative 'base_mob'
module Paidgeeks
  module RubyFC
    module Templates
      class Rocket < BaseMob

        def self.max_turn_rate
          0.0
        end

        def self.max_velocity
          200.0
        end

        def self.max_energy
          1
        end

        def self.energy_recovery_rate
          0 #  per second
        end

        def self.credit_cost
          1
        end

        def self.damage_caused
          1
        end

        def self.can_scan
          false
        end

        def self.munition?
          true
        end

        def self.max_scan_range
          0.0
        end

        def self.png_file_path
          Pathname.new(File.join(File.expand_path('..', __FILE__), "..", "images", "rocket.png")).realpath.to_s
        end

      end
    end
  end
end
