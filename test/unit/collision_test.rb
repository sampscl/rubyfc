require 'pp'
require 'minitest/autorun'

require_relative '../../config/config'
require_relative '../../lib/game_engine/all'
require_relative '../helpers/fleet_manager_test_helper'

class CollisionTest < MiniTest::Test
  def setup
    # need some static and some moving mobs
    @gs = Paidgeeks::RubyFC::Engine::GameState.new($stdout)
    Paidgeeks::RubyFC::Config.load(@gs)
    ndx = 1

    # 1
    @gs.add_fleet(ndx, FleetManagerTestHelper.new(ndx), 0, $stdout)
    @gs.mobs[ndx] = Paidgeeks::RubyFC::Mob.from_msg({ 
      "x_pos" => 1000,
      "y_pos" => 1000,
      "heading" => 0.0,
      "velocity" => 0.0,
      "mid" => @gs.reserve_mid,
      "fid" => ndx,
      "template" => Paidgeeks::RubyFC::Templates::Gunship,
      "create_time" => @gs.time,
      "turn_rate" => 0.0,
      "valid_time" => @gs.time,
      "turn_start_time" => 0.0,
      "turn_stop_time" => 0.0,
      "turn_stop" => 0,
      "energy" => Paidgeeks::RubyFC::Templates::Gunship.max_energy,
      "hitpoints" => Paidgeeks::RubyFC::Templates::Gunship.hit_points,
      "last_scan_tick" => 0,
      "fleet_source" => false,
      })
    ndx += 1

    # 2
    @gs.add_fleet(ndx, FleetManagerTestHelper.new(ndx), 0, $stdout)
    @gs.mobs[ndx] = Paidgeeks::RubyFC::Mob.from_msg({ 
      "x_pos" => 1030, # about 1.5 ticks away for a rocket
      "y_pos" => 1000,
      "heading" => 0.0,
      "velocity" => 0.0,
      "mid" => @gs.reserve_mid,
      "fid" => ndx,
      "template" => Paidgeeks::RubyFC::Templates::Fighter,
      "create_time" => @gs.time,
      "turn_rate" => 0.0,
      "valid_time" => @gs.time,
      "turn_start_time" => 0.0,
      "turn_stop_time" => 0.0,
      "turn_stop" => 0,
      "energy" => Paidgeeks::RubyFC::Templates::Fighter.max_energy,
      "hitpoints" => Paidgeeks::RubyFC::Templates::Fighter.hit_points,
      "last_scan_tick" => 0,
      "fleet_source" => false,
      })
    ndx += 1

  end

  def test_collisions
    ke = Paidgeeks::RubyFC::Engine::KinematicEngine.new
    smp = Paidgeeks::RubyFC::Engine::SanitizedMessageProcessor.new
    gsc = Paidgeeks::RubyFC::Engine::GameStateChanger
    fm = @gs.fleets[1][:manager]
    smp.fire_msg({
      "type" => "fire",
      "munition_type" => "Rocket",
      "munition_heading" => 90.0,
      "source_ship" => 1,
      }, fm, @gs)

    last_time = @gs.time
    gsc::tick_msg(@gs, {"type" => "tick", "fleet_source" => false})
    ke.update(last_time, @gs)


    last_time = @gs.time
    gsc::tick_msg(@gs, {"type" => "tick", "fleet_source" => false})
    ke.update(last_time, @gs)

    assert(@gs.mobs.size() == 1, "Rocket intercept kills both rocket and target")

  end
end
