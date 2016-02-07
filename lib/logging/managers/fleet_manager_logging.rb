require_relative '../base_logging'
module Paidgeeks
  module RubyFC
    module Logging
      module Managers
        class FleetManagerLoggingAspect < BaseLogging
          around :log, method_arg: true do |method, proxy, *args, &block|
            result = proxy.call(*args, &block)
            begin
              BaseLogging.write("#{BaseLogging.inout} (#{self.tick}) #{self.class}.#{method}: #{args[0].to_s}")
            rescue => e
              self.fleet_state = :error
              self.fleet_metadata[:error] = "Exception in log: #{e}"
              self.fleet_metadata[:backtrace] = e.backtrace.join("\n\t")
              self.fleet_metadata[:inspected_args] = [args[0].inspect]
            end
            result
          end
          around :process, method_arg: true do |method, proxy, *args, &block|
            begin
              arg_str = args.join(", ")
              result = proxy.call(*args, &block)
              BaseLogging.write("#{BaseLogging.inout} (#{self.tick}) #{self.class}.#{method}(#{arg_str}) => #{result}")
            rescue => e
              self.fleet_state = :error
              self.fleet_metadata[:error] = "eception in process: #{e}"
              self.fleet_metadata[:backtrace] = e.backtrace.join("\n\t")
              self.fleet_metadata[:inspected_args] = args.collect { |arg| arg.inspect }
            end
            result
          end
        end
        FleetManagerLoggingAspect.apply(Paidgeeks::RubyFC::Managers::FleetManager)
      end
    end
  end
end
