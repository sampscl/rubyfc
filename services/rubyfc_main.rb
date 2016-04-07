#!/usr/bin/env ruby
require 'active_record'
require 'yaml'

SIGNAL_QUEUE = []
Signal.trap "TERM" do
  SIGNAL_QUEUE << :TERM
end
Signal.trap "INT" do
  SIGNAL_QUEUE << :INT
end

db = YAML::load_file(Paidgeeks::RubyFC::DB_YML_PATH)
env = ENV.has_key?("RAILS_ENV") ? ENV["RAILS_ENV"] : "production"
ActiveRecord::Base.establish_connection(db[env])

def main
  while not SIGNAL_QUEUE.any?
    sleep 1.0
  end
end

if __FILE__ == $0
  main
end
