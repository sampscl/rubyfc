module Paidgeeks
  module RubyFC
    module Engine
      # This class implements the rules for how messages from a fleet are handled. As such,
      # the methods of this class form the official fleet to game API.
      class FleetMessageHandler
        # Set fleet metadata
        # Parameters:
        # - msg => The message, in the form: 
        #   {
        #     "type" => "set_fleet_metadata", 
        #     "author" => "Author's name", 
        #     "fleet_name" => "Name of the fleet",
        #   }
        def set_fleet_metadata(msg, smp, fm, gs)
          check_field_count(msg, 3)
          check_field_of_type(msg, "author", String)
          check_field_of_type(msg, "fleet_name", String)
          msg["fid"] = fm.fleet_id
          smp.set_fleet_metadata_msg(msg, fm, gs)
        end

        # Acknowledges that the fleet has finished processing a game tick.
        # This message should be sent every tick. if it is not, the game
        # is allowed to flag the fleet as "errored". If that happens, 
        # the fleet forefits the game.
        # Parameters:
        # - msg => The message, in the form:
        #   {
        #     "type" => "tick_acknowledged",
        #     "tick" =>  tick,
        #   }
        def tick_acknowledged(msg, smp, fm, gs)
          check_field_count(msg, 2)
          check_field_of_type(msg, "tick", Fixnum)
          msg["fid"] = fm.fleet_id
          smp.tick_acknowledged_msg(msg, fm, gs)
        end

        # Launch a ship. This message is ignored if 
        # source_ship is unable to launch for some reason,
        # Common reasons include: not enough energy, not
        # enough credits, and wrong source ship (not all
        # ships can launch other ships). The newly created
        # ship will begin life at the current position of
        # source_ship.
        # Parameters:
        # - msg => The message, in the form:
        #   {
        #     "type" => "launch",
        #     "ship_type" => "ship type to launch" (Cruiser, Fighter, Gunship, or scenario-defined),
        #     "source_ship" => mid of the ship that will launch ship_type
        #     "launch_param" => launch parameter from the fleet, useful to assign fleet-specific missions to ships. Can be anything.
        #   }
        def launch(msg, smp, fm, gs)
          check_field_count(msg, 4)
          check_field_of_type(msg, "ship_type", String)
          check_field_of_type(msg, "source_ship", Fixnum)
          check_field_exists(msg, "launch_param")
          msg["fid"] = fm.fleet_id
          smp.launch_msg(msg, fm, gs)
        end

        # Fire a munition. This message is ignored if 
        # source_ship is unable to fire for some reason,
        # Common reasons include: not enough energy, not
        # enough credits, and wrong source ship (not all
        # ships can fire munitions). The newly created
        # munition will begin life at the current position of
        # source_ship.
        # Parameters:
        # - msg => The message, in the form:
        #   {
        #     "type" => "fire",
        #     "munition_type" => "ship type to launch" (Missile, Rocket),
        #     "munition_heading" => The heading, in degrees, to give the new munition
        #     "source_ship" => mid of the ship that will launch ship_type
        #     "target" => mid of the target, can be 0 if there is no specific target. Has no effect for rockets.
        #     "launch_param" => launch parameter from the fleet, useful to assign fleet-specific missions to ships. Can be anything.
        #   }
        def fire(msg, smp, fm, gs)
          check_field_count(msg, 6)
          check_field_of_type(msg, "source_ship", Fixnum)
          check_field_of_type(msg, "munition_type", String)
          check_field_of_type(msg, "munition_heading", Float)
          check_field_of_type(msg, "target", Fixnum)
          check_field_exists(msg, "launch_param")
          msg["fid"] = fm.fleet_id
          smp.fire_msg(msg, fm, gs)
        end

        # Scan a region. Note that the area scanned depends on the range of the scan. The area scanned is
        # defined in the game config, this causes the width of the scan to vary depending on the range. 
        # This constraint is there to prevent fast and accurate scanning of the entire game area. The area 
        # scanned is a pie slice starting at the source ship and ending range units away at the specified azimuth.
        # 
        # The width of the pie slice is adjusted automatically to enforce the scanned area rule. The 
        # formula for calculating the scan width is:
        #   width_in_radians = scanned_area / range
        #
        # The range of the scan is automatically adjusted according to the game configuration settings.
        # 
        # The result of a scan will only include other fleet's mobs.
        #
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "scan",
        #     "source_ship" => mid of the scanning ship,
        #     "azimuth" => absolute azimuth, in degrees, with 0 => North and 90 => East, must be a Float (0.0, not 0)
        #     "range" => The max range of the scan  must be > 0 (see config field_width and field_height) for default playing field dimensions, must be a Float (0.0 not 0)
        # }
        def scan(msg, smp, fm, gs)
          check_field_count(msg, 4)
          check_field_of_type(msg, "source_ship", Fixnum)
          check_field_of_type(msg, "azimuth", Float)
          check_field_of_type(msg, "range", Float)
          msg["fid"] = fm.fleet_id
          smp.scan_msg(msg, fm, gs)
        end

        # Set the speed of a mob
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "set_speed",
        #     "mid" => mob id of the ship to set speed on,
        #     "speed" => the new speed, units/second, will be clamped to the max speed of the mob template, must be a Float (0.0, not 0)
        # }
        def set_speed(msg, smp, fm, gs)
          check_field_count(msg, 3)
          check_field_of_type(msg, "mid", Fixnum)
          check_field_of_type(msg, "speed", Float)
          msg["fid"] = fm.fleet_id
          smp.set_speed_msg(msg, fm, gs)
        end

        # Turn to a specific heading
        # Parameters:
        # - msg => A Hash: {
        #     "type" => "turn_to",
        #     "mid" => mob id of the ship to turn,
        #     "heading" => final heading, in degrees, must be a Float (0.0, not 0)
        #     "direction" => "clockwise" or "counterclockwise"
        # }
        def turn_to(msg, smp, fm, gs)
          check_field_count(msg, 4)
          check_field_of_type(msg, "mid", Fixnum)
          check_field_of_type(msg, "heading", Float)
          check_field_of_type(msg, "direction", String)
          msg["fid"] = fm.fleet_id
          smp.turn_to_msg(msg, fm, gs)
        end

        # Turn a mob so it moves in a circle
        # Parameters: 
        # - msg => A Hash: {
        #     "type" => "turn_forever",
        #     "mid" => mob id of the ship to turn,
        #     "rate" => turn rate in degrees/second, must be > 0
        #     "direction" => "clockwise" or "counterclockwise"
        #  }
        def turn_forever(msg, smp, fm, gs)
          check_field_count(msg, 4)
          check_field_of_type(msg, "mid", Fixnum)
          check_field_of_type(msg, "rate", Float)
          check_field_of_type(msg, "direction", String)
          msg["fid"] = fm.fleet_id
          smp.turn_forever_msg(msg, fm, gs)
        end

        # private stuff
        private
        def check_field_count(msg, count)
          raise ArgumentError, "#{count} fields are required in message #{msg}" unless count == msg.length
        end

        def check_field_exists(msg, field_name)
          raise ArgumentError, "field #{field_name} missing from message #{msg}" unless msg.has_key?(field_name)
        end

        def check_field_of_type(msg, field_name, type)
          check_field_exists(msg, field_name)
          raise ArgumentError, "field #{field_name} is a #{msg[field_name].class.name} but should be a #{type.name} in message #{msg}" unless msg[field_name].kind_of?(type)
        end
      end
    end
  end
end
