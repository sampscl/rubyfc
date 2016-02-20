require 'yaml'
require_relative 'constants'
module Paidgeeks
  module RubyFC
    class Config
      # turn the config yaml file into global variables
      cfg = YAML.load_file(File.join(Paidgeeks::RubyFC::CFG_DIR, "config.yml"))
      cfg.each do |k, v|
        eval("$#{k}=#{v.inspect}")
      end
    end
  end
end
