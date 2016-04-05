require 'pp'
require 'minitest/autorun'

require_relative '../../lib/game_engine/all'
require_relative '../helpers/fleet_manager_test_helper'

class TtgPcaTest < MiniTest::Test
  def setup
    # need some static and some moving mobs
    @gs = Paidgeeks::RubyFC::Engine::GameState.new($stdout)
    ndx = 1

    # 1
    @gs.add_fleet(ndx, FleetManagerTestHelper.new(ndx), 0, $stdout)
    @gs.mobs[ndx] = Paidgeeks::RubyFC::Mob.from_msg({ 
      "x_pos" => 1000,
      "y_pos" => 1000,
      "heading" => 0.0,
      "velocity" => 0.0,
      "mid" => ndx,
      "fid" => ndx,
      })
    ndx += 1

    # 2
    @gs.add_fleet(ndx, FleetManagerTestHelper.new(ndx), 0, $stdout)
    @gs.mobs[ndx] = Paidgeeks::RubyFC::Mob.from_msg({ 
      "x_pos" => 1000,
      "y_pos" => 1500,
      "heading" => 0.0,
      "velocity" => 0.0,
      "mid" => ndx,
      "fid" => ndx,
      })
    ndx += 1

    # 3
    @gs.add_fleet(ndx, FleetManagerTestHelper.new(ndx), 0, $stdout)
    @gs.mobs[ndx] = Paidgeeks::RubyFC::Mob.from_msg({ 
      "x_pos" => 1000,
      "y_pos" => 1500,
      "heading" => Paidgeeks::deg_to_rad(270.0),
      "velocity" => 1.0,
      "mid" => ndx,
      "fid" => ndx,
      })
    ndx += 1

    # 4
    @gs.add_fleet(ndx, FleetManagerTestHelper.new(ndx), 0, $stdout)
    @gs.mobs[ndx] = Paidgeeks::RubyFC::Mob.from_msg({ 
      "x_pos" => 1001,
      "y_pos" => 1500,
      "heading" => Paidgeeks::deg_to_rad(270.0),
      "velocity" => 1.0,
      "mid" => ndx,
      "fid" => ndx,
      })
    ndx += 1

    # 5
    @gs.add_fleet(ndx, FleetManagerTestHelper.new(ndx), 0, $stdout)
    @gs.mobs[ndx] = Paidgeeks::RubyFC::Mob.from_msg({ 
      "x_pos" => 1000,
      "y_pos" => 1500,
      "heading" => Paidgeeks::deg_to_rad(90.0),
      "velocity" => 1.0,
      "mid" => ndx,
      "fid" => ndx,
      })
    ndx += 1

    # 6
    @gs.add_fleet(ndx, FleetManagerTestHelper.new(ndx), 0, $stdout)
    @gs.mobs[ndx] = Paidgeeks::RubyFC::Mob.from_msg({ 
      "x_pos" => 1001,
      "y_pos" => 1501,
      "heading" => Paidgeeks::deg_to_rad(180.0),
      "velocity" => 1.0,
      "mid" => ndx,
      "fid" => ndx,
      })
    ndx += 1

    # 7
    @gs.add_fleet(ndx, FleetManagerTestHelper.new(ndx), 0, $stdout)
    @gs.mobs[ndx] = Paidgeeks::RubyFC::Mob.from_msg({ 
      "x_pos" => 1000,
      "y_pos" => 1001,
      "heading" => Paidgeeks::deg_to_rad(0.0),
      "velocity" => 1.0,
      "mid" => ndx,
      "fid" => ndx,
      })
    ndx += 1

    # 8
    @gs.add_fleet(ndx, FleetManagerTestHelper.new(ndx), 0, $stdout)
    @gs.mobs[ndx] = Paidgeeks::RubyFC::Mob.from_msg({ 
      "x_pos" => 1001,
      "y_pos" => 1000,
      "heading" => Paidgeeks::deg_to_rad(90.0),
      "velocity" => 1.0,
      "mid" => ndx,
      "fid" => ndx,
      })
    ndx += 1
  end

  def test_ttg_pca
    assert(Float::INFINITY == Paidgeeks::ttg_pca_mobs(@gs.mobs[1], @gs.mobs[2]), "Static mobs have infinite time-to-go.")
    assert(Float::INFINITY == Paidgeeks::ttg_pca_mobs(@gs.mobs[3], @gs.mobs[4]), "Mobs moving in parallel infinite time-to-go.")
    assert(Paidgeeks::is_near(1.0,Paidgeeks::ttg_pca_mobs(@gs.mobs[1], @gs.mobs[4])), "1 mob moving to another has a sensible ttg.")
    assert(Paidgeeks::is_near(1.0,Paidgeeks::ttg_pca_mobs(@gs.mobs[4], @gs.mobs[1])), "Order does not matter.")
    assert(Paidgeeks::is_near(0.5,Paidgeeks::ttg_pca_mobs(@gs.mobs[4], @gs.mobs[5])), "2 mobs headed for each other will collide.")
    assert(Paidgeeks::is_near(1.0,Paidgeeks::ttg_pca_mobs(@gs.mobs[5], @gs.mobs[6])), "2 mobs headed for each other will collide (5,6).")
    assert(Paidgeeks::is_near(-1.0,Paidgeeks::ttg_pca_mobs(@gs.mobs[7], @gs.mobs[8])), "2 mobs already past pca will have negative ttg (7,8).")
  end
end
