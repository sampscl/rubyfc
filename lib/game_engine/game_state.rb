require 'set'
module Paidgeeks
  module RubyFC
    module Engine
      class GameState
        attr_accessor :fleets # hash of fid => {} # fid is fleet id, see add_fleet for Hash definition
          # {
          #   manager => FleetManager, 
          #   mobs => Set.new(), # Set of mid that belong to fleet (mid is mob id)
          #   last_ack_tick => Integer, 
          #   log_stream => IO,
          #   credits => Integer, # number of credits the fleet has
          # }
        attr_accessor :mobs # hash of mid => Mob
        attr_accessor :tick # Integer
        attr_accessor :time # Float
        attr_accessor :mission # Mission
        attr_accessor :journal # IO
        attr_accessor :config # hash of config values
        attr_accessor :tick_scan_reports # array of scan reports generated in the last tick
        attr_accessor :munition_intercepts # array of munition intercept reports in the last tick

        def initialize(journal)
          @fleets = {}
          @mobs = {}
          @tick = 0
          @time = 0.0
          @mission = nil
          @journal = journal
          @config = {}
          @tick_scan_reports = []
          @munition_intercepts = []
          @next_mid = 0 # the next mid is really 1, reserve_mid takes care of that
        end

        def reserve_mid
          @next_mid += 1
        end

        def cleanup
          fleets.each { |fid, fleet| fleet[:manager].cleanup }
          fleets.clear
          mobs.clear
          mission.cleanup if self.mission
        end

        def add_fleet(fid, manager, last_ack_tick, log_stream)
          self.fleets[fid] = {
            manager: manager,
            mobs: Set.new,
            last_ack_tick: last_ack_tick,
            log_stream: log_stream,
            credits: config[:initial_fleet_credits],
          }
        end
      end
    end
  end
end
