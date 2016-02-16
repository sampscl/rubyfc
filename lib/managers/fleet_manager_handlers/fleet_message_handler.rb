module Paidgeeks
  module RubyFC
    module Managers
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
        def set_fleet_metadata(msg, fleet_manager, game_manager)
          check_field_count(msg, 3)
          check_field_of_type(msg, "author", String)
          check_field_of_type(msg, "fleet_name", String)
          set_fleet(msg, fleet_manager)
          game_manager.set_fleet_metadata_msg(msg)
        end

        def start(msg, fleet_manager, game_manager)
          # This message is actually not meant to be received
          # from the fleet, though it does not hurt anything if it is.
          check_field_count(msg, 2)
          check_field_of_type(msg, "log_stream_file_name", String)
          set_fleet(msg, fleet_manager)
          game_manager.start_msg(msg)
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
        def tick_acknowledged(msg, fleet_manager, game_manager)
          check_field_count(msg, 2)
          check_field_of_type(msg, "tick", Fixnum)
          set_fleet(msg, fleet_manager)
          game_manager.tick_acknowledged_msg(msg)
        end

        # private stuff
        private
        def set_fleet(msg, fleet_manager)
          msg["fleet"] = fleet_manager.fleet_id
        end
        def check_field_count(msg, count)
          raise ArgumentError, "#{count} fields are required in message #{msg}" unless count == msg.length
        end

        def check_field_of_type(msg, field_name, type)
          raise ArgumentError, "field #{field_name} missing from message #{msg}" unless msg.has_key?(field_name)
          raise ArgumentError "field #{field_name} is a #{msg[field_name].class.name} but should be a #{type.name} in message #{msg}" unless msg[field_name].kind_of?(type)
        end
      end
    end
  end
end
