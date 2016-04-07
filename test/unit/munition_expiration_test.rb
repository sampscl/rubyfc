require 'pp'
require 'minitest/autorun'

require_relative '../../config/config'
require_relative '../../lib/game_engine/all'
require_relative '../helpers/fleet_manager_test_helper'

class MunitionExpirationTest < MiniTest::Test
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
      "target_mid" => nil,
      "fleet_source" => false,
      })
    ndx += 1
  end

  def test_munition_expiration
    ke = Paidgeeks::RubyFC::Engine::KinematicEngine.new(@gs)
    smp = Paidgeeks::RubyFC::Engine::SanitizedMessageProcessor.new
    gsc = Paidgeeks::RubyFC::Engine::GameStateChanger
    fm = @gs.fleets[1][:manager]
    smp.fire_msg({
      "type" => "fire",
      "munition_type" => "Rocket",
      "munition_heading" => 0.0,
      "source_ship" => 1,
      "target_mid" => 0,
      }, fm, @gs)

    assert(@gs.mobs.size() == 2, "Rocket successfully fired")

    last_time = @gs.time
    expire_time = last_time + @gs.config[:rocket_life_time]
    while @gs.time < expire_time + 0.010
      gsc::tick_msg(@gs, {"type" => "tick", "fleet_source" => false})
      ke.update(last_time, @gs)
      last_time = @gs.time
    end

    assert(@gs.mobs.size() == 1, "Rocket expires when its supposed to")

    smp.fire_msg({
      "type" => "fire",
      "munition_type" => "Missile",
      "munition_heading" => 0.0,
      "source_ship" => 1,
      "target_mid" => 0,
      }, fm, @gs)

    assert(@gs.mobs.size() == 2, "Missile successfully fired")

    last_time = @gs.time
    expire_time = last_time + @gs.config[:missile_life_time]
    while @gs.time < expire_time + 0.010
      gsc::tick_msg(@gs, {"type" => "tick", "fleet_source" => false})
      ke.update(last_time, @gs)
      last_time = @gs.time
    end

    assert(@gs.mobs.size() == 1, "Missile expires when its supposed to")

  end
end
