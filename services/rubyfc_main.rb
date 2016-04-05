#!/usr/bin/env ruby
require 'optparse'
require 'yaml'
require_relative '../lib/game_engine/game_coordinator'
require_relative '../lib/game_engine/transcript'
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
  result = {
    fleets: [],
    game_log_file_name: "game.log",
    just_show_transcript: false,
    game_id: 1,
    mission: "Paidgeeks::RubyFC::Missions::Deathmatch",
  }
  OptionParser.new do |opts|
    opts.on("--fleet=", "Specify fleet file") do |opt|
      result[:fleets] << opt
    end
    opts.on("--log_file=", "Specify the game log file") do |opt|
      result[:game_log_file_name] = opt
    end

    opts.on("--just-show-transcript", "Just show the transcript from the game log, do not actually play it back") do
      result[:just_show_transcript]=true
    end

    opts.on("--mission=", "Set mission name") do |opt|
      result[:mission] = opt
    end
  end.parse!
  
  result
end

def main
  opts = parse_command_line
  if not opts[:just_show_transcript]
    gc = Paidgeeks::RubyFC::Engine::GameCoordinator.new

    gc.game_setup(opts)

    last_time = gc.gs.time
    while !SIGNAL_QUEUE.any? and :in_progress == gc.game_tick(last_time)
      last_time = gc.gs.time
      Thread.pass
    end
    report = gc.gs.mission.mission_report(gc.gs)

    puts("Mission report: #{report.inspect}")

    gc.cleanup
  else
    Paidgeeks::RubyFC::Engine::Transcript::playback_until(opts) { SIGNAL_QUEUE.any? }
  end
end

if __FILE__ == $0
  main
end
