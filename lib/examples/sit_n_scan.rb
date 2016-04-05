#!/usr/bin/env ruby

# useful: Paidgeeks module has handy methods for encoding and decoding
# messages with RubyFC. We'll just use those here.
require_relative '../utilities/stream_comms'

# useful: Paidgeeks module has handy methods for doing math. We'll 
# just use those here
require_relative '../utilities/math_utils'

# save some global state (this is horrible programming practice, sorry.)
$last_scan_angle = 0.0
$scan_range = 1000.0
$scan_width = Paidgeeks.rad_to_deg(37.5 / $scan_range)
$mid=0

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

# Process messages received from the game
# Parameters:
# - msg => The message; this will be a Hash object with
#   String keys.
def process(msg)
  case msg["type"] # all messages have a "type" field
  when "begin_tick" # beginning of a game tick
    #log(msg)

    # do a scan, increment by a tiny bit less than the scan width
    # to create a bit of overlap from one scan to the next.
    $last_scan_angle += (0.95 * $scan_width)
    $last_scan_angle -= 360.0 if $last_scan_angle > 360.0
    send({
      "type" => "scan",
      "source_ship" => $mid,
      "azimuth" => $last_scan_angle,
      "range" => $scan_range,
      })
    log("scan ang:#{$last_scan_angle}, wid:#{$scan_width}")

  when "end_tick" # end of a game tick
    send({"type" => "tick_acknowledged", "tick" => msg["tick"]})
    #log(msg)
  when "create_mob_notify" # new mob of mine, set speed to zero
    $mid = msg["mid"]
    send({"type" => "set_speed", "mid" => msg["mid"], "speed" => 0.0})
    log(msg)
  when "scan_report"
    log(msg) if not msg["reports"].empty?
  else # this is a message that we don't handle yet, just log it
    #log("Got message that I don't handle: #{msg.inspect}")
  end
end

# This is the program entry point. Because of the __FILE_ trick below, 
# this will only be executed if the script is run as as "program" from
# the command line. Which happens to be *exactly* what RubyFC does
# when you give it a fleet file name.
def main

  # always write your fleet metadata first
  send({
      "type"       => "set_fleet_metadata",
      "author"     => "Clay Sampson",
      "fleet_name" => "Sit-N-Scan Example 1.0",
    })

  # Keep going forever, RubyFC will clean up the fleets automagically
  loop do
    # Read a message. Use a timeout of 1 second to 
    # be a good player and not try to eat all the
    # available CPU time by spinning in a loop.
    msg = Paidgeeks.read_object($stdin, 1)
    
    # If we did not get a message, loop again
    next if msg.nil?

    # process the message
    process(msg)
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
