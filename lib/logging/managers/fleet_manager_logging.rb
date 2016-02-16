require_relative '../base_logging'
module Paidgeeks
  module RubyFC
    module Logging
      module Managers
        class FleetManagerLoggingAspect < BaseLogging
          around :log, method_arg: true do |method, proxy, *args, &block|
            result = nil
            begin
              result = proxy.call(*args, &block)
              BaseLogging.debug("#{BaseLogging.inout} #{self.tick} #{self.class}.#{method}: #{args[0].to_s}")
            rescue => e
              self.fleet_state = :error
              self.fleet_metadata[:error] = "Exception in log: #{e}"
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
              BaseLogging.info("#{BaseLogging.inout} #{self.tick} #{self.class}.#{method}(#{args.join(", ")}) => #{result}")
            rescue => e
              self.fleet_state = :error
              self.fleet_metadata[:error] = "Exception in process: #{e}"
              self.fleet_metadata[:backtrace] = e.backtrace.join("\n\tfrom: ")
              self.fleet_metadata[:inspected_args] = args.collect { |arg| arg.inspect }
              BaseLogging.error("#{BaseLogging.inout} #{self.tick} #{self.class}.#{method}: #{self.inspect}")
            end
            result
          end
          [:cleanup, :start, :begin_tick, :cache_inputs, :process_logging, :process_inputs, :end_tick, :flush_output, :queue_output].each do |sym|
            around sym, method_arg: true do |method, proxy, *args, &block|
              begin
                BaseLogging.debug("#{BaseLogging.enter} #{self.tick} #{self.class}.#{method}(#{args.join(", ")})")
                result = proxy.call(*args, &block)
                BaseLogging.debug("#{BaseLogging.leave} #{self.tick} #{self.class}.#{method} => #{result}")
                result
              rescue => e
                self.fleet_state = :error
                self.fleet_metadata[:error] = "Exception in #{method}: #{e}"
                self.fleet_metadata[:backtrace] = e.backtrace.join("\n\tfrom: ")
                self.fleet_metadata[:inspected_args] = args.collect { |arg| arg.inspect }
                BaseLogging.error("#{BaseLogging.inout} #{self.tick} #{self.class}.#{method}: #{self.inspect}")
              end
            end
          end
        end
        FleetManagerLoggingAspect.apply(Paidgeeks::RubyFC::Managers::FleetManager)
      end
    end
  end
end
