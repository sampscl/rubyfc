require 'rubygems'
require 'bundler/setup'
require 'Qt'
require 'ostruct'

require_relative '../../../config/config'
require_relative '../../game_engine/all'
require_relative '../../utilities/stream_comms'

require_relative 'playback_widget'

module Paidgeeks
  module RubyFC
    module UI
      class Qt4Main < Qt::Object

        attr_accessor :dev_null # File to /dev/null
        attr_accessor :gs # the gamestate
        attr_accessor :gsc
        attr_accessor :log_file # File API'ed log file
        attr_accessor :playback_widget

        def initialize
          super()
          self.dev_null = File.open("/dev/null", "r+")
          self.gs = Paidgeeks::RubyFC::Engine::GameState.new(self.dev_null)
          self.gsc = Paidgeeks::RubyFC::Engine::GameStateChanger
          Paidgeeks::RubyFC::Config.load(gs)

        end # initialize

        def init_ui(log_file_name)
          app = Qt::Application.new(ARGV)

          if(log_file_name == "stdin")
            # stdin is a live playback, so no TiVo controls
            self.playback_widget = Paidgeeks::RubyFC::UI::PlaybackWidget.new(gs)
            playback_widget.resize(1280, 1024)
            playback_widget.show
          else
            window = Qt::Widget.new
            window.resize(1280, 1024)
            forward = Qt::PushButton.new("Tick", window)
            forward.setGeometry(5, 5, 40, 20)
            forward.connect(:clicked, self, :tick)
            self.playback_widget = Paidgeeks::RubyFC::UI::PlaybackWidget.new(gs, window)
            playback_widget.setGeometry(45, 5, 1280, 1024)
            forward.show
            playback_widget.show
            window.show
          end
          app
        end

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

          self.log_file = log_file

          app = init_ui(log_file_name)
          app.exec

        end # run

        def tick
          begin
            msg = Paidgeeks.read_object(log_file, 1.0)
            process_msg(msg) if msg
            playback_widget.update
          rescue StandardError => e
            $stderr.write("tick() error => (#{e.inspect})\n")
          end
        end # tick

        def process_msg(msg)
          $stdout.write("processing #{msg.inspect}\n")
          case msg["type"]
          when "init_mission"
            # do nothing, init mission doesn't do anything for playback.
          when "game_config"
            # do nothing, game config doesn't do anything for playback.
          when "begin_tick"
            # do nothing, the tick updates are handled within the tick_msg
          when "end_tick"
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
