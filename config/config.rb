require 'yaml'
require_relative 'constants'
module Paidgeeks
  module RubyFC
    class Config
      cfg = YAML.load_file(File.join(Paidgeeks::RubyFC::CFG_DIR, "config.yml"))
      $max_messages_per_tick = cfg["max_messages_per_tick"] 
      $unacknowledged_ticks_limit = cfg["unacknowledged_ticks_limit"] 
      $max_game_ticks = cfg["max_game_ticks"]
      $log_level = cfg["log_level"]
    end
  end
end
