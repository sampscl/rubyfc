require 'rubygems'
require 'bundler/setup' 
require 'aspector'
require 'pp'
require 'facter'
require 'json'

module Paidgeeks
  module DebugUtils

    @@game_state = :not_started

    def self.terminal_program
      case Facter.value("operatingsystem")
      when "Ubuntu" ; "gnome-terminal"
      else            "bash" end
    end

    def self.user_input msg
      print msg
      $stdout.flush
      $stdin.gets.chomp
    end

    def self.print_help
      puts("Fleet Commander Debugger commands:")
      puts("init            => Initialize the game (call this before tick).")
      puts("game log        => Open a tail session for the game log.")
      puts("fleet log [fid] => Open a tail session for fleet fid's log file.")
      puts("pry             => Open a pry session. Note that all globals can be set here.")
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
        else
          puts("Unable to tick, game state is #{@@game_state}")
          return
        end
      end
      puts("New game state: #{@@game_state}")
    end

    def self.init
      result = (:not_started == @@game_state ? :init : :already_init)
      puts("Game already initialized.") if result == :already_init
      result
    end

    def self.fleet_log(gc, fid)
      fid = fid.to_i
      fn = gc.gs.fleets[fid][:log_stream].path
      Process.detach(Process.spawn(terminal_program, "-e", "less +F #{fn}"))
    end

    def self.game_log
      Process.detach(Process.spawn(terminal_program, "-e", "less +F #{$debug_log.path}"))
    end

    def self.pry_session(gc)
      puts("Be aware that calling DebugUtils functions within the pry session may behave strangely. Everything else should work though!")
      puts("Exit the pry session to return to the debugger.")
      binding.pry
    end

    def self.debug(gc)
      @@game_state = :in_progress if not gc.nil?
      while !SIGNAL_QUEUE.any?
        begin
          cmd = user_input("Command? ")
          case cmd
          when "help", "?"            ; print_help
          when "init"                 ; return init
          when /^fleet log (\d+)/     ; fleet_log(gc, $1)
          when "game log"             ; game_log
          when "pry"                  ; pry_session(gc)
          when "q", "quit"            ; puts("Quitting."); return :quit
          when /^t (\d+)$/            ; tick(gc, $1)
          when "t"                    ; tick(gc, "1")
          else                          puts("Unknown command: '#{cmd}'")
          end # case cmd
        rescue Exception => e
          puts("Debugger caught exception => #{e}")
          puts(e.backtrace.join("\n\tfrom: "))
        end
      end
    end
  end
end
