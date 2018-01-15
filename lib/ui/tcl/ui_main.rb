require 'rubygems'
require 'bundler/setup'
require 'tk'

module Paidgeeks
  module RubyFC
    module UI
      class TkMain

        # Get log file and log file name as [log_file, log_file_name]. Call
        # log_file.close() when done with it.
        def open_log_file
          case ARGV[0]
          when "-"
            [$stdin, "stdin"]
          when nil
            lfn = Tk.getOpenFile
            File.exist?(lfn) ? [File.open(lfn), lfn] : [nil, nil]
          else
            File.exist?(ARGV[0]) ? [File.open(ARGV[0]), ARGV[0]] : [nil, nil]
          end
        end

        def run
          log_file, log_file_name = open_log_file
          return 0 if log_file.nil?
          begin
            root = TkRoot.new { title "Fleet Commander Playback - #{log_file_name}" }
            fleets = TkListbox.new(root) { height 4 }
            mobs = TkListbox.new(root) { height 25 }
            log = TkListbox.new(root) { height 10 }
            game_field = TkCanvas.new(root) { }
            status = TkLabel.new(root) { }

            fleets.grid row: 0, column: 0
            mobs.grid row: 1, column: 0
            log.grid row: 2, column: 0
            game_field.grid row: 0, column: 1, rowspan: 3
            status.grid row: 3, column: 0, columnspan: 2

            Tk.mainloop
          ensure
            log_file.close()
          end
        end
      end
    end
  end
end
