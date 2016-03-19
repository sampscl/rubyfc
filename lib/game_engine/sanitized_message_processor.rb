require_relative '../utilities/stream_comms'
require_relative './game_state_changer'
module Paidgeeks
  module RubyFC
    module Engine
      class SanitizedMessageProcessor

        def set_fleet_metadata_msg(msg, fm, gs)
          gsc = Paidgeeks::RubyFC::Engine::GameStateChanger # NOTE: this is *not* an instance! It's just shorthand
          gsc::set_fleet_metadata_msg(gs, msg)
        end

        def tick_acknowledged_msg(msg, fm, gs)
          gsc = Paidgeeks::RubyFC::Engine::GameStateChanger # NOTE: this is *not* an instance! It's just shorthand
          gsc::tick_acknowledged_msg(gs, msg)
        end

        def launch_msg(msg, fm, gs)
          gsc = Paidgeeks::RubyFC::Engine::GameStateChanger # NOTE: this is *not* an instance! It's just shorthand
          origin_mob = gs.mobs[msg["source_ship"]]

          if origin_mob.nil? or origin_mob.fid != fm.fleet_id
            gsc::warn_fleet(gs, {
              "type" => "warn_fleet", 
              "fid" => fm.fleet_id,
              "original_message" => msg,
              "warning" => "source_ship invalid"
              })
            return nil
          end

          new_ship_klass = Paidgeeks::RubyFC::Templates.const_get(msg["ship_type"])

          case new_ship_klass
          when Paidgeeks::RubyFC::Templates::Rocket, Paidgeeks::RubyFC::Templates::Missile
            gsc::warn_fleet(gs, {
              "type" => "warn_fleet", 
              "fid" => fm.fleet_id,
              "original_message" => msg,
              "warning" => "ship_type cannot be launched, it must be fired"
              })
            return nil
          else # not a munition, attempt to create another ship
            if not origin_mob.template.can_create_others
              gsc::warn_fleet(gs, {
                "type" => "warn_fleet", 
                "fid" => fm.fleet_id,
                "original_message" => msg,
                "warning" => "source_ship cannot create other ships"
                })
              return nil
            end
          end # case new_ship_klass

          if gs.fleets[fm.fleet_id][:credits] < new_ship_klass.credit_cost
            gsc::warn_fleet(gs, {
              "type" => "warn_fleet", 
              "fid" => fm.fleet_id,
              "original_message" => msg,
              "warning" => "not enough credits"
              })
            return nil
          end

          if origin_mob.energy < new_ship_klass.energy_cost
            gsc::warn_fleet(gs, {
              "type" => "warn_fleet", 
              "fid" => fm.fleet_id,
              "original_message" => msg,
              "warning" => "source_ship does not have enough energy"
              })
            return nil
          end

          # we're here: source_ship can launch new_ship_klass and fleet has enough credits,
          # and the origin_mob has enough energy, so we will deduct credits, remobe energy
          # and then launch a new ship. Yay!
          gsc::reduce_credits_msg(gs, {
            "type" => "reduce_credits",
            "fid" => fm.fleet_id,
            "amount" => new_ship_klass.credit_cost
            })
          gsc::reduce_energy(gs, {
            "type" => "reduce_energy",
            "mid" => origin_mob.mid,
            "amount" => new_ship_klass.energy_cost,
            })
          gsc::create_mob_msg(gs, {
            "type" => "create_mob",
            "template" => new_ship_klass,
            "create_time" => gs.time,
            "x_pos" => origin_mob.x_pos,
            "y_pos" => origin_mob.y_pos,
            "heading" => origin_mob.heading,
            "velocity" => new_ship_klass.max_velocity,
            "turn_rate" => 0.0,
            "valid_time" => gs.time,
            "turn_start_time" => 0.0,
            "turn_stop_time" => 0.0,
            "turn_stop" => origin_mob.heading,
            "fid" => fm.fleet_id,
            "mid" => gs.reserve_mid,
            "energy" => new_ship_klass.max_energy,
            "hitpoints" => new_ship_klass.hit_points,
            "last_scan_tick" => 0,
          })
        end

        def fire_msg(msg, fn, gs)
          gsc = Paidgeeks::RubyFC::Engine::GameStateChanger # NOTE: this is *not* an instance! It's just shorthand
          origin_mob = gs.mobs[msg["source_ship"]]

          if origin_mob.nil? or origin_mob.fid != fm.fleet_id
            gsc::warn_fleet(gs, {
              "type" => "warn_fleet", 
              "fid" => fm.fleet_id,
              "original_message" => msg,
              "warning" => "source_ship invalid"
              })
            return nil
          end

          new_ship_klass = Paidgeeks::RubyFC::Templates.const_get(msg["ship_type"])

          case new_ship_klass
          when Paidgeeks::RubyFC::Templates::Rocket
            if not origin_mob.template.can_fire_rockets
              gsc::warn_fleet(gs, {
                "type" => "warn_fleet", 
                "fid" => fm.fleet_id,
                "original_message" => msg,
                "warning" => "source_ship cannot fire rockets"
                })
              return nil
            end
          when Paidgeeks::RubyFC::Templates::Missile
            if not origin_mob.template.can_fire_missiles
              gsc::warn_fleet(gs, {
                "type" => "warn_fleet", 
                "fid" => fm.fleet_id,
                "original_message" => msg,
                "warning" => "source_ship cannot fire missiles"
                })
              return nil
            end
          else # not a munition
            gsc::warn_fleet(gs, {
              "type" => "warn_fleet", 
              "fid" => fm.fleet_id,
              "original_message" => msg,
              "warning" => "ship_type cannot be fired, it must be launched"
              })
            return nil
          end # case new_ship_klass

          if gs.fleets[fm.fleet_id][:credits] < new_ship_klass.credit_cost
            gsc::warn_fleet(gs, {
              "type" => "warn_fleet", 
              "fid" => fm.fleet_id,
              "original_message" => msg,
              "warning" => "not enough credits"
              })
            return nil
          end

          if origin_mob.energy < new_ship_klass.energy_cost
            gsc::warn_fleet(gs, {
              "type" => "warn_fleet", 
              "fid" => fm.fleet_id,
              "original_message" => msg,
              "warning" => "source_ship does not have enough energy"
              })
            return nil
          end

          # we're here: source_ship can launch new_ship_klass and fleet has enough credits,
          # and the origin_mob has enough energy, so we will deduct credits, remobe energy
          # and then launch a new ship. Yay!
          gsc::reduce_credits_msg(gs, {
            "type" => "reduce_credits",
            "fid" => fm.fleet_id,
            "amount" => new_ship_klass.credit_cost
            })
          gsc::reduce_energy(gs, {
            "type" => "reduce_energy",
            "mid" => origin_mob.mid,
            "amount" => new_ship_klass.energy_cost,
            })
          gsc::create_mob_msg(gs, {
            "type" => "create_mob",
            "template" => new_ship_klass,
            "create_time" => gs.time,
            "x_pos" => origin_mob.x_pos,
            "y_pos" => origin_mob.y_pos,
            "heading" => Paidgeeks::normalize_to_circle(Paidgeeks::deg_to_rad(msg["munition_heading"])),
            "velocity" => new_ship_klass.max_velocity,
            "turn_rate" => 0.0,
            "valid_time" => gs.time,
            "turn_start_time" => 0.0,
            "turn_stop_time" => 0.0,
            "turn_stop" => origin_mob.heading,
            "fid" => fm.fleet_id,
            "mid" => gs.reserve_mid,
            "energy" => new_ship_klass.max_energy,
            "hitpoints" => new_ship_klass.hit_points,
            "last_scan_tick" => 0,
          })
        end

        def scan_msg(msg, fm, gs)
          gsc = Paidgeeks::RubyFC::Engine::GameStateChanger # NOTE: this is *not* an instance! It's just shorthand
          origin_mob = gs.mobs[msg["source_ship"]]

          if msg["range"] <= 0.0
            gsc::warn_fleet(gs, {
              "type" => "warn_fleet", 
              "fid" => fm.fleet_id,
              "original_message" => msg,
              "warning" => "range must be > 0"
              })
            return nil
          end

          if msg["azimuth"] < 0.0 or msg["azimuth"] >= 360.0
            gsc::warn_fleet(gs, {
              "type" => "warn_fleet", 
              "fid" => fm.fleet_id,
              "original_message" => msg,
              "warning" => "razimuth must be >= 0.0 and < 360.0"
              })
            return nil
          end

          if origin_mob.nil? or origin_mob.fid != fm.fleet_id
            gsc::warn_fleet(gs, {
              "type" => "warn_fleet", 
              "fid" => fm.fleet_id,
              "original_message" => msg,
              "warning" => "source_ship invalid"
              })
            return nil
          end

          if not origin_mob.template.can_scan
            gsc::warn_fleet(gs, {
              "type" => "warn_fleet", 
              "fid" => fm.fleet_id,
              "original_message" => msg,
              "warning" => "source_ship cannot scan"
              })
            return nil
          end

          if origin_mob.last_scan_tick == gs.tick
            gsc::warn_fleet(gs, {
              "type" => "warn_fleet", 
              "fid" => fm.fleet_id,
              "original_message" => msg,
              "warning" => "source_ship already scanned this tick"
              })
            return nil
          end

          if origin_mob.template == Paidgeeks::RubyFC::Templates::Missile and msg["range"] > gs.config[:missile_max_scan_range]
            msg["range"] = gs.config[:missile_max_scan_range]
          end

          gsc::scan_msg(gs, msg)
        end

        def set_speed_msg(msg, fm, gs)
          gsc = Paidgeeks::RubyFC::Engine::GameStateChanger # NOTE: this is *not* an instance! It's just shorthand
          mob = gs.mobs[msg["mid"]]
          if mob.nil? or mob.fid != fm.fleet_id
            gsc::warn_fleet(gs, {
              "type" => "warn_fleet", 
              "fid" => fm.fleet_id,
              "original_message" => msg,
              "warning" => "mid invalid"
              })
            return nil
          end

          # set limits
          if msg["speed"] < 0.0
            msg["speed"] = 0.0
          elsif msg["speed"] > mob.template.max_velocity
            msg["speed"] = mob.template.max_velocity
          end
          
          gsc::set_speed_msg(gs, msg)
        end
      end
    end
  end
end
require_relative '../logging/game_engine/sanitized_message_processor_logging.rb'
