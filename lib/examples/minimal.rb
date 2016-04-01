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

# Process messages received from the game
# Parameters:
# - msg => The message; this will be a Hash object with
#   String keys.
def process(msg)
  case msg["type"] # all messages have a "type" field
  when "begin_tick" # beginning of a game tick
    log(msg)
  when "end_tick" # end of a game tick
    send({"type" => "tick_acknowledged", "tick" => msg["tick"]})
    log(msg)
  else # this is a message that we don't handle yet, just log it
    log("Got message that I don't handle: #{msg.inspect}")
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
      "fleet_name" => "Minimal Example 1.0",
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
