require 'test_helper'

class FleetTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "fleet has many games" do
    f = Fleet.create!
    g = Game.create!
    f.games << g
    f.save!

    g = Game.find(g.id)
    f = Fleet.find(f.id)

    assert f.games.include?(g)

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

  test "destroy fleet also destroys fleet ranking" do
    f = Fleet.create
    fr = FleetRanking.create
    fr.fleet = f
    f.save!
    fr.save!

    f.destroy

    assert Fleet.find_by_id(f.id) == nil
    assert FleetRanking.find_by_id(fr.id) == nil
  end
end
