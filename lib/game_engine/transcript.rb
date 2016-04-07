require 'pp'
require_relative '../../config/constants'
require_relative '../utilities/stream_comms'

module Paidgeeks
  module RubyFC
    module Engine
      class Transcript
        def self.playback_until(opts, &stop)
          # open journal
          File.open(File.join(Paidgeeks::RubyFC::LOG_DIR, opts[:game_log_file_name]),"rt") do |journal|
            msg = nil
            while !stop.call() and (nil != (msg = Paidgeeks::read_object(journal)))
              pp(msg)
              puts()
            end
          end # end journal open
        end # end run
      end
    end
  end
end
