#!/usr/bin/env ruby
require 'optparse'
require_relative '../config/constants'
require_relative '../config/config'
require_relative '../lib/managers/all'

SIGNAL_QUEUE = []
Signal.trap "TERM" do
  SIGNAL_QUEUE << :TERM
end
Signal.trap "INT" do
  SIGNAL_QUEUE << :INT
end

def parse_command_line
  fleets = []
  game_log_file_name="game.log"
  game_playback_file_name=nil
  just_show_transcript = false
  OptionParser.new do |opts|
    opts.on("--fleets=", "Specify fleet files") do |opt|
      (opt.split(",").map { |fleet| fleet.strip }).each do |fleet_file|
        fleets << fleet_file
      end
    end
    opts.on("--log_file=", "Specify the game log file") do |opt|
      game_log_file_name = opt
    end

    opts.on("--playback=", "Specify game playback file") do |opt|
      game_playback_file_name = opt
    end

    opts.on("--just_show_transcript", "Just show the transcript of the playback, do not actually play it back") do
      just_show_transcript=true
    end
  end.parse!
  
  {
    fleets: fleets,
    game_log_file_name: game_log_file_name,
    game_playback_file_name: game_playback_file_name,
    just_show_transcript: just_show_transcript,
  }
end
def main
  args = parse_command_line
  if args[:game_playback_file_name].nil? # no playback, run the game
    File.open(File.join(Paidgeeks::RubyFC::LOG_DIR, args[:game_log_file_name]),"w+t") do |log_file|
      gm = Paidgeeks::RubyFC::Managers::GameManager.new(args[:fleets], log_file, 1)
      gm.run_game_while { SIGNAL_QUEUE.count == 0 }
      gm.cleanup
    end
  else # playback an old game, or dump a transcript
    File.open(args[:game_playback_file_name], "rt") do |playback_file|
      gm = Paidgeeks::RubyFC::Managers::GameManager.new([], $stdout, 1)
      gm.playback_while(playback_file) { SIGNAL_QUEUE.count == 0 } if !args[:just_show_transcript]
      gm.show_transcript(playback_file) if args[:just_show_transcript]
      gm.cleanup
    end
  end
end

if __FILE__ == $0
  main
end
