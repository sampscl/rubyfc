require_relative '../base_logging'
module Paidgeeks
  module RubyFC
    module Logging
      module Engine
        class FleetManagerLoggingAspect < BaseLogging

          around :log, method_arg: true do |method, proxy, *args, &block|
            result = nil
            begin
              result = proxy.call(*args, &block)
              BaseLogging.debug("#{BaseLogging.inout} #{self.class}.#{method}: #{args[0].to_s}")
            rescue => e
              self.fleet_state = :error
              self.fleet_metadata[:error] = "Exception in #{self.class}.#{method}: #{e}"
              self.fleet_metadata[:backtrace] = e.backtrace.join("\n\tfrom:")
              self.fleet_metadata[:inspected_args] = [args[0].inspect]
              BaseLogging.error("#{BaseLogging.inout} #{self.tick} #{self.class}.#{method}: #{self.inspect}")
            end
            result
          end
          around :process, method_arg: true do |method, proxy, *args, &block|
            result = nil
            begin
              result = proxy.call(*args, &block)
              BaseLogging.info("#{BaseLogging.inout} #{self.class}.#{method}(#{args.join(", ")}) => #{result}")
            rescue => e
              self.fleet_state = :error
              self.fleet_metadata[:error] = "Exception in #{self.class}.#{method}: #{e}"
              self.fleet_metadata[:backtrace] = e.backtrace.join("\n\tfrom: ")
              self.fleet_metadata[:inspected_args] = args.collect { |arg| arg.inspect }
              BaseLogging.error("#{BaseLogging.inout} #{self.class}.#{method}: #{self.inspect}")
            end
            result
          end
          [:cleanup, :cache_inputs, :process_logging, :process_inputs, :flush_output, :queue_output].each do |sym|
            around sym, method_arg: true do |method, proxy, *args, &block|
              begin
                BaseLogging.debug("#{BaseLogging.enter} #{self.class}.#{method}(#{args.join(", ")})")
                result = proxy.call(*args, &block)
                BaseLogging.debug("#{BaseLogging.leave} #{self.class}.#{method} => #{result}")
                result
              rescue => e
                self.fleet_state = :error
                self.fleet_metadata[:error] = "Exception in #{self.class}.#{method}: #{e}"
                self.fleet_metadata[:backtrace] = e.backtrace.join("\n\tfrom: ")
                self.fleet_metadata[:inspected_args] = args.collect { |arg| arg.inspect }
                BaseLogging.error("#{BaseLogging.inout} #{self.class}.#{method}: #{self.inspect}")
              end
            end
          end
        end
        FleetManagerLoggingAspect.apply(Paidgeeks::RubyFC::Engine::FleetManager)
      end
    end
  end
end
