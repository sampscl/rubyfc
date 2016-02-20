require_relative '../../utilities/pass_through'
module Paidgeeks
  module RubyFC
    module Managers
      # All methods defined here (*_msg) are recorded in the game journal
      class GameManager

        def set_gid_msg(msg)
          @game_id = msg["gid"]
        end

        def create_fleet_msg(msg)
          cmd = File.join(APP_DIR, "lib/utilities/null_fleet.rb")
          create_fleet(cmd) # this is only called this way during game playback
        end

        def set_fleet_metadata_msg(msg)
          fleet = fleets[msg["fleet"]]        
          fleet.fleet_metadata["author"] = msg["author"]
          fleet.fleet_metadata["fleet_name"] = msg["fleet_name"]
        end

        def start_msg(msg)
        end

        def begin_tick_msg(msg)
          fleets[msg["fleet"]].begin_tick(msg["tick"])
        end

        def end_tick_msg(msg)
          fleets[msg["fleet"]].end_tick(msg["tick"])
        end

        def tick_acknowledged_msg(msg)
          fleet = fleets[msg["fleet"]]
          ack_tick = msg["tick"]
          fleets[msg["fleet"]].last_acknowledged_tick = msg["tick"] if ack_tick <= fleet.tick
        end

        def launch_msg(msg)
          fleet = fleets[msg["fleet"]]
          source_ship = ships[msg["source_ship"]]
          return if source_ship.nil?
          
        end
      end
    end
  end
end
