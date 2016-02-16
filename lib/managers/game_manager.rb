require_relative './game_manager_parts/all'
require_relative '../utilities/stream_comms'

module Paidgeeks
  module RubyFC
    module Managers
      class GameManager
        
        attr_reader :fleets # fid,fleet
        attr_reader :game_id

        def initialize(fleet_files, game_log_stream, gid)
          @playback=false
          @game_log_stream = game_log_stream
          @fleets = {}
          set_gid_msg({"type" => "set_gid", "gid" => gid}) # so journaling gets the game id
          fleet_files.each { |fleet_file|  create_fleet(fleet_file) }
        end

        def cleanup
          @fleets.each { |fid,fleet| fleet.cleanup }
        end
  
        def run_game_while &continue_block
          fleets.each { |fid, fleet| fleet.start(self) }

          sleep 1 # let the fleets initialize

          tick = 0
          any_alive = true
          begin
            sleep(0.010)
            any_alive = false
            tick = tick + 1
            fleets.each do |fid, fleet|
              if !(:alive == fleet.fleet_state)
                fleet.process_logging # allow dead and errored fleets to continue logging
                next
              end
              begin_tick_msg({"type" => "begin_tick", "tick" => tick, "fleet" => fid})
              fleet.cache_inputs
              fleet.process_logging
              fleet.process_inputs(self)
              end_tick_msg({"type" => "end_tick", "tick" => tick, "fleet" => fid})
              fleet.flush_output

              if tick - fleet.last_acknowledged_tick > $unacknowledged_ticks_limit
                fleet.fleet_state = :error
                fleet.fleet_metadata[:error] = "Too many unacknowledged ticks (#{fleet.last_acknowledged_tick} / #{tick})"
              end

              any_alive |= (fleet.fleet_state == :alive)
            end
          end until !any_alive || !continue_block.call || tick >= $max_game_ticks

          end_game
          nil
        end

        # Create a fleet
        # Parameters:
        # - fleet_file => The file to load the fleet from
        # Returns:
        # - fleet => The FleetManager for the new fleet
        def create_fleet(fleet_file)
          fid = 1 + @fleets.count
          fleet = Paidgeeks::RubyFC::Managers::FleetManager.new(fleet_file, fid, self.game_id)
          @fleets[fid] = fleet
          fleet
        end

        # Write a journal entry to the game log
        # Parameters:
        # - msg => The message Hash object to write
        def journal(msg)
          if !@playback
            Paidgeeks.write_object(@game_log_stream, msg)
          else
            puts msg
          end
        end

        def end_game
        end
      end
    end
  end
end
require_relative '../logging/managers/game_manager_logging.rb'
