require 'rubygems'
require 'bundler/setup' 
require 'aspector'
require 'pp'

module Paidgeeks
  module DebugUtils

    @@game_state = :not_started

    def self.user_input msg
      print msg
      $stdout.flush
      $stdin.gets.chomp
    end

    def self.print_help
      puts("AIFC Debugger commands:")
      puts("init            => Initialize the game (call this before tick).")
      puts("fleet log [fid] => Open a log tail session for fleet fid's log file.")
      puts("pry             => Open a pry session (the pry gem must be installed).")
      puts("q or quit       => Quit the debugger.")
      puts("t [num]         => Tick the game [num] times. Must call init first. Num is optional and defaults to 1.")
    end

    def self.tick(gc, ticks)
      last_time = gc.gs.time if gc
      if ticks.nil? or ticks.empty?
        ticks = 1
      else
        ticks = ticks.to_i
      end
      while ticks > 0
        ticks = ticks - 1
        if :in_progress == @@game_state
          @@game_state = gc.game_tick(last_time)
          last_time = gc.gs.time
          puts(" end tick ".center(80,"*"))
          puts("New game state: #{@@game_state}")
        else
          puts("Unable to tick, game state is #{@@game_state}")
          return
        end
      end
    end

    def self.init
      result = (:not_started == @@game_state ? :init : :already_init)
      puts("Game already initialized.") if result == :already_init
      result
    end

    def self.fleet_log(gc, fid)
      fid = fid.to_i
      fn = gc.gs.fleets[fid][:log_stream].path
      Process.detach(Process.spawn("gnome-terminal", "-e", "less +F #{fn}"))
    end

    def self.pry_session(gc)
      puts("Be aware that calling DebugUtils functions within the pry session may behave strangely. Everything else should work though!")
      puts("Exit the pry session to return to the debugger.")
      binding.pry
    end

    def self.debug(gc)
      @@game_state = :in_progress if not gc.nil?
      while !SIGNAL_QUEUE.any?
        cmd = user_input("Command? ")
        case cmd
        when "help", "?"            ; print_help
        when "init"                 ; return init
        when /^fleet log (\d+)/     ; fleet_log(gc, $1)
        when "pry"                  ; pry_session(gc)
        when "q", "quit"            ; puts("Quitting."); return :quit
        when /^t (\d+)$/            ; tick(gc, $1)
        when "t"                    ; tick(gc, "1")
        else                          puts("Unknown command: #{cmd}")
        end # case cmd
      end
    end
  end
end
