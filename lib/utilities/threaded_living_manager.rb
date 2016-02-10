require 'thread'
require_relative './logging_thread'

module Paidgeeks
  class ThreadedLivingManager
    attr_reader :thread_continue

    def initialize
      @mutex = Mutex.new
      @thread_continue = true
      @thread = Paidgeeks::LoggingThread.new("#{APP_NAME}: #{self.class}") { work! } 
    end

    def do_synchronize &block
      @mutex.synchronize { block.call }
    end

    def alive?
      @thread_continue
    end

    def die
      @thread_continue = false
      @thread.join
      nil
    end
  end
end
