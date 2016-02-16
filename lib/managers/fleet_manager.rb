require 'open3'
require_relative './fleet_manager_handlers/all'
require_relative '../../config/constants'
require_relative '../utilities/pid_state'
require_relative '../utilities/stream_comms'

module Paidgeeks
  module RubyFC
    module Managers
      # The fleet manager has an instance assiged to every fleet. It
      # is the communication conduit between the game and the ships
      # of each fleet. It reads and unpacks messages, validates them, and calls out
      # the the GameManager for processing. It also provides fleet-level logging.
      class FleetManager

        attr_reader :fleet_file
        attr_reader :fleet_id
        attr_reader :fleet_msg_handler
        attr_accessor :fleet_metadata
        attr_accessor :fleet_state
        attr_accessor :tick
        attr_accessor :last_acknowledged_tick
        attr_reader :log_stream_file_name

        def initialize(ff, fid, gid)
          @fleet_file = ff
          @fleet_id = fid
          @fleet_msg_handler = FleetMessageHandler.new
          @fleet_metadata = {}
          @fleet_state = :initializing # or: :alive, :dead, :error
          self.tick = 0
          self.last_acknowledged_tick = 0
          @output_queue = [] # encoded and JSON'ed
          @input_queue = [] # encoded and JSON'ed

          @log_stream_file_name = File.join(LOG_DIR, "game-#{gid}-fleet-#{fid}.log")
          @log_stream = File.open(@log_stream_file_name,"w+t")

          begin
            @stdin, @stdout, @stderr, @wait_thr = Open3.popen3(@fleet_file)
          rescue => e
            @stdin = @stdout = @stderr = @wait_thr = nil
            @fleet_state = :error
            self.fleet_metadata[:error] = "Exception creating fleet: #{e}"
            self.fleet_metadata[:backtrace] = e.backtrace.join("\n\tfrom: ")
            self.fleet_metadata[:inspected_args] = []
          end
        end

        def cleanup
          if !@wait_thr.nil?
            p = @wait_thr[:pid]
            [@stdin, @stdout, @stderr].each { |s| s.close }
            Process.kill("KILL", p) if Paidgeeks::PidState.pid_state(p) == :alive
            @stdin = @stdout = @stderr = @wait_thr = nil
          end
          @log_stream.close if @log_stream
          @log_stream = nil
        end

        def start(game_manager)
          @fleet_state = :alive if :error != @fleet_state
          process({"type" => "start", "log_stream_file_name" => @log_stream_file_name}, 0, game_manager)
        end

        def begin_tick(new_time)
          self.tick = new_time
          queue_output({type: :begin_tick, tick: new_time})
        end

        def cache_inputs
          msg_count = 0
          while(!(encoded_msg = Paidgeeks.read_line(@stdout, 0)).nil? && msg_count < $max_messages_per_tick)
            msg_count += 1
            @input_queue << encoded_msg
          end
        end

        def process_logging
          return if @stderr.nil?
          msg_count = 0
          begin
            msg = Paidgeeks.read_line(@stderr, 0)
            if !msg.nil?
              msg_count += 1
              log(msg, msg_count)
            end
          end until msg.nil? || msg_count >= $max_messages_per_tick
          @log_stream.flush
        end

        def process_inputs(game_manager)
          @input_queue.each_with_index { |msg, ndx| process(Paidgeeks.decode(msg), ndx+1, game_manager) }
          @input_queue.clear
        end

        def end_tick(new_time)
          queue_output({type: :end_tick, tick: new_time})
        end

        def flush_output
          if !@output_queue.empty?
            @stdin.puts(@output_queue)
            @output_queue.clear
          end
          @stdin.flush
        end

        # methods for others to call on this fleeet

        def queue_output(msg, encoded=false)
          msg = Paidgeeks.encode(msg) if false == encoded
          @output_queue << msg
        end

        # private stuff
        private
        def log(msg, count)
          @log_stream.puts msg
        end

        def process(msg, count, game_manager)
          fleet_msg_handler.send(msg["type"].to_sym, msg, self, game_manager)
        end
      end
    end
  end
end

require_relative '../logging/managers/fleet_manager_logging.rb'
