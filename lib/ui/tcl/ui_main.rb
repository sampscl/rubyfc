require 'rubygems'
require 'bundler/setup'
require 'tk'

require_relative '../../game_engine/all'
require_relative '../../utilities/stream_comms'

module Paidgeeks
  module RubyFC
    module UI
      class TkMain

        attr_accessor :all_msgs
        attr_accessor :fleets
        attr_accessor :mobs

        def initialize
          self.all_msgs = []
          self.fleets = []
          self.mobs = []
        end

        # Get log file and log file name as [log_file, log_file_name]. Call
        # log_file.close() when done with it.
        def open_log_file
          case ARGV[0]
          when "-"
            [$stdin, "stdin"]
          when nil
            lfn = Tk.getOpenFile
            File.exist?(lfn) ? [File.open(lfn), lfn] : [nil, nil]
          else
            File.exist?(ARGV[0]) ? [File.open(ARGV[0]), ARGV[0]] : [nil, nil]
          end
        end

        def run
          @log_file, log_file_name = open_log_file
          return 0 if @log_file.nil?
          begin
            @root = TkRoot.new { title "Fleet Commander Playback: #{log_file_name}" }
            @lists_frame = TkFrame.new(@root) { borderwidth 3 ; relief "flat" }
            @fleets = TkListbox.new(@lists_frame) { listvariable @fleets ; height 4 }
            @mobs = TkListbox.new(@lists_frame) { listvariable @mobs ; height 25 }
            @log = TkListbox.new(@lists_frame) { listvariable @all_msgs ; height 10 }
            @game_field = TkCanvas.new(@root) { width 1024 ; height 768 }
            @status_frame = TkFrame.new(@root) { borderwidth 3 ; relief "flat" }
            @status_label = TkLabel.new(@status_frame) { }

            @fleets.pack fill: "both", expand: 1
            @mobs.pack fill: "both", expand: 1
            @log.pack fill: "both", expand: 1

            @status_label.pack fill: "both", expand: 1

            @lists_frame.grid row: 0, column: 0, sticky: "nsew"
            @game_field.grid row: 0, column: 1, rowspan: 2, sticky: "nsew"
            @status_frame.grid row: 1, column: 0, columnspan: 2, sticky: "nsew"

            Thread.new { do_update_thread }

            Tk.mainloop
          ensure
            @log_file.close()
          end
        end

        def do_update_thread
          loop do
            begin
              msg = Paidgeeks.read_object(@log_file, 1.0)
              process_msg(msg) if !msg.nil?
            rescue StandardError => e
              $stderr.write("do_update_thread() exiting (#{e.inspect})\n")
              return
            end
          end
        end

        def process_msg(msg)
          msg_text = msg.inspect
          $stdout.write("processing message: #{msg_text}\n")
          #self.all_msgs << msg_text
          #self.all_msgs.shift(100) if self.all_msgs.length > 10_000
        end

      end
    end
  end
end
