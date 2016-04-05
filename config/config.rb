require 'yaml'
require_relative 'constants'
module Paidgeeks
  module RubyFC
    class Config

      def self.load(gs)
        # turn the config yaml file into gamestate variables
        cfg = YAML.load_file(File.join(Paidgeeks::RubyFC::CFG_DIR, "config.yml"))
        cfg.each do |k, v|
          gs.config[k.to_sym] = v
        end
        $log_level = gs.config[:log_level]
      end
    end
  end
end
