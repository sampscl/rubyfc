require_relative '../base_logging'
require 'thread'
module Paidgeeks
  module RubyFC
    module Logging
      module Engine
        class GameStateChangerLoggingAspect < BaseLogging

          @@gsc_mutex = Mutex.new
          def self.gsc_mutex
            @@gsc_mutex
          end

          ALL_MSG_HANDLERS = /.*_msg$/

          around ALL_MSG_HANDLERS, method_arg: true do |method, proxy, gs, msg, &block|
            GameStateChangerLoggingAspect::gsc_mutex.synchronize do
              if :debug == $log_level 
                if (!msg.has_key?("type") or method.to_s != "#{msg["type"]}_msg")
                  raise ArgumentError.new("Missing or incorrect message type: #{msg.inspect}")
                end
                if !msg.has_key?("fleet_source")
                  raise ArgumentError.new("All game state change messages require a fleet_source field: #{msg.inspect}")
                end
              end
              Paidgeeks.write_object(gs.journal, msg)

              proxy.call(gs, msg)
            end
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
