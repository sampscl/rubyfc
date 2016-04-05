require_relative '../base_logging'
module Paidgeeks
  module RubyFC
    module Logging
      module Engine
        class SanitizedMessageProcessorLoggingAspect < BaseLogging
          ALL_MSG_HANDLERS = /.*_msg$/

          around ALL_MSG_HANDLERS, method_arg: true do |method, proxy, msg, fm, gs, &block|
            # set fleet_source for all messages coming from a fleet
            msg = msg.merge({"fleet_source" => true})
            # don't bother if not debugging, this just adds confusion to the journal
            Paidgeeks.write_object(gs.journal, msg) if :debug == $log_level

            proxy.call(msg, fm, gs)
          end
        end
        SanitizedMessageProcessorLoggingAspect.apply(Paidgeeks::RubyFC::Engine::SanitizedMessageProcessor)
      end
    end
  end
end
