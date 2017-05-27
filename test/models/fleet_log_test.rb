require 'test_helper'

class FleetLogTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "fleet log belong fleet" do
    f = Fleet.create
    fl = FleetLog.create
    fl.fleet = f
    f.save!
    fl.save!

    f = Fleet.find(f.id)
    fl = FleetLog.find(fl.id)

    assert fl.fleet == f
  end

  test "destroy fleet also destroys fleet logs" do
    f = Fleet.create
    fl = FleetLog.create
    fl.fleet = f
    f.save!
    fl.save!

    f.destroy

    assert Fleet.find_by_id(f.id) == nil
    assert FleetLog.find_by_id(fl.id) == nil
  end

end
