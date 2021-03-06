#!/usr/bin/env ruby
begin
  require 'pry'
rescue LoadError
  $stderr.write("Error loading pry gem, pry will not be available.\n")
end

begin
  require 'pry-nav'
rescue LoadError
  $stderr.write("Error loading pry-nav gem, pry-nav (debugger support) will not be available.\n")
end

require 'tempfile'
require_relative 'aifc-game'
require_relative '../lib/utilities/debug_utils'

Tempfile.open("rubyfc-debug-log") do |debug_log|

  # Hack! Makes debug life easy though.
  $debug_log = debug_log

  # Hack! This is really handy inside a Pry session though.
  $msg_hook = Proc.new {}

  class PaidgeeksHookAspect < Aspector::Base
    around :write_object, method_arg: true do |method, proxy, stream, object, &block|
      PP.pp(object, $debug_log, 80)
      $debug_log.flush
      result = proxy.call(stream, object)
      begin
        $msg_hook.call(object)
      rescue Exception => e
        $stderr.write("Debugger (hook) caught exception => #{e}\n")
        $stderr.write(e.backtrace.join("\n\tfrom: "))
      end
      result
    end
  end
  PaidgeeksHookAspect.apply(Paidgeeks, class_methods: true)

  # monkey patch run_game
  def run_game(gc)
    $gc = gc # make easily available to pry
    Paidgeeks::DebugUtils.debug(gc)
  end

  def debug_main
    main() if :init == Paidgeeks::DebugUtils.debug(nil)
  end

  if __FILE__ == $0
    debug_main
  end
end
