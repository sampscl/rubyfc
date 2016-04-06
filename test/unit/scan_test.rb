require 'pp'
require 'minitest/autorun'

require_relative '../../lib/game_engine/all'
require_relative '../helpers/fleet_manager_test_helper'

class ScanTest < MiniTest::Test
  def setup
    # need 5 mobs: center, ne, se, sw, nw. All with different fids
    @gs = Paidgeeks::RubyFC::Engine::GameState.new($stdout)
    @gs.add_fleet(1, FleetManagerTestHelper.new(1), 0, $stdout)
    @gs.mobs[1] = Paidgeeks::RubyFC::Mob.from_msg({ # center
      "x_pos" => 1000,
      "y_pos" => 1000,
      "mid" => 1,
      "fid" => 1,
      })
    @gs.add_fleet(2, FleetManagerTestHelper.new(2), 0, $stdout)
    @gs.mobs[2] = Paidgeeks::RubyFC::Mob.from_msg({ # ne
      "x_pos" => 1500,
      "y_pos" => 1500,
      "mid" => 2,
      "fid" => 2,
      })
    @gs.add_fleet(3, FleetManagerTestHelper.new(3), 0, $stdout)
    @gs.mobs[3] = Paidgeeks::RubyFC::Mob.from_msg({ # se
      "x_pos" => 1500,
      "y_pos" => 500,
      "mid" => 3,
      "fid" => 3,
      })
    @gs.add_fleet(4, FleetManagerTestHelper.new(4), 0, $stdout)
    @gs.mobs[4] = Paidgeeks::RubyFC::Mob.from_msg({ # sw
      "x_pos" => 500,
      "y_pos" => 500,
      "mid" => 4,
      "fid" => 4,
      })
    @gs.add_fleet(5, FleetManagerTestHelper.new(5), 0, $stdout)
    @gs.mobs[5] = Paidgeeks::RubyFC::Mob.from_msg({ # nw
      "x_pos" => 500,
      "y_pos" => 1500,
      "mid" => 5,
      "fid" => 5,
      })

    @gs.add_fleet(6, FleetManagerTestHelper.new(6), 0, $stdout)
    @gs.mobs[6] = Paidgeeks::RubyFC::Mob.from_msg({ # exact north
      "x_pos" => 1000,
      "y_pos" => 1500,
      "mid" => 6,
      "fid" => 6,
      })
    @gs.add_fleet(7, FleetManagerTestHelper.new(7), 0, $stdout)
    @gs.mobs[7] = Paidgeeks::RubyFC::Mob.from_msg({ # slight west of north
      "x_pos" => 995,
      "y_pos" => 1500,
      "mid" => 7,
      "fid" => 7,
      })
    @gs.add_fleet(8, FleetManagerTestHelper.new(8), 0, $stdout)
    @gs.mobs[8] = Paidgeeks::RubyFC::Mob.from_msg({ # slight east of north
      "x_pos" => 1005,
      "y_pos" => 1500,
      "mid" => 8,
      "fid" => 8,
      })

    @gs.add_fleet(9, FleetManagerTestHelper.new(9), 0, $stdout)
    @gs.mobs[9] = Paidgeeks::RubyFC::Mob.from_msg({ # exact south
      "x_pos" => 1000,
      "y_pos" => 500,
      "mid" => 9,
      "fid" => 9,
      })
    @gs.add_fleet(10, FleetManagerTestHelper.new(10), 0, $stdout)
    @gs.mobs[10] = Paidgeeks::RubyFC::Mob.from_msg({ # slight west of south
      "x_pos" => 995,
      "y_pos" => 500,
      "mid" => 10,
      "fid" => 10,
      })
    @gs.add_fleet(11, FleetManagerTestHelper.new(11), 0, $stdout)
    @gs.mobs[11] = Paidgeeks::RubyFC::Mob.from_msg({ # slight east of south
      "x_pos" => 1005,
      "y_pos" => 500,
      "mid" => 11,
      "fid" => 11,
      })
  end

  def test_scan
    gsc = Paidgeeks::RubyFC::Engine::GameStateChanger

    gsc::scan_msg(@gs, {"type" => "scan", "fleet_source" => false, "source_ship" => 1, "azimuth" => 45.0, "range" => 1000.0})
    sr = @gs.fleets[1][:manager].queued_output.pop
    assert(1 == sr["reports"].size, "There should be 1 scan report at 45")
    assert(2 == sr["reports"].first["mid"], "Mob 2 should be reported at 45")

    gsc::scan_msg(@gs, {"type" => "scan",  "fleet_source" => false, "source_ship" => 1, "azimuth" => 135.0, "range" => 1000.0})
    sr = @gs.fleets[1][:manager].queued_output.pop
    assert(1 == sr["reports"].size, "There should be 1 scan report at 135")
    assert(3 == sr["reports"].first["mid"], "Mob 3 should be reported at 135")

    gsc::scan_msg(@gs, {"type" => "scan",  "fleet_source" => false, "source_ship" => 1, "azimuth" => 225.0, "range" => 1000.0})
    sr = @gs.fleets[1][:manager].queued_output.pop
    assert(1 == sr["reports"].size, "There should be 1 scan report at 225")
    assert(4 == sr["reports"].first["mid"], "Mob 4 should be reported at 225")

    gsc::scan_msg(@gs, {"type" => "scan",  "fleet_source" => false, "source_ship" => 1, "azimuth" => 315.0, "range" => 1000.0})
    sr = @gs.fleets[1][:manager].queued_output.pop
    assert(1 == sr["reports"].size, "There should be 1 scan report at 315")
    assert(5 == sr["reports"].first["mid"], "Mob 5 should be reported at 315")

    gsc::scan_msg(@gs, {"type" => "scan",  "fleet_source" => false, "source_ship" => 1, "azimuth" => 0.0, "range" => 1000.0})
    sr = @gs.fleets[1][:manager].queued_output.pop
    assert(3 == sr["reports"].size, "There should be 3 scan reports at 0")
    sr["reports"].each do |report|
      assert([6,7,8].include?(report["mid"]), "Mobs 6-8 should be reported at 0")
    end

    gsc::scan_msg(@gs, {"type" => "scan",  "fleet_source" => false, "source_ship" => 1, "azimuth" => 180.0, "range" => 1000.0})
    sr = @gs.fleets[1][:manager].queued_output.pop
    assert(3 == sr["reports"].size, "There should be 3 scan reports at 180")
    sr["reports"].each do |report|
      assert([9,10,11].include?(report["mid"]), "Mobs 9-11 should be reported at 180")
    end
  end
end
