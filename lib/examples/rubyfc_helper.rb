#!/usr/bin/env ruby

#
# This file contains helper code for novice programmers. 
#
require_relative '../utilities/stream_comms'
require_relative '../utilities/mob'

$fleet = {
  "author"     => "NOBODY",
  "fleet_name" => "You forgot to set the $fleet!"
}

$mobs = {}

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

# placeholders
def on_idle
end
def integrate_mob_notify(msg)
  mob = $mobs[msg["mid"]]
  msg.each { |k,v| mob.send("#{k}=", v) if mob.respond_to?("#{k}=") }
end
def create_mob_notify(msg)
  mob = Paidgeeks::Mob.from_msg(msg)
  $mobs[mob.mid] = mob
end
def delete_mob_notify(msg)
  mid = msg["mid"]
  $mobs.delete(mid)
end

# Process messages received from the game
# Parameters:
# - msg => The message; this will be a Hash object with
#   String keys.
def process(msg)
  case msg["type"] # all messages have a "type" field
  when "begin_tick" # beginning of a game tick
    on_idle
  when "warn_fleet", "disqualify_fleet_notify", "fleet_state_notify"
    log(msg)
  when "integrate_mob_notify"
    integrate_mob_notify(msg)
  when "create_mob_notify"
    create_mob_notify(msg)
  when "delete_mob_notify"
    delete_mob_notify(msg)
  when "end_tick" # end of a game tick, ALWAYS ACKNOWLEDGE THIS
    send({"type" => "tick_acknowledged", "tick" => msg["tick"]})
    log(msg)
  else # this is a message that we don't handle yet
  end
end

# This is the program entry point. Because of the __FILE_ trick below, 
# this will only be executed if the script is run as as "program" from
# the command line. Which happens to be *exactly* what RubyFC does
# when you give it a fleet file name.
def rubyfc_helper

  # always write your fleet metadata first
  send({"type" => "set_fleet_metadata"}.merge($fleet))

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
