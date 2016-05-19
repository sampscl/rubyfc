require_relative '../game_engine/game_state_changer'
require_relative '../utilities/math_utils'
require_relative '../templates/all'
module Paidgeeks
  module RubyFC
    module Missions
      class Deathmatch

        def initialize
          @winner = nil
        end

        def mission_title
          "Deathmatch"
        end

        def mission_description
%{Deathmatch!
  
* Every fleet for itself until only one fleet remains
* No credits
* Munitions only cost energy
* Each fleet gets 1 Gunship
}
        end

        # Set game state defaults. This is called after the game state and engine components are
        # initialized but before any fleets are loaded. Use this method to override any configuration
        # defaults in gs.config and to add any scenario-specific templates into the 
        # Paidgeeks::RubyFC::Templates  module.
        # Parameters:
        # - gs => The gamestate
        def set_defaults(gs)
        end

        # Initialize mission. This is called after the game state and engine components are
        # initialized but before any fleets are loaded. 
        # Parameters:
        # - gs => The gamestate
        def init_mission(gs)
          Paidgeeks.write_object(gs.journal, {"type" => "init_mission", "mission" => self.class.name})
        end

        # Prepare the mission to run. This is called after set_defaults and init_mission, and 
        # after all the fleets are initialized and have provided fleet metadata to the game.
        # All living fleets in gs will be participants in this mission. This is a good time
        # to create the mobs that each fleet will start the mission with, as well as any
        # mission-controlled fleets. 
        # Parameters:
        # - gs => The gamestate
        def prepare_to_run(gs)
          gsc = Paidgeeks::RubyFC::Engine::GameStateChanger # note that this is a class not an instance
          gs.fleets.each do |fid, fleet|
            # each fleet gets zero credits
            gsc::set_credits_msg(gs, {
              "type" => "set_credits",
              "fid" => fid,
              "amount" => 0,
              "fleet_source" => false,
              })

            #
            # Monkeypatches to create custom configuration
            #

            # in order to allow fighting with no credits, the cost of 
            # munitions must be zero. 
            Paidgeeks::RubyFC::Templates::Rocket.define_singleton_method(:credit_cost) { 0 }
            Paidgeeks::RubyFC::Templates::Missile.define_singleton_method(:credit_cost) { 0 }

            # Extend the range of the gunship's scanners to speed up the action
            Paidgeeks::RubyFC::Templates::Gunship.define_singleton_method(:max_scan_range) { 2500.0 }

            # each fleet gets 1 gunship starting in a random location
            gsc::create_mob_msg(gs, {
              "type" => "create_mob",
              "template" => Paidgeeks::RubyFC::Templates::Gunship,
              "create_time" => gs.time,
              "x_pos" => rand(gs.config[:field_width]),
              "y_pos" => rand(gs.config[:field_width]),
              "heading" => Paidgeeks.deg_to_rad(rand(360)),
              "velocity" => Paidgeeks::RubyFC::Templates::Gunship.max_velocity,
              "turn_rate" => 0.0,
              "valid_time" => gs.time,
              "turn_start_time" => 0.0,
              "turn_stop_time" => 0.0,
              "turn_stop" => 0,
              "fid" => fid,
              "mid" => gs.reserve_mid,
              "energy" => Paidgeeks::RubyFC::Templates::Gunship.max_energy,
              "hitpoints" => Paidgeeks::RubyFC::Templates::Gunship.hit_points,
              "last_scan_tick" => 0,
              "target_mid" => nil,
              "launch_param" => "Main Gunship",
              "fleet_source" => false,
            })
          end
        end

        # Update the mission. Each game cycle consists of 1 tick, and this is the first thing
        # that happens at the beginning of each tick. Use this to examine the game state and
        # make decisions about how the mission should unfold as the game progresses.
        # Parameters:
        # - gs => The gamestate
        def update_mission(gs)
        end

        # Notification for when a munition has hit a target. A good place to keep score.
        # Parameters:
        # - gs => The gamestate
        # - mun_mid => The munition mid
        # - target_mid => The target mid
        def event_munition_intercept(gs, mun_mid, target_mid)
        end

        # Determine if the mission is complete. This is the last thing to happen at the 
        # end of every tick. 
        # Parameters:
        # - gs => The gamestate
        # Returns:
        # - true if the mission is complete
        # - false if the missions is not complete
        def mission_complete?(gs)
          alive_count = 0
          last_examined = nil
          gs.fleets.each do |fid, fleet| 
            if :alive == fleet[:manager].fleet_state
              alive_count += 1 
              last_examined = fid
            end
          end
          if 1 == alive_count
            @winner = gs.fleets[last_examined][:manager].fleet_metadata
          end
          alive_count <= 1
        end

        # Generate a mission report
        # Parameters:
        # - gs => The game state
        # Returns:
        # - Hash => {
        #     winner => metadata hash from the winning fleet or nil if no winner
        #     announcement => string describing the results of the mission
        #   }
        def mission_report(gs)
          if @winner
            return {
              winner: @winner,
              announcement: "Wins!"
            }
          else
            return {
            winner: nil,
            announcement: "No winner."
            }
          end
        end

        # Cleanup the mission. This is called after the game state is cleaned up. Use it
        # to clean up any files, databases, or other state information that will not
        # otherwise automatically be cleaned up.
        def cleanup
        end
      end
    end
  end
end
