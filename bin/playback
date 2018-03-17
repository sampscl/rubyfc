#!/usr/bin/env ruby

require_relative '../lib/ui/qt4/ui_main'

def main
    ui = Paidgeeks::RubyFC::UI::Qt4Main.new
    begin
      ui.run
    ensure
      # make siure we will clean all fleets
      ui.gs.fleets.each {|_fid, fleet| fleet[:manager].cleanup }
    end
end

if __FILE__ == $0
  main
end
