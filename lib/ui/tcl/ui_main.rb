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
            @root = TkRoot.new { title "Fleet Commander Playback - #{log_file_name}" }
            @lists_frame = TkFrame.new(@root) { borderwidth 3 ; relief "flat" }
            @fleets = TkListbox.new(@lists_frame) { height 4 }
            @mobs = TkListbox.new(@lists_frame) { height 25 }
            @log = TkListbox.new(@lists_frame) { height 10 }
            @game_field = TkCanvas.new(@root) { width 1024 ; height 768 }
            @status_frame = TkFrame.new(@root) { borderwidth 3 ; relief "flat" }
            @status_label = TkLabel.new(@status_frame) { }

            @fleets.pack fill: "both", expand: 1
            @mobs.pack fill: "both", expand: 1
            @log.pack fill: "both", expand: 1

            @status_label.pack fill: "both", expand: 1

            @lists_frame.grid row: 0, column: 0, sticky: "nsew"
            @game_field.grid row: 0, column: 1, rowspan: 2, sticky: "nsew"
            @status_frame.grid row: 1, column: 0, columnspan: 2, sticky: "nsew"

            Tk.mainloop
          ensure
            log_file.close()
          end
        end
      end
    end
  end
end
