require_relative '../base_logging'
module Paidgeeks
  module RubyFC
    module Logging
      module Engine
        class GameStateChangerLoggingAspect < BaseLogging
          ALL_MSG_HANDLERS = /.*_msg$/

          around ALL_MSG_HANDLERS, method_arg: true do |method, proxy, gs, msg, &block|
            if :debug == $log_level and (!msg.has_key?("type") or method.to_s != "#{msg["type"]}_msg")
              raise ArgumentError.new("Missing or incorrect message type: #{msg.inspect}")
            end
            Paidgeeks.write_object(gs.journal, msg)

            proxy.call(gs, msg)
          end

          around :msg_to_fleet, method_arg: true do |method, proxy, gs, fm, msg, &block|
            msg = msg.merge({"fleet_source" => false})
            Paidgeeks.write_object(gs.journal, msg)

            proxy.call(gs, fm, msg)
          end
        end
        GameStateChangerLoggingAspect.apply(Paidgeeks::RubyFC::Engine::GameStateChanger, class_methods: true)
      end
    end
  end
end
