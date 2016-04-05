require_relative '../../lib/utilities/stream_comms'

class FleetManagerTestHelper
  attr_reader :queued_output
  attr_accessor :fleet_id

  def initialize(fid=0)
    @fleet_id = fid
    @queued_output = []
  end

  def queue_output(encoded)
    @queued_output << Paidgeeks.decode(encoded)
  end
end
