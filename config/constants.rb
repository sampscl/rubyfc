module Paidgeeks
  module RubyFC
    # Program-wide constants go here
    APP_NAME = "RubyFC"
    APP_DIR = File.expand_path('../../', __FILE__)
    LOG_DIR = File.join(APP_DIR, "log")
    CFG_DIR = File.join(APP_DIR, "config")
    DB_YML_PATH = File.join(CFG_DIR, "database.yml")
  end
end
