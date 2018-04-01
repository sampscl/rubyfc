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

require 'pp'
require 'optparse'
require 'stringio'
require_relative '../config/constants'
require_relative '../lib/utilities/stream_comms'

# save copies
$real_stdin = $stdin
$real_stdout = $stdout
$real_stderr = $stderr
REAL_STDIN = STDIN
REAL_STDOUT = STDOUT
REAL_STDERR = STDERR

# make fakes
$fake_stdin = StringIO.new("r+")
$fake_stdout = StringIO.new("r+")
$fake_stderr = StringIO.new("r+")
FAKE_STDIN = $fake_stdin
FAKE_STDOUT = $fake_stdout
FAKE_STDERR = $fake_stderr

$stdin = $fake_stdin
$stdout = $fake_stdout
$stderr = $fake_stderr
# STDIN = FAKE_STDIN
# STDOUT = FAKE_STDOUT
# STDERR = FAKE_STDERR

module DebugFleet
  def self.require_relative(f)
    path = File.expand_path(f)
    Kernel::load(path)
    DebugFleet.define_singleton_method(:send_msg_to_fleet) { |msg| process_msg(msg) }
  end
end

module Paidgeeks
  module FleetDebugger

    def self.parse_command_line
      result = {
        fleet: nil,
        game_log_file_name: nil,
      }
      OptionParser.new do |opts|
        opts.on("--fleet=", "Specify fleet file") do |opt|
          result[:fleet] = opt
        end
        opts.on("--fid=", "Specify fleet id from game log; this will control which messages the debug fleet receives") do |opt|
          result[:fid] = opt.to_i
        end
        opts.on("--log_file=", "Specify the game log file") do |opt|
          result[:game_log_file_name] = opt
        end

      end.parse!

      result
    end

    def self.io_fake
      $stdin = $fake_stdin
      $stdout = $fake_stdout
      $stderr = $fake_stderr
    end

    def self.io_real
      $stdin = $real_stdin
      $stdout = $real_stdout
      $stderr = $real_stderr
    end

    def self.user_input(msg)
      $real_stdout.print msg
      $real_stdout.flush
      $real_stdin.gets.chomp
    end

    def self.print_help
      $real_stdout.puts("Fleet Debugger commands:")
      $real_stdout.puts("init            => Initialize the debugging session by loading the fleet.")
      $real_stdout.puts("pry             => Open a pry session.")
      $real_stdout.puts("q or quit       => Quit the debugger.")
      $real_stdout.puts("m [num]         => Send [num] messages from the game log. Num is optional and defaults to 1.")
    end

    def self.pry_session()
      $real_stdout.puts("Exit the pry session to return to the debugger.")
      $real_stdout.puts("The fleet is loaded, so all it's modules and globals are available to pry.")
      binding.pry
    end

    def self.init(fleet)
      $real_stdout.puts("loading fleet #{fleet}")
      DebugFleet.require_relative(fleet)
    end

    def self.fleet_would_receive(msg, fid)
      return false if msg["fid"] && msg["fid"] != fid
      return false if msg["fleet_source"] == true

      case msg["type"]
      when /_notify$/    ; return true
      when "game_config" ; return true
      when "tick"        ; return true
      when "end_tick"    ; return true
      when "scan_report" ; return true
      end
      false
    end

    def self.show_interaction(msg, resp, log)
      $real_stdout.write("--------------------------------------------------------------------------------")
      $real_stdout.write("\nMessage   =>\n")
      PP.pp(msg, $real_stdout)
      $real_stdout.write("\nResponses =>\n")
      PP.pp(resp, $real_stdout)
      $real_stdout.write("\nFleet Log =>\n")
      PP.pp(log, $real_stdout)
      $real_stdout.write("\n")
      $real_stdout.flush
    end

    def self.issue(journal, fid, msg_count)
      $real_stdout.puts("Issuing #{msg_count} message(s)")
      # Send msg_count messages to fleet
      msg_count = msg_count.to_i
      while msg_count > 0

        # get next message that fid would have seen during the game
        msg = nil
        begin
          msg = Paidgeeks.read_object(journal)
          #$real_stdout.puts("fleet_would_receive(#{msg}, #{fid}) => #{fleet_would_receive(msg, fid)}")
        end until fleet_would_receive(msg, fid)

        msg_count -= 1
        DebugFleet::send_msg_to_fleet(msg)
        $stdout.rewind
        $stderr.rewind
        resp = []
        $stdout.lines.each { |line| resp << Paidgeeks.decode(line.chomp) }
        log = $stderr.read

        $stdout.string = ""
        $stderr.string = ""

        show_interaction(msg, resp, log)
      end
    end

    def self.main
      opts = parse_command_line
      journal_file_name = File.join(Paidgeeks::RubyFC::LOG_DIR, opts[:game_log_file_name])
      journal = opts[:game_log_file_name] == "-" ? $real_stdin : File.open(journal_file_name,"rt")
      opts[:journal] = journal
      cmd = "help"
      loop do
        begin
          new_cmd = user_input("Command? [#{cmd}]: ")
          if new_cmd == ""
            new_cmd = cmd
          else
            cmd = new_cmd
          end
          case cmd
          when "help", "?"            ; print_help
          when "init"                 ; init(opts[:fleet])
          when "pry"                  ; io_real ; pry_session ; io_fake
          when "q", "quit"            ; $real_stdout.puts("Quitting."); return :quit
          when /^m (\d+)$/            ; issue(journal, opts[:fid], $1)
          when "m"                    ; issue(journal, opts[:fid], "1")
          else                          $real_stdout.puts("Unknown command")
          end # case cmd
        rescue Exception => e
          $real_stderr.puts("Debugger caught exception => #{e}")
          $real_stderr.puts(e.backtrace.join("\n\tfrom: "))
        end
      end
    end
  end
end

if __FILE__ == $0
  Paidgeeks::FleetDebugger::main
end
