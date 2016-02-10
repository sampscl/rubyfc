require 'open3'
require_relative '../../config/constants'
require_relative '../utilities/pid_state'
require_relative '../utilities/stream_comms'

module Paidgeeks
  module RubyFC
    module Managers
      class FleetManager

        attr_reader :fleet_file
        attr_accessor :fleet_metadata
        attr_accessor :fleet_state
        attr_accessor :tick

        def initialize(ff)
          @fleet_file = ff
          @fleet_metadata = {}
          @fleet_state = :initializing # or: :alive, :dead, :error
          self.tick=0
          @output_queue = [] # encoded and JSON'ed
          @input_queue = [] # encoded and JSON'ed

          begin
            @stdin, @stdout, @stderr, @wait_thr = Open3.popen3("ruby #{fleet_file}")
          rescue
            @stdin = @stdout = @stderr = @wait_thr = nil
            @fleet_state = :error            
          end
        end

        def cleanup
          if !@wait_thr.nil?
            p = @wait_thr[:pid]
            [@stdin, @stdout, @stderr].each { |s| s.close }
            Process.kill("KILL", p) if Paidgeeks::PidState.pid_state(p) == :alive
            @stdin = @stdout = @stderr = @wait_thr = nil
          end
        end

        def start
          @fleet_state = :alive
        end

        def cache_inputs
          msg_count = 0
          while(!(encoded_msg = Paidgeks.read_line(@stdout, 0)).nil? && msg_count < MAX_MESSAGES_PER_TICK)
            msg_count = msg_count + 1
            @input_queue << msg
          end
        end

        def process_logging
          msg_count = 0
          begin
            msg = Paidgeeks.read_object(@stderr)
            if !msg.nil?
              msg_count = msg_count + 1
              log(msg, msg_count)
            end
          end until msg.nil? || msg_count >= MAX_MESSAGES_PER_TICK
        end

        def queue_output(msg, encoded=false)
          msg = Paidgeeks.encode(msg) if false == encoded
          @output_queue << msg
        end

        def begin_tick(new_time)
          self.tick = new_time
          queue_output({msg: :begin_tick, tick: new_time})
        end

        def end_tick(new_time)
          queue_output({msg: :end_tick, tick: new_time})
        end

        def flush_output
          if !@output_queue.empty?
            @stdin.puts(@output_queue)
            @output_queue.clear
          end
          @stdin.flush
        end

        def process_inputs
          @input_queue.each_with_index { |msg, ndx| process(Paidgeeks.decode(msg), ndx+1) }
          @input_queue.clear
        end

        # private stuff

        private
        # The log method is just here to provide an entry point for aspecting. All
        # the real work is done in the aspect.
        def log(msg, count)
        end

        def process(msg, count)
        end

      end
    end
  end
end

require_relative '../logging/managers/fleet_manager_logging.rb'
