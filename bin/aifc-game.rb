#!/usr/bin/env ruby
require 'optparse'
require 'yaml'
require 'fileutils'
require 'securerandom'
require_relative '../lib/game_engine/all'
require_relative '../config/constants'
require_relative '../config/config'

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
    game_log_file_name: "#{SecureRandom.uuid}.log",
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

    FileUtils.mkdir_p(Paidgeeks::RubyFC::LOG_DIR) if not Dir.exist?(Paidgeeks::RubyFC::LOG_DIR)

    journal_file_name = File.join(Paidgeeks::RubyFC::LOG_DIR, opts[:game_log_file_name])

    # g = Game.create!()
    # opts[:fleets].each {|ff| FleetFile.create!(path: ff, game: g)}
    # Journal.create!(path: journal_file_name, game: g)

    journal = opts[:game_log_file_name] == "-" ? $stdout : File.open(journal_file_name,"w+t")
    opts[:journal] = journal

    gc.game_setup(opts)

    run_game(gc)

    report = gc.gs.mission.mission_report(gc.gs)

    Paidgeeks::RubyFC::Engine::GameStateChanger::mission_report_msg(gc.gs, {
      "type" => "mission_report",
      "report" => report,
      "fleet_source" => false,
      })

    $stderr.write("Mission report: #{report.inspect}\n")

    gc.cleanup
  else
    Paidgeeks::RubyFC::Engine::Transcript::playback_until(opts) { SIGNAL_QUEUE.any? }
  end
end

def run_game(gc)
  $stderr.write("Game start at #{Time.now}\n")
  last_time = gc.gs.time
  while !SIGNAL_QUEUE.any? and :in_progress == gc.game_tick(last_time)
    last_time = gc.gs.time
  end
  $stderr.write("Game finish at #{Time.now}\n")
end

if __FILE__ == $0
  main
end
