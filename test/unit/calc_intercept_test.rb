require 'pp'
require 'minitest/autorun'

require_relative '../../lib/game_engine/all'
require_relative '../helpers/fleet_manager_test_helper'

class CalcInterceptTest < MiniTest::Test
  def setup
    # need some static and some moving mobs
    @gs = Paidgeeks::RubyFC::Engine::GameState.new($stdout)
    ndx = 1
    # 1
    @gs.add_fleet(ndx, FleetManagerTestHelper.new(ndx), 0, $stdout)
    @gs.mobs[ndx] = Paidgeeks::RubyFC::Mob.from_msg({ # center
      "x_pos" => 1000,
      "y_pos" => 1000,
      "heading" => 0.0,
      "velocity" => 1.0,
      "mid" => ndx,
      "fid" => ndx,
      })
    ndx += 1

    # 2
    @gs.add_fleet(ndx, FleetManagerTestHelper.new(ndx), 0, $stdout)
    @gs.mobs[ndx] = Paidgeeks::RubyFC::Mob.from_msg({ # center
      "x_pos" => 1000,
      "y_pos" => 1001,
      "heading" => 0.0,
      "velocity" => 0.0,
      "mid" => ndx,
      "fid" => ndx,
      })
    ndx += 1

    # 3
    @gs.add_fleet(ndx, FleetManagerTestHelper.new(ndx), 0, $stdout)
    @gs.mobs[ndx] = Paidgeeks::RubyFC::Mob.from_msg({ # center
      "x_pos" => 1001,
      "y_pos" => 1001,
      "heading" => Paidgeeks::deg_to_rad(180.0),
      "velocity" => 1.0,
      "mid" => ndx,
      "fid" => ndx,
      })
    ndx += 1

    # 4
    @gs.add_fleet(ndx, FleetManagerTestHelper.new(ndx), 0, $stdout)
    @gs.mobs[ndx] = Paidgeeks::RubyFC::Mob.from_msg({ # center
      "x_pos" => 1000,
      "y_pos" => 1001,
      "heading" => Paidgeeks::deg_to_rad(180.0),
      "velocity" => 1.0,
      "mid" => ndx,
      "fid" => ndx,
      })
    ndx += 1

    # 5
    @gs.add_fleet(ndx, FleetManagerTestHelper.new(ndx), 0, $stdout)
    @gs.mobs[ndx] = Paidgeeks::RubyFC::Mob.from_msg({ # center
      "x_pos" => 1000,
      "y_pos" => 999,
      "heading" => Paidgeeks::deg_to_rad(180.0),
      "velocity" => 0.5,
      "mid" => ndx,
      "fid" => ndx,
      })
    ndx += 1

    # 6
    @gs.add_fleet(ndx, FleetManagerTestHelper.new(ndx), 0, $stdout)
    @gs.mobs[ndx] = Paidgeeks::RubyFC::Mob.from_msg({ # center
      "x_pos" => 1000,
      "y_pos" => 999,
      "heading" => Paidgeeks::deg_to_rad(180.0),
      "velocity" => 1.0,
      "mid" => ndx,
      "fid" => ndx,
      })
    ndx += 1
  end

  def test_calc_intercept

    result = Paidgeeks::calc_intercept_mobs(@gs.mobs[1], @gs.mobs[2])
    assert(result[0] == true, "Moving mobs should be able to intercept")
    assert(Paidgeeks::is_near(result[1],0.0), "mob 1 => mob 2 intercept should be North")
    assert(Paidgeeks::is_near(result[2],1.0), "mob 1 => mob 2 intercept should be in 1 second")

    result = Paidgeeks::calc_intercept_mobs(@gs.mobs[2], @gs.mobs[1])
    assert(result[0] == false, "Impossible intercepts should say so")

    result = Paidgeeks::calc_intercept_mobs(@gs.mobs[1], @gs.mobs[3])
    assert(result[0] == true, "Moving mobs should be able to intercept")
    assert(Paidgeeks::is_near(result[1],Paidgeeks::deg_to_rad(90.0)), "mob 1 => mob 3 intercept should be East")
    assert(Paidgeeks::is_near(result[2],1.0), "mob 1 => mob 3 intercept should be in 1 second")

    result = Paidgeeks::calc_intercept_mobs(@gs.mobs[1], @gs.mobs[4])
    assert(result[0] == true, "Moving mobs should be able to intercept")
    assert(Paidgeeks::is_near(result[1],Paidgeeks::deg_to_rad(0.0)), "mob 1 => mob 4 intercept should be North")
    assert(Paidgeeks::is_near(result[2],0.5), "mob 1 => mob 4 intercept should be in 0.5 seconds")

    result = Paidgeeks::calc_intercept_mobs(@gs.mobs[1], @gs.mobs[5])
    assert(result[0] == true, "Moving mobs should be able to intercept")
    assert(Paidgeeks::is_near(result[1],Paidgeeks::deg_to_rad(180.0)), "mob 1 => mob 5 intercept should be South")
    assert(Paidgeeks::is_near(result[2],2.0), "mob 1 => mob 5 intercept should be in 2.0 seconds")

    result = Paidgeeks::calc_intercept_mobs(@gs.mobs[1], @gs.mobs[6])
    assert(result[0] == false, "Impossible intercepts should be reported")
  end
end
