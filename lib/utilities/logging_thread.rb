require 'thread'
module Paidgeeks
  class LoggingThread < Thread
    attr_accessor :log_thread_name
    def initialize(name="", *args, &block)
      self.log_thread_name = name
      super(*args,&wrap(&block))
    end

    def gettid
      syscall(186)
    end
    
    def wrap(&block)
      return lambda do
        begin 
          warn("#{self.log_thread_name} TID => #{gettid}")
          yield
        rescue Exception, StandardError, LoadError=> ex
          warn("error in thread: #{ex.message}")
          warn("#{ex.backtrace.join("\n\tfrom: ")}")
        ensure
          warn("thread exiting: #{log_thread_name}")
        end
      end
    end
  end
end
