require_relative '../utilities/stream_comms'
require_relative '../utilities/mob'
require_relative 'all'
module Paidgeeks
  module RubyFC
    module Engine

      # The game state changer processes all messages that affect the game state. It
      # is what implements the memoization that allows game playback. As such, the
      # methods in this class form the official internal game API and the game-to-fleet
      # API. See the notes below.
      #
      # Notes:
      #
      # Messages that are sent to fleets after being processed are
      # renamed to end with "_notify", and this is what forms 99% of the
      # game-to-fleet API.
      #
      # Game coordinator will also send messages to the fleet that are not well-
      # defined in this file: game_config, begin_tick, and end_tick.
      #
      # Please note that the GameStateChanger class is, itself STATELESS. Keep it
      # that way. Also, note that GameStateChanger trusts its input. Callers are
      # responsible for ensuring that all messages are actionable as-is.
      class GameStateChanger

        # Send a message to a fleet. This is here to ensure that all messages
        # are journaled (see game_state_changer_logging.rb)
        # Returns:
        # - The message sent to the fleet, unencoded
        def self.msg_to_fleet(gs, fm, msg)
          fm.queue_output(Paidgeeks.encode(msg))
        end

        # Send a warning message to a fleet. This is not really a game state change,
        # but it will generate a fleet message. It's basically syntactic sugar for
        # msg_to_fleet. Note the name does not end in _msg, so this method will
        # NOT be journaled (but msg_to_fleet will, due to the logging aspect).
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "warn_fleet",
        #     "original_message" => the original message hash that caused this warning,
        #     "warning" => text string describing the warning (e.g. "source_ship invalid")
        #     "fleet_source" => false | true,
        #     "fid" => fleet id,
        #   }
        def self.warn_fleet(gs, msg)
          fleet = gs.fleets[msg["fid"]]
          msg_to_fleet(gs, fleet[:manager], msg)
        end

        # Tick and update the time. This also, somewhat unexpectedly, resets the "...in the last tick" state members.
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "tick"
        #     "fleet_source" => false | true,
        # }
        def self.tick_msg(gs, msg)
          gs.tick += 1
          gs.time = gs.tick * gs.config[:seconds_per_tick]
          gs.tick_scan_reports = []
          gs.munition_intercepts = []
        end

        # Update tick acknowledged for a fleet
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "tick_acknowledged",
        #     "tick" =>  tick,
        #     "fid" => fid,
        #     "fleet_source" => false | true,
        #   }
        def self.tick_acknowledged_msg(gs, msg)
          gs.fleets[msg["fid"]][:last_ack_tick] = msg["tick"]
        end

        # Set fleet metatdata (from the fleet itself)
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "set_fleet_metadata",
        #     "author" => "Author's name",
        #     "fleet_name" => "Name of the fleet",
        #     "fid" => fid,
        #     "fleet_source" => false | true,
        #   }
        def self.set_fleet_metadata_msg(gs, msg)
          fleet = gs.fleets[msg["fid"]]
          fm = fleet[:manager]
          fm.fleet_metadata["author"] = msg["author"]
          fm.fleet_metadata["fleet_name"] = msg["fleet_name"]
        end

        # Add a fleet. This also creates the fleet manager to manage the fleet.
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "add_fleet"
        #     "fid" => fleet id
        #     "ff" => fleet file to load
        #     "last_ack_tick" => initial value for the last acknowledged tick from this fleet
        #     "log_stream" => IO instance for fleet logging
        #     "fleet_source" => false | true,
        #   }
        def self.add_fleet_msg(gs, msg)
          mgr = Paidgeeks::RubyFC::Engine::FleetManager.new(msg["ff"], msg["fid"], msg["log_stream"])
          gs.add_fleet(msg["fid"], mgr, msg["last_ack_tick"], msg["log_stream"])
        end

        # Disqualify a fleet, also destroys all fleet's mobs
        #
        # This will generate a _notify message to the fleet.
        #
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "disqualify_fleet",
        #     "error" => descriptive string of the error
        #     "backtrace" => String containing the call stack at the time of the error
        #     "inspected_args" => Array of any relevant arguments pertaining to the error
        #     "fleet_source" => false | true,
        #   }
        def self.disqualify_fleet_msg(gs, msg)
          fleet = gs.fleets[msg["fid"]]
          fleet[:manager].fleet_state = :error
          fleet[:manager].fleet_metadata[:error] = msg["error"]
          fleet[:manager].fleet_metadata[:backtrace] = msg["backtrace"]
          fleet[:manager].fleet_metadata[:inspected_args] = msg["inspected_args"]
          msg_to_fleet(gs, fleet[:manager], msg.merge({"type" => "disqualify_fleet_notify"}))
          mids = fleet[:mobs].to_a
          mids.each do |mid|
            delete_mob_msg(gs, {
              "type" => "delete_mob",
              "mid" => mid,
              "reason" => "fleet disqualified"
              })
          end
        end

        # Update the fleet state
        #
        # This will generate a _notify message to the fleet.
        #
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "fleet_state",
        #     "fid" => fleet id,
        #     "state" => Fleet state, see Fleet class docs for possible values.
        #     "fleet_source" => false | true,
        #   }
        def self.fleet_state_msg(gs, msg)
          fleet = gs.fleets[msg["fid"]]
          fleet[:manager].fleet_state = msg["state"].to_sym
          msg_to_fleet(gs, fleet[:manager], msg.merge({"type" => "fleet_state_notify"}))
        end

        # Integrate a mob (kinematic repositioning). This also does game rule enforcement for position:
        # all mobs must remain on the playing field. To prevent mobs from "hiding" just on the other side
        # (and complicating scanning logic), motion is not wrapped around a-la pacman. Instead, mobs will
        # just stop at the barrier created by the boundary.
        #
        # Also, note that the msg parameter is modified directly by this function. This is not
        # typical behavor for the gsc, since it normally will trust any input. In this case, it
        # does not trust the positional data (x and y position). This is due to the Mob class
        # being playing-field agnostic but the game needs to enforce the rules somewhere. The other
        # sensible option would be to create a rules enforcement class that proxies access to the
        # game state changer and therefore ensures that all the rules are being followed. That
        # feels like overkill at this point.
        #
        # This will generate a _notify message to the fleet.
        #
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "integrate_mob",
        #     "x_pos" => x position (units)
        #     "y_pos" => y position (units),
        #     "heading" => heading (radians),
        #     "velocity" => velocity (units per second),
        #     "turn_rate" => turn rate (radians per second),
        #     "valid_time" => the time this data is valid (seconds),
        #     "turn_start_time" => If turn_rate != 0, this is the time to start turning in order to reach a specific heading,
        #     "turn_stop_time" => If turn_rate != 0, this is the time to stop turning in order to reach a specific heading,
        #     "turn_stop" => The time to stop turning in order to reach a specific heading,
        #     "fid" => fleet id,
        #     "mid" => mob id,
        #     "fleet_source" => false | true,
        #   }
        # Returns:
        # - mob => The mob that was just integrated
        def self.integrate_mob_msg(gs, msg)

          # clamp x and y to be inside the playfield (this is a case of legal motion creating illegal game state)
          if msg["x_pos"] < 0.0
            msg = msg.merge({"x_pos" => 0.0})
          end

          if msg["x_pos"] >= gs.config[:field_width]
            msg = msg.merge({"x_pos" => gs.config[:field_width] - 1.0})
          end

          if msg["y_pos"] < 0
            msg = msg.merge({"y_pos" => 0.0})
          end

          if msg["y_pos"] >= gs.config[:field_height]
            msg = msg.merge({"y_pos" => gs.config[:field_height] - 1.0})
          end

          # store updated values
          mob = gs.mobs[msg["mid"]]
          mob.x_pos = msg["x_pos"]
          mob.y_pos= msg["y_pos"]
          mob.heading = msg["heading"]
          mob.velocity = msg["velocity"]
          mob.turn_rate = msg["turn_rate"]
          mob.valid_time = msg["valid_time"]
          mob.turn_start_time = msg["turn_start_time"]
          mob.turn_stop_time = msg["turn_stop_time"]
          mob.turn_stop = msg["turn_stop"]

          # notify fleet
          fleet = gs.fleets[msg["fid"]]
          msg_to_fleet(gs, fleet[:manager], msg.merge({"type" => "integrate_mob_notify"}))

          # return the mob
          mob
        end

        # Report results of mission. This not really a game state change, but
        # it does need to be recorded and run through the same general processing
        # as every other message.
        def self.mission_report_msg(gs, msg)
          # nothing to do
        end

        # Reduce fleet credits
        #
        # This will generate a _notify message to the fleet.
        #
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "reduce_credits",
        #     "amount" => Amount of credits to subtract, (negative values will increase credits!)
        #     "fid" => fleet id losing the credits
        #     "fleet_source" => false | true,
        #   }
        def self.reduce_credits_msg(gs, msg)
          fleet = gs.fleets[msg["fid"]]
          fleet[:credits] -= msg["amount"]
          msg = msg.merge({
            "new_balance" => fleet[:credits],
            "type" => "reduce_credits_notify",
            })
          msg_to_fleet(gs, fleet[:manager], msg)
        end

        # Set fleet credits
        #
        # This will generate a _notify message to the fleet.
        #
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "set_credits",
        #     "amount" => Amount of credits
        #     "fid" => fleet id losing the credits
        #     "fleet_source" => false | true,
        #   }
        def self.set_credits_msg(gs, msg)
          fleet = gs.fleets[msg["fid"]]
          fleet[:credits] = msg["amount"]
          msg_to_fleet(gs, fleet[:manager], msg.merge({"type" => "set_credits_notify"}))
        end

        # Reduce a mobs energy
        #
        # This will generate a _notify message to the fleet.
        #
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "reduce_energy",
        #     "amount" => Amount of energy to subtract (negative values will increase energy!)
        #     "mid" => mob id
        #     "fleet_source" => false | true,
        #   }
        def self.reduce_energy_msg(gs, msg)
          mob = gs.mobs[msg["mid"]]
          mob.energy -= msg["amount"]
          fleet = gs.fleets[mob.fid]
          msg = msg.merge({
            "new_energy" => mob.energy,
            "type" => "reduce_energy_notify"
            })
          msg_to_fleet(gs, fleet[:manager], msg)
        end

        # Set a mobs energy
        #
        # This will generate a _notify message to the fleet.
        #
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "set_energy",
        #     "new_energy" => Amount of energy
        #     "mid" => mob id
        #     "fleet_source" => false | true,
        #   }
        def self.set_energy_msg(gs, msg)
          mob = gs.mobs[msg["mid"]]
          mob.energy = msg["new_energy"]
          fleet = gs.fleets[mob.fid]
          msg_to_fleet(gs, fleet[:manager], msg.merge({"type" => "set_energy_notify"}))
        end

        # Create a new mob
        #
        # This will generate a _notify message to the fleet.
        #
        # Parameters:
        # - msg => A Hash {
        #     "type" => "create_mob",
        #     "template" => A Class used as a template for the mob,
        #     "create_time" => Time of creation for the mob
        #     "x_pos" => position of new mob,
        #     "y_pos" => position of new mob,
        #     "heading" => heading of new mob,
        #     "velocity" => velocity of new mob,
        #     "turn_rate" => turn rate of new mob,
        #     "valid_time" => time of validity for the new mob,
        #     "turn_start_time" => turn start time of new mob,
        #     "turn_stop_time" => turn stop time of new mob,
        #     "turn_stop" => turn stop of new mob,
        #     "fid" => fleet id of new mob
        #     "mid" => mob id of new mob (must be unique for entire game!),
        #     "energy" => starting energy fot mob
        #     "hitpoints" => starting hit points for mob
        #     "last_scan_tick" => tick of the last scan this mom performed,
        #     "target_mid" => mid of target. This is not required to be a valid mid,
        #     "launch_param" => launch parameter for the mob, can be anything.
        #     "fleet_source" => false | true,
        #   }
        def self.create_mob_msg(gs, msg)
          mob = Paidgeeks::RubyFC::Mob.from_msg(msg)
          gs.mobs[mob.mid] = mob
          gs.fleets[mob.fid][:mobs].add(mob.mid)
          fleet = gs.fleets[mob.fid]
          msg_to_fleet(gs, fleet[:manager], msg.merge({"type" => "create_mob_notify"}))
        end

        # Delete a mob
        #
        # This will generate a _notify message to the fleet.
        #
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "delete_mob",
        #     "mid" => Mob's mid,
        #     "reason" => A string reason for deleting the mob
        #     "fleet_source" => false | true,
        #   }
        def self.delete_mob_msg(gs, msg)
          mob = gs.mobs[msg["mid"]]
          fleet = gs.fleets[mob.fid]
          fleet[:mobs].delete(mob.mid)
          gs.mobs.delete(mob.mid)
          msg_to_fleet(gs, fleet[:manager], msg.merge({"type" => "delete_mob_notify"}))
        end

        # Notify fleet one if its munitions intercepted something, this doesn't really change the gamestate,
        # but it does follow the *_notify pattern for fleet notification for interesting events. It also
        # notifies the mission that someone scored a hit.
        #
        # This will generate a _notify message to the fleet.
        #
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "munition_intercept",
        #     "munition_mid" => mid of the interceptor,
        #     "target_mid" => mid of the target,
        #     "remaining_target_hitpoints" => hitpoints remaining on target after intercept, will be <=0 if target destroyed
        #     "fleet_source" => false | true,
        #   }
        def self.munition_intercept_msg(gs, msg)
          mob = gs.mobs[msg["munition_mid"]]
          fleet = gs.fleets[mob.fid]
          gs.mission.event_munition_intercept(gs, msg["munition_mid"], msg["target_mid"]) if !gs.mission.nil?
          msg_to_fleet(gs, fleet[:manager], msg.merge({"type" => "munition_intercept_notify"}))
          gs.munition_intercepts << msg
        end

        # Notify fleet of munition target updates. This doesn't really change the gamestate,
        # but it does follow the *_notify pattern for fleet notification for interesting events.
        #
        # This will generate a _notify message to the fleet.
        #
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "missile_target_update",
        #     "munition_mid" => mun_mob.mid,
        #     "target_mid" => target_mob.mid,
        #     "x_pos" => target_mob.x_pos,
        #     "y_pos" => target_mob.y_pos,
        #     "heading" => target_mob.heading,
        #     "velocity" => target_mob.velocity,
        #     "valid_time" => target_mob.valid_time,
        #     "template" => target_mob.template.class.name,
        #     "fleet_source" => false | true,
        #   }
        def self.missile_target_update_msg(gs, msg)
          mob = gs.mobs[msg["munition_mid"]]
          fleet = gs.fleets[mob.fid]
          msg_to_fleet(gs, fleet[:manager], msg.merge({"type" => "missile_target_update_notify"}))
        end

        # Reduce mobs hitpoints
        #
        # This will generate a _notify message to the fleet.
        #
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "reduce_hitpoints",
        #     "mid" => mid of the mob to modify
        #     "amount" => number of hitpoints to subtract, set to negative to increase hitpoints
        #     "fleet_source" => false | true,
        #   }
        def self.reduce_hitpoints_msg(gs, msg)
          mob = gs.mobs[msg["mid"]]
          mob.hitpoints -= msg["amount"]
          fleet = gs.fleets[mob.fid]
          msg_to_fleet(gs, fleet[:manager], msg.merge({"type" => "reduce_hitpoints_notify"}))
        end

        # Scan
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "scan",
        #     "source_ship" => mid of the scanning ship,
        #     "azimuth" => absolute azimuth, in degrees, with 0 => North and 90 => East, must be a Float (0.0, not 0)
        #     "range" => The max range of the scan, must be > 0 (see config field_width and field_height) for default playing field dimensions, must be a Float (0.0 not 0)
        #     "fleet_source" => false | true,
        # }
        def self.scan_msg(gs, msg)
          source_ship = gs.mobs[msg["source_ship"]]
          source_ship.last_scan_tick = gs.tick
          x = source_ship.x_pos
          y = source_ship.y_pos
          range = msg["range"]
          range_squared = range * range

          # Get the ship template class; for the playback system, the template
          # is a String, not a class. In that case, transform it into the
          # ship class.
          template = source_ship.template.is_a?(String) ? Paidgeeks.class_from_string(source_ship.template) : source_ship.template
          half_theta = 0.5 * (template.scanned_area / range) # scan twice this wide
          center = msg["azimuth"]
          if center > 180.0 # negative angles to left, makes math below work
            center -= 360.0
          end
          center = Paidgeeks.deg_to_rad(center)
          start = Paidgeeks::normalize_to_circle(center - half_theta)
          stop = Paidgeeks::normalize_to_circle(center + half_theta)

          reports = []

          scan_slices = Proc.new do |slice_pairs|
            gs.mobs.each do |mid, mob|
              next if mob.fid == source_ship.fid
              rel_ang = Paidgeeks::normalize_to_circle(Paidgeeks::relative_angle(x, y, mob.x_pos, mob.y_pos))
              #puts("#{source_ship.mid} to #{mid} => #{Paidgeeks.rad_to_deg(rel_ang)} #{Paidgeeks.rad_to_deg start} => #{Paidgeeks.rad_to_deg center} => #{Paidgeeks.rad_to_deg stop}")
              range2 = Paidgeeks.range2(x,y,mob.x_pos,mob.y_pos)
              slice_pairs.each do |pair|
                if rel_ang >= pair[0] and rel_ang < pair[1] and range2 <= range_squared
                  reports << {
                    "mid" => mid,
                    "x_pos" => mob.x_pos,
                    "y_pos" => mob.y_pos,
                    "heading" => mob.heading,
                    "velocity" => mob.velocity,
                    "turn_rate" => 0.0,
                    "valid_time" => mob.valid_time,
                    "turn_start_time" => 0.0,
                    "turn_stop_time" => 0.0,
                    "turn_stop" => 0.0,
                    "template" => mob.template.kind_of?(String) ? mob.template : mob.template.name,
                    "fid" => mob.fid,
                  }
                end # inside slice pair
              end # slice pairs
            end # each mob
          end # Proc

          if stop < start # crosses north
            scan_slices.call([[start, Paidgeeks::TWOPI],[0.0, stop]])
          else # does not cross north
            scan_slices.call([[start, stop]])
          end

          scan_report = {
            "type" => "scan_report",
            "scan_msg" => msg,
            "last_scan_tick" => source_ship.last_scan_tick,
            "scan_width" => Paidgeeks.rad_to_deg(2.0*half_theta),
            "reports" => reports,
          }
          fleet = gs.fleets[source_ship.fid]
          msg_to_fleet(gs, fleet[:manager], scan_report)
          gs.tick_scan_reports << scan_report
        end

        # Set mob speed.
        #
        # This will generate a _notify message to the fleet.
        #
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "set_speed",
        #     "mid" => Mob id
        #     "speed" => The new speed
        #     "fid" => fleet id
        #     "fleet_source" => false | true,
        #   }
        def self.set_speed_msg(gs, msg)
          mob = gs.mobs[msg["mid"]]
          mob.velocity = msg["speed"]
          fleet = gs.fleets[mob.fid]
          msg_to_fleet(gs, fleet[:manager], msg.merge({"type" => "set_speed_notify"}))
        end

        # Turn mob to a new heading
        #
        # This will generate a _notify message to the fleet.
        #
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "turn_to",
        #     "mid" => mob id of the ship to turn,
        #     "heading" => final heading, in degrees, must be a Float (0.0, not 0) and [0.0, 360.0)
        #     "direction" => "clockwise" or "counterclockwise"
        #     "fid" => fleet id
        #     "fleet_source" => false | true,
        # }
        def self.turn_to_msg(gs, msg)
          mob = gs.mobs[msg["mid"]]
          mob = mob.turn_to(Paidgeeks::deg_to_rad(msg["heading"]), msg["direction"].to_sym)
          gs.mobs[mob.mid] = mob
          fleet = gs.fleets[mob.fid]
          msg_to_fleet(gs, fleet[:manager], msg.merge({"type" => "turn_to_notify"}))
        end

        # Turn mob forever so it flies in a circle
        #
        # This will generate a _notify message to the fleet.
        #
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "turn_to",
        #     "mid" => mob id of the ship to turn,
        #     "rate" => Turn rate, in degrees/second, must be a Float (0.0, not 0)
        #     "direction" => "clockwise" or "counterclockwise"
        #     "fid" => fleet id
        #     "fleet_source" => false | true,
        # }
        def self.turn_forever_msg(gs, msg)
          mob = gs.mobs[msg["mid"]]
          mob = mob.turn_forever(Paidgeeks::deg_to_rad(msg["rate"]), msg["direction"].to_sym)
          fleet = gs.fleets[mob.fid]
          gs.mobs[mob.mid] = mob
          msg_to_fleet(gs, fleet[:manager], msg.merge({"type" => "turn_forever_notify"}))
        end
      end
    end
  end
end
require_relative '../logging/game_engine/game_state_changer_logging.rb'
