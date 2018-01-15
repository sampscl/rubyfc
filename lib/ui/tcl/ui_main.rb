require 'rubygems'
require 'bundler/setup'
require 'tk'
require 'ostruct'

require_relative '../../../config/config'
require_relative '../../game_engine/all'
require_relative '../../utilities/stream_comms'

module Paidgeeks
  module RubyFC
    module UI
      class TkMain

        attr_accessor :dev_null # File to /dev/null
        attr_accessor :gs # the gamestate
        attr_accessor :gsc

        def initialize
          self.dev_null = File.open("/dev/null", "r+")
          self.gs = Paidgeeks::RubyFC::Engine::GameState.new(self.dev_null)
          self.gsc = Paidgeeks::RubyFC::Engine::GameStateChanger
          Paidgeeks::RubyFC::Config.load(gs)

        end # initialize

        def run
          log_file, log_file_name =
            case ARGV[0]
            when "-"
              [$stdin, "stdin"]
            when nil
              lfn = Tk.getOpenFile
              File.exist?(lfn) ? [File.open(lfn), lfn] : [nil, nil]
            else
              File.exist?(ARGV[0]) ? [File.open(ARGV[0]), ARGV[0]] : [nil, nil]
            end

          return -1 if log_file.nil?

          root = TkRoot.new { title "Fleet Commander Playback: #{log_file_name}" }
          if log_file_name != "stdin"
            tick_once_cmd = proc do
              msg = Paidgeeks.read_object(log_file, 1.0)
              self.process_msg(msg) if msg
            end

            tick_many_cmd = proc do
              $stdout.write("tick_many\n")
            end

            buttons_frame = TkFrame.new(root) { borderwidth 3 ; relief "flat" }
            tick_button = TkButton.new(buttons_frame) { text "Tick Once" ; command tick_once_cmd }
            tick_many_button = TkButton.new(buttons_frame) { text "Tick..." ; command tick_many_cmd }
            tick_button.pack fill: "both", expand: 1
            tick_many_button.pack fill: "both", expand: 1
            game_field = TkCanvas.new(root) { width 1024 ; height 768 }
            game_field.grid row: 0, column: 1, sticky: "nsew"
            buttons_frame.grid row: 0, column: 0
            # end if reading from game log file
          else # else reading from stdin
            game_field = TkCanvas.new(root) { width 1024 ; height 768 }
            game_field.grid row: 0, column: 0, sticky: "nsew"

            Thread.new do
              loop do
                begin
                  msg = Paidgeeks.read_object(log_file, 1.0)
                  self.process_msg(msg) if msg
                rescue StandardError => e
                  $stderr.write("do_update_thread() exiting (#{e.inspect})\n")
                  return
                end
              end
            end

          end # end else using stdin

          Tk.mainloop
        end # run

        def process_msg(msg)
          $stdout.write("processing #{msg.inspect}\n")
          case msg["type"]
          when "init_mission"
            # do nothing, init mission doesn't do anything for playback.
          when "game_config"
            # do nothing, game config doesn't do anything for playback.
          when "begin_tick", "end_tick"
            # do nothing, the tick updates are handled within the tick_msg
          when /_notify$/
            # do nothing, the notify messages do not affect game state
          when "add_fleet"
            # we do not want a real fleet here
            new_ff = File.expand_path("../../utilities/null_fleet.rb", __FILE__)
            msg["ff"] = new_ff
            self.gsc.send("#{msg["type"]}_msg".to_sym, self.gs, msg)
          when "scan_report"
            # do nothing, scan reports don't do anything for playback
          when "turn_to"
            # do nothing, turn_to calls mob functions that, from a state
            # perspective, are reduntant with integration messages
          when "turn_forever"
            # do nothing, turn_forever calls mob functions that, from a state
            # perspective, are reduntant with integration messages
          else
            self.gsc.send("#{msg["type"]}_msg".to_sym, self.gs, msg)
          end
        end # process_msg

      end
    end
  end
end
