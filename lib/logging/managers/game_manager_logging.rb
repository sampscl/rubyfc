require_relative '../base_logging'
module Paidgeeks
  module RubyFC
    module Logging
      module Managers
        class GameManagerLoggingAspect < BaseLogging
          ALL_MSG_HANDLERS = /.*_msg$/

          around ALL_MSG_HANDLERS, method_arg: true do |method, proxy, *args, &block|
            self.journal(args[0])
            result = proxy.call(*args, &block)
            result
          end

          around :cleanup, method_arg: true do |method, proxy, *args, &block|
            BaseLogging.info("#{BaseLogging.enter} #{self.class}.#{method}(#{args.join(", ")})")
            result = proxy.call(*args, &block)
            BaseLogging.info("#{BaseLogging.leave} #{self.class}.#{method} => #{result}")
            result
          end

          around :run_game, method_arg: true do |method, proxy, *args, &block|
            BaseLogging.info("#{BaseLogging.enter} #{self.class}.#{method}(#{args.join(", ")})")
            result = proxy.call(*args, &block)
            BaseLogging.info("#{BaseLogging.leave} #{self.class}.#{method} => #{result}")
            result
          end

          around :create_fleet, method_arg: true do |method, proxy, *args, &block|
            self.journal({"type" => "create_fleet", "fleet_file" => args[0]})
            BaseLogging.info("#{BaseLogging.enter} #{self.class}.#{method}(#{args.join(", ")})")
            result = proxy.call(*args, &block)
            BaseLogging.info("#{BaseLogging.leave} #{self.class}.#{method} => #{result.inspect}")
            result
          end

          around :journal, method_arg: true do |method, proxy, *args, &block|
            BaseLogging.debug("#{BaseLogging.enter} #{self.class}.#{method}(#{args.join(", ")})")
            result = proxy.call(*args, &block)
            BaseLogging.debug("#{BaseLogging.leave} #{self.class}.#{method}")
            result
          end

          around :playback_while, method_arg: true do |method, proxy, *args, &block|
            BaseLogging.info("#{BaseLogging.enter} #{self.class}.#{method}(#{args.join(", ")})")
            result = proxy.call(*args, &block)
            BaseLogging.info("#{BaseLogging.leave} #{self.class}.#{method} => #{result}")
            result
          end

          around :end_game, method_arg: true do |method, proxy, *args, &block|

            result = proxy.call(*args, &block)
            BaseLogging.write("#{BaseLogging.inout} End of game fleet status:")
            fleets.each do |fid, fleet|
              md = fleet.fleet_metadata
              md.each do |k,v|
                BaseLogging.write("#{BaseLogging.inout} Fleet #{fleet.fleet_id} #{k} => #{v}")            
              end
            end
            result
          end
        end
        GameManagerLoggingAspect.apply(Paidgeeks::RubyFC::Managers::GameManager)
      end
    end
  end
end
