require 'open3'
require 'thread'
require_relative '../../config/constants'
require_relative '../utilities/pid_state'
require_relative '../utilities/stream_comms'

module Paidgeeks
  module RubyFC
    module Engine
      # The fleet manager has an instance assiged to every fleet. It
      # is the communication conduit between the game and the ships
      # of each fleet. It reads and unpacks messages, validates them, and 
      # calls out for processing. It also provides fleet-level logging. and
      # the current state of the fleet
      class FleetManager

        attr_accessor :fleet_id
        attr_reader :fleet_msg_handler
        attr_accessor :fleet_metadata
        attr_accessor :fleet_state # :initializing, :alive, :dead, :error

        def initialize(ff, fid, ls)
          @fleet_id = fid
          @fleet_msg_handler = FleetMessageHandler.new
          @fleet_metadata = {}
          @fleet_state = :initializing
          @output_queue = [] # encoded and JSON'ed
          @input_queue = [] # encoded and JSON'ed

          @log_stream = ls
          @instance_lock = Mutex.new

          begin
            @stdin, @stdout, @stderr, @wait_thr = Open3.popen3(ff)
          rescue => e
            @stdin = @stdout = @stderr = @wait_thr = nil
            @fleet_state = :error
            self.fleet_metadata[:error] = "Exception creating fleet: #{e}"
            self.fleet_metadata[:backtrace] = e.backtrace.join("\n\tfrom: ")
            self.fleet_metadata[:inspected_args] = []
          end
        end

        # Cleanup the fleet. It is given a SIGTERM and up to 1 second to exit
        # before SIGKILL.
        def cleanup
          status = :already_dead
          if !@wait_thr.nil?
            p = @wait_thr.pid
            [@stdin, @stdout, @stderr].each { |s| s.close }
            if Paidgeeks::PidState.pid_state(p) == :alive
              Process.kill("TERM", p) 
              status = :sigterm
              count=0
              while :alive == Paidgeeks::PidState.pid_state(p) && count < 10
                sleep(0.100)
                count += 1
              end
            end
            if Paidgeeks::PidState.pid_state(p) == :alive
              Process.kill("KILL", p) 
              status = :sigkill
            end
            @stdin = @stdout = @stderr = @wait_thr = nil
          else
            status = :not_started
          end
          status
        end

        def cache_inputs(gs)
          msg_count = 0
          max = gs.config[:max_messages_per_tick]
          while(!(encoded_msg = Paidgeeks.read_line(@stdout, 0)).nil? && msg_count < max)
            msg_count += 1
            @input_queue << encoded_msg
          end
        end

        def process_logging(gs)
          return if @stderr.nil?
          msg_count = 0
          max = gs.config[:max_messages_per_tick]
          begin
            msg = Paidgeeks.read_line(@stderr, 0)
            if !msg.nil?
              msg_count += 1
              log(msg)
            end
          end until msg.nil? || msg_count >= max
          @log_stream.flush
        end

        # Process the cached inputs from fleet. Will sanitize messages and  
        # pass them to smp for processing. Will raise ArgumentError if a message 
        # fails validation.
        # Parameters:
        # - smp => SanitizedMessageProcessor
        # - gs => GameState
        def process_inputs(smp, gs)
          @input_queue.each { |msg| process(Paidgeeks.decode(msg), smp, gs) }
          @input_queue.clear
        end

        def flush_output
          if !@output_queue.empty?
            @stdin.puts(@output_queue)
            @output_queue.clear
          end
          @stdin.flush
        end

        # Queue a message for output. The message must already be encoded.
        def queue_output(msg)
          @instance_lock.synchronize do
            @output_queue << msg
          end
        end

        # private stuff
        private
        def log(msg)
          @log_stream.puts msg
        end

        def process(msg, smp, gs)
          fleet_msg_handler.send(msg["type"].to_sym, msg, smp, self, gs)
        end
      end
    end
  end
end
require_relative '../logging/game_engine/fleet_manager_logging.rb'
