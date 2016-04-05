require_relative '../base_logging'
module Paidgeeks
  module RubyFC
    module Logging
      module Engine
        class GameCoordinatorLoggingAspect < BaseLogging
          around :game_setup, method_arg: true do |method, proxy, *args, &block|
            BaseLogging.info("#{BaseLogging.enter} #{self.class}.#{method}: #{args}")
            result = proxy.call(*args)
            BaseLogging.info("#{BaseLogging.leave} #{self.class}.#{method} => #{result}")

            BaseLogging.info("Monkey patched templates:")

            Paidgeeks::RubyFC::Templates.constants.each do |t|
              klass = Paidgeeks::RubyFC::Templates.const_get(t)
              BaseLogging.info("\t#{klass} =>")
              (klass.methods - Object.methods).each do |m|
                BaseLogging.info("\t\t#{m} == #{klass.send(m)}")
              end
            end

            result
          end

          around :game_tick, method_arg: true do |method, proxy, *args, &block|
            BaseLogging.debug("#{BaseLogging.enter} #{self.class}.#{method}: #{args}")
            result = proxy.call(*args)
            BaseLogging.debug("#{BaseLogging.leave} #{self.class}.#{method} => #{result}")
            result
          end
        end
        GameCoordinatorLoggingAspect.apply(Paidgeeks::RubyFC::Engine::GameCoordinator)
      end
    end
  end
end
