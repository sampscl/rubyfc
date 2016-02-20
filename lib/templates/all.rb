# this logic requires all files in the same directory as this file.
dir = File.expand_path('..', __FILE__)

Dir["#{dir}/*.rb"].each {|file_name| require file_name unless file_name == __FILE__}
