#!/usr/bin/env ruby
require 'optparse'
require_relative './lib/managers/all'
def main
  fleets = []
  OptionParser.new do |opts|
    opts.on("--fleets=", "Specify fleet files") do |opt|
      (opt.split(",").map { |fleet| fleet.strip }).each do |fleet_file|
        fleets << Paidgeeks::RubyFC::Managers::FleetManager.new(fleet_file)
      end
    end
  end.parse!

  fleets.each { |fleet| fleet.start }

  tick = 0
  any_alive = true
  begin
    any_alive = false
    tick = tick + 1
    fleets.each do |fleet|
      fleet.begin_tick tick
      fleet.cache_inputs
      fleet.process_logging
      fleet.process_inputs
      fleet.end_tick tick
      fleet.flush_output
      any_alive |= (fleet.fleet_state == :alive)
    end
  end until !any_alive
end

if __FILE__ == $0
  main
end
