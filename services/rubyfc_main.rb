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
    game_playback_file_name: nil,
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

    opts.on("--playback=", "Specify game playback file") do |opt|
      result[:game_playback_file_name] = opt
    end

    opts.on("--just-show-transcript", "Just show the transcript of the playback, do not actually play it back") do
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
    report = Paidgeeks::RubyFC::Engine::GameCoordinator::run_until(opts) { SIGNAL_QUEUE.any? }
    puts("Mission report: #{report.inspect}")
  else
    Paidgeeks::RubyFC::Engine::Transcript::playback_until(opts) { SIGNAL_QUEUE.any? }
  end
end

if __FILE__ == $0
  main
end
