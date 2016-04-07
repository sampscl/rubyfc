require 'thread'
require_relative 'all'
require_relative '../../config/constants'
require_relative '../utilities/class_from_string'
require_relative '../missions/all'

module Paidgeeks
  module RubyFC
    module Engine
      class GameCoordinator
        
        attr_reader :journal
        attr_reader :log_files
        attr_reader :gs
        attr_reader :gsc 
        attr_reader :smp
        attr_reader :ke
        attr_reader :opts
        attr_reader :report

        def cleanup
          ke.cleanup
          gs.cleanup
          log_files.each { |lf| lf.close }
        end

        # Do all game setup based on opts. 
        # Parameters:
        # - opts => {
        #     :game_log_file_name => baename of game log, file will be in LOG_DIR
        #     :mission => Full name of mission to run, e.g. "Paidgeeks::RubyFC::Missions::Deathmatch"
        #     :fleets => Array of fleet file names that will be loaded to manage fleets
        #     :game_id => Integer used to name fleet log files uniquely
        #   }
        def game_setup(opts)
          # save game opts
          @opts = opts

          # log files we must close
          @log_files = []

          # game journal
          @journal = opts[:journal]

          # initialize game state
          @gs = Paidgeeks::RubyFC::Engine::GameState.new(@journal)
          
          # load the config into game state
          Config.load(gs)

          # no winner (yet)
          @report = {
            winner: nil,
            announcement: "No winner."
          }

          # initialize other engine components
          @gsc = Paidgeeks::RubyFC::Engine::GameStateChanger # NOTE: this is *not* an instance! It's just shorthand
          @smp = Paidgeeks::RubyFC::Engine::SanitizedMessageProcessor.new
          @ke = Paidgeeks::RubyFC::Engine::KinematicEngine.new(gs)

          # load & initialize mission
          gs.mission = Paidgeeks::class_from_string(opts[:mission]).new
          gs.mission.set_defaults(gs)
          gs.mission.init_mission(gs)

          # set mission info in config, this will be sent to all fleets later
          gs.config[:mission_title] = gs.mission.mission_title
          gs.config[:mission_description] = gs.mission.mission_description

          # load fleet(s)
          opts[:fleets].each_with_index do |ff,ndx|

            fid = ndx+1 # just so we don't have fleet ID's == 0

            ls = File.open(File.join(Paidgeeks::RubyFC::LOG_DIR, "game-#{opts[:game_id]}-fleet-#{fid}.log"),"w+t")
            log_files << ls

            gsc::add_fleet_msg(gs, {
              "type" => "add_fleet",
              "fid" => fid,
              "ff" => ff,
              "last_ack_tick" => gs.tick,
              "log_stream" => ls,
              "fleet_source" => false,
              })
          end # end add each fleet

          # init fleets -- first message received must be metatdata
          sleep(1.0) # let fleets have a moment to initialize
          gs.fleets.each { |fid, fleet| fleet[:manager].cache_inputs(gs) }
          gs.fleets.each { |fid, fleet| fleet[:manager].process_inputs(smp,gs) }
          gs.fleets.each do |fid, fleet|
            if not(fleet[:manager].fleet_metadata.has_key?("author") and fleet[:manager].fleet_metadata.has_key?("fleet_name"))
              # no metadata, fleet is disqualified
              gsc::disqualify_fleet_msg(gs, {
                "type" => "disqualify_fleet",
                "fid" => fid,
                "error" => "Fleet did not provide metadata",
                "backtrace" => "",
                "inspected_args" => [],
                "fleet_source" => false,
                })
            else
              # fleet allowed to participate, mark as alive
              gsc::fleet_state_msg(gs, {
                "type" => "fleet_state",
                "fid" => fid, 
                "state" => "alive",
                "fleet_source" => false,
                })

              # give fleet the game config
              gsc::msg_to_fleet(gs, fleet[:manager], {
                "type" => "game_config",
                "fid" => fid,
                "config" => gs.config,
                })
            end
          end

          # notify mission that it is ready to run
          gs.mission.prepare_to_run(gs)
        end # game_setup

        # Tick the game once. This is the 'forever' loop for running the 
        # game. Call it repeatedly until the game is over, then get
        # the final mission report.
        # Parameters:
        # - last_time => the last gs.time this method was called
        # Returns:
        # - :in_progress => Game is still in progress
        # - :finished => Game is finished, get final status with report method and call cleanup
        def game_tick(last_time)
          return :finished if gs.tick >= gs.config[:max_game_ticks]

          # tick
          gsc::tick_msg(gs, {"type" => "tick", "fleet_source" => false})

          # update mission
          gs.mission.update_mission(gs)

          # begin tick fleet
          # read fleet inputs
          # process logging
          # process fleet inputs
          gs.fleets.each do |fid, fleet| 
            fm = fleet[:manager]
            if :alive != fm.fleet_state
              # logging (all fleets get to log, even dead ones)
              fm.process_logging(gs)
              next
            end

            gsc::msg_to_fleet(gs, fm, {"type" => "begin_tick", "tick" => gs.tick, "time" => gs.time, "fid" => fid}) 
            fm.cache_inputs(gs)
            fm.process_logging(gs)
            fm.process_inputs(smp, gs)
          end

          # update mobs' kinematics, energy, and do collosion detection
          ke.update(last_time, gs)

          # end tick
          # send fleet outputs
          # read inputs and process for up to 1 second in order to receive tick acknowledgement
          gs.fleets.each do |fid, fleet| 
            fm = fleet[:manager]
            next if :alive != fm.fleet_state

            gsc::msg_to_fleet(gs, fm, {"type" => "end_tick", "tick" => gs.tick, "time" => gs.time, "fid" => fid}) 
            fm.flush_output

            stop_at = Time.now + 1.0
            while fleet[:last_ack_tick] != gs.tick and Time.now <= stop_at
              Thread.pass
              fm.cache_inputs(gs)
              fm.process_logging(gs)
              fm.process_inputs(smp, gs)
            end

            if fleet[:last_ack_tick] != gs.tick
              gsc::disqualify_fleet_msg(gs, {
                "type" => "disqualify_fleet",
                "fid" => fid,
                "error" => "Failure to acknowledge tick",
                "backtrace" => "",
                "inspected_args" => [],
                "fleet_source" => false,
                })
            end
          end

          # evaluate mission, release cpu to help give fleets some time to do their fleet thing
          gs.mission.mission_complete?(gs) ? :finished : :in_progress
        end # game_tick
      end
    end
  end
end
require_relative '../logging/game_engine/game_coordinator_logging.rb'
