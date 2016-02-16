require 'aspector'
module Paidgeeks
  module RubyFC
    module Logging
      class BaseLogging < Aspector::Base
        def self.write(msg=nil, &block)
          warn msg if msg 
          block.call if block
        end

        def self.log_level
          $log_level
        end

        def self.debug(msg=nil, &block)
          write(msg, &block) if log_level == :debug
        end

        def self.info(msg=nil, &block)
          write(msg, &block) if [:debug, :info].include?(log_level)
        end

        def self.error(msg=nil, &block)
          write(msg, &block)
        end

        def self.log_time
          Time.now.strftime('%F %T')
        end

        def self.enter
          "#{log_time} ===>"
        end

        def self.leave
          "#{log_time} <==="
        end

        def self.inout
          "#{log_time} <==>"
        end
      end
    end
  end
end
