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
        attr_accessor :play_timer # Qt::Timer when playing, nil otherwise
        attr_accessor :toggle_play_button # Qt::Button when not in live mode (reading from stdin)

        def initialize
          super()
          self.dev_null = File.open("/dev/null", "r+")
          self.gs = Paidgeeks::RubyFC::Engine::GameState.new(self.dev_null)
          self.gsc = Paidgeeks::RubyFC::Engine::GameStateChanger
          self.play_timer = nil
          self.toggle_play_button = nil
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
            #window.resize(1280, 1024)

            tick_button = Qt::PushButton.new("Tick", window)
            tick_button.connect(:clicked, self, :tick)

            self.toggle_play_button = Qt::PushButton.new("Play", window)
            toggle_play_button.connect(:clicked, self, :toggle_play)

            button_layout = Qt::VBoxLayout.new
            button_layout.add_widget(tick_button)
            button_layout.add_widget(toggle_play_button)
            button_layout.set_alignment(Qt::AlignTop)

            self.playback_widget = Paidgeeks::RubyFC::UI::PlaybackWidget.new(gs, window)
            playback_widget.width = 1280
            playback_widget.height = 1024

            top_layout = Qt::HBoxLayout.new
            top_layout.add_layout(button_layout)
            top_layout.add_widget(playback_widget)
            window.set_layout(top_layout)

            self.play_timer =  Qt::Timer.new(window)
            play_timer.single_shot = false
            play_timer.connect(:timeout, self, :tick)

            tick_button.show
            toggle_play_button.show
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
              lfn = nil #Tk.getOpenFile
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
            if self.play_timer
              play_timer.stop
              toggle_play_button.disabled = false
              stop_button.disabled = true
            end
          end
        end # tick

        def toggle_play
          if play_timer.is_active()
            play_timer.stop
            toggle_play_button.text = "Play"
          else
            play_timer.start((gs.config[:seconds_per_tick]*1000.0).round)
            toggle_play_button.text = "Stop"
          end
        end # toggle_play

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
