#!/usr/bin/env ruby

# useful: Paidgeeks module has handy methods for encoding and decoding
# messages with RubyFC. We'll just use those here.
require_relative '../utilities/stream_comms'

# Convenience function to send a message Hash to RubyFC, the
# flush is important to make sure that the game receives messages
# in a timely manner.
def send(msg)
  Paidgeeks.write_object($stdout, msg)
  $stdout.flush
end

# Convenience method to write a log entry. Each fleet
# has it's own log file created for it.
# Parameters:
# - msg => The message to write, will be turned into a string
#   and written to the log file.
def log(msg)
  $stderr.puts(msg)
end

class Cruiser
  attr_accessor :scan_plan # Array of {
    # "type" => "scan",
    # "source_ship" => mid,
    # "azimuth" => degrees,
    # "range" => game_units, gunship inherits default scan range of 1500.0
    # }
  attr_accessor :enemies # {mid: mob, ...}
  attr_accessor :mid # my gunship
  def initialize
    range_for_30_degree_scan = 143.0 # 30 degrees to radians = area / range; solve for range
    range_for_3_degree_scan = 1043.0 # 30 degrees to radians = area / range; solve for range
    self.enemies = {}
    self.mid = nil
    self.scan_plan = [ # scans always cover 75 square units on a 3600 x 2400 playing field (config.yml)
      { "type" => "scan", "source_ship" => 0, "azimuth" => 15.0,"range" => range_for_30_degree_scan }, # 0 - 30
      { "type" => "scan", "source_ship" => 0, "azimuth" => 45.0,"range" => range_for_30_degree_scan }, # 30 - 60
      { "type" => "scan", "source_ship" => 0, "azimuth" => 75.0,"range" => range_for_30_degree_scan }, # 60 - 90
      { "type" => "scan", "source_ship" => 0, "azimuth" => 105.0,"range" => range_for_30_degree_scan }, # 90 - 120
      { "type" => "scan", "source_ship" => 0, "azimuth" => 135.0,"range" => range_for_30_degree_scan }, # 120 - 150
      { "type" => "scan", "source_ship" => 0, "azimuth" => 165.0,"range" => range_for_30_degree_scan }, # 150 - 180
      { "type" => "scan", "source_ship" => 0, "azimuth" => 195.0,"range" => range_for_30_degree_scan }, # 180 - 210
      { "type" => "scan", "source_ship" => 0, "azimuth" => 225.0,"range" => range_for_30_degree_scan }, # 210 - 240
      { "type" => "scan", "source_ship" => 0, "azimuth" => 255.0,"range" => range_for_30_degree_scan }, # 240 - 270
      { "type" => "scan", "source_ship" => 0, "azimuth" => 285.0,"range" => range_for_30_degree_scan }, # 270 - 300
      { "type" => "scan", "source_ship" => 0, "azimuth" => 315.0,"range" => range_for_30_degree_scan }, # 300 - 330
      { "type" => "scan", "source_ship" => 0, "azimuth" => 345.0,"range" => range_for_30_degree_scan }, # 330 - 360
    ]
    (1..120).each { |i| self.scan_plan << { "type" => "scan", "source_ship" => 0, "azimuth" => i * 3.0, "range" => range_for_3_degree_scan } }
  end

  # Process messages received from the game
  # Parameters:
  # - msg => The message; this will be a Hash object with
  #   String keys.
  def process(msg)
    case msg["type"] # all messages have a "type" field
    when "begin_tick" # beginning of a game tick
      send(self.scan_plan.first)
      self.scan_plan.rotate!
    when "end_tick" # end of a game tick
      send({"type" => "tick_acknowledged", "tick" => msg["tick"]})
      process_engagements()
      log(self.enemies.pretty_inspect)
    when "munition_intercept_notify"
      if msg["remaining_target_hitpoints"] <= 0
        self.enemies.delete(msg["target_mid"])
      end
    when "create_mob_notify" # new mob of mine, fly in a circle
      log(msg)
      if self.mid.nil?
        self.mid = msg["mid"]
        self.scan_plan.each { |sp| sp["source_ship"] = self.mid }
      end
    when "scan_report"
      msg["reports"].each { |report| self.enemies[report["mid"]] = report }
    else # this is a message that we don't handle yet, just log it
      #log("Got message that I don't handle: #{msg.inspect}")
    end
  end
end # class Cruiser

# This is the program entry point. Because of the __FILE_ trick below,
# this will only be executed if the script is run as as "program" from
# the command line. Which happens to be *exactly* what RubyFC does
# when you give it a fleet file name.
def main

  # always write your fleet metadata first
  send({
      "type"       => "set_fleet_metadata",
      "author"     => "Clay Sampson",
      "fleet_name" => "Advanced Minimal Example 1.0",
    })

  fleet = Cruiser.new

  # Keep going forever, RubyFC will clean up the fleets automagically
  loop do
    # Read a message. Use a timeout of 1 second to
    # be a good player and not try to eat all the
    # available CPU time by spinning in a loop.
    msg = Paidgeeks.read_object($stdin, 1)

    # If we did not get a message, loop again
    next if msg.nil?

    # process the message
    fleet.process(msg)
  end
end

# Useful ruby trick: if the name of this file (__FILE__) is also
# the program name ($0), then this file was run like a program,
# so we'll act like a program. Otherwise, this file was loaded
# some other way (like 'require', or 'load') and there is nothing
# to do.
if __FILE__ == $0
  main
end
