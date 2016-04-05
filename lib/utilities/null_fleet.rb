#!/usr/bin/env ruby
require_relative './stream_comms'

# Keep going until we're not alive anymore
$alive = true
begin
  Paidgeeks.read_object($stdin, 1)
end until !$alive
