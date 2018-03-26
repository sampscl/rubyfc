require 'thread'
require 'concurrent'
require_relative './game_state_changer'
module Paidgeeks
  module RubyFC
    module Engine
      class KinematicEngine

        def cleanup
        end

        # Perform once-a-tick updates on mobs: kinematic integration, energy update, and
        # collision detection with munitions
        # Parameters:
        # - last_time => the last time (same units as gs.time) that this method was called, used for interval calculations
        # - gs => The gamestate
        def update(last_time, gs)
          munitions = []
          to_time = gs.time

          futures = gs.mobs.collect do |mid,mob|
            munitions << mob if mob.template.munition?
            Concurrent::Future.execute(executor: Concurrent.global_immediate_executor) do
              update_energy(last_time, gs, mob)

              transient_mob = mob.integrate(to_time)
              msg = {
                "type" => "integrate_mob",
                "mid" => transient_mob.mid,
                "fid" => transient_mob.fid,
                "x_pos" => transient_mob.x_pos,
                "y_pos" => transient_mob.y_pos,
                "heading" => transient_mob.heading,
                "velocity" => transient_mob.velocity,
                "turn_rate" => transient_mob.turn_rate,
                "valid_time" => transient_mob.valid_time,
                "turn_start_time" => transient_mob.turn_start_time,
                "turn_stop_time" => transient_mob.turn_stop_time,
                "turn_stop" => transient_mob.turn_stop,
                "fleet_source" => false,
              }
              updated_mob = Paidgeeks::RubyFC::Engine::GameStateChanger::integrate_mob_msg(gs, msg)

              # check expiration of missiles and rockets
              if Paidgeeks::RubyFC::Templates::Missile == updated_mob.template
                if updated_mob.create_time + gs.config[:missile_life_time] < updated_mob.valid_time
                  Paidgeeks::RubyFC::Engine::GameStateChanger::delete_mob_msg(gs, {
                    "type" => "delete_mob",
                    "mid" => updated_mob.mid,
                    "reason" => "no fuel",
                    "fleet_source" => false,
                    })
                end # end if time to die
              elsif Paidgeeks::RubyFC::Templates::Rocket == updated_mob.template
                if updated_mob.create_time + gs.config[:rocket_life_time] < updated_mob.valid_time
                  Paidgeeks::RubyFC::Engine::GameStateChanger::delete_mob_msg(gs, {
                    "type" => "delete_mob",
                    "mid" => updated_mob.mid,
                    "reason" => "no fuel",
                    "fleet_source" => false,
                    })
                end # end if time to die
              end # end if rocket
            end # end Concurrent::Future.execute block
          end # end all mobs collect

          # make sure concurrent processing is complete
          futures.each { |f| f.value }

          # reprocess all mobs for collisions and missile target updates
          process_collisions(last_time, munitions, gs) if munitions.any?
        end

        # Detect and process munition collisions and target updates for a game update interval. This is
        # normally called from update, although it is possible (mostly for testing) to call independently.
        # This functionassumes that all mobs have been integrated to the same valid_time (which is true
        # when called from update).
        # Parameters:
        # - last_time => the last time (same units as gs.time) that this method was called, used for interval calculations
        # - munitions => Array of munition mobs
        # - gs => The gamestate
        def process_collisions(last_time, munitions, gs)
          collisions = [] # ary of hashes {interceptor_mob: mob1, mob2: mob2, ttg: ttg}
          gs.mobs.each do |mid,mob|
            munitions.each do |mun_mob|
              next if mun_mob.fid == mob.fid
              ttg = Paidgeeks::ttg_pca_mobs(mob, mun_mob)
              if ttg <= 0 and mun_mob.valid_time+ttg > last_time and within_collision_zone(mob, mun_mob, ttg)
                collisions << {interceptor_mob: mun_mob, mob2: mob, ttg: ttg}
              end # end if ttg is within the last integration interval
            end # end for all munitions
          end # end for all mobs

          return if not collisions.any?

          # reorder in ascending ttg order
          collisions.sort! do |a,b|
            result= -1 if a[:ttg] > b[:ttg]
            result = 0 if a[:ttg] == b[:ttg]
            result = 1 if a[:ttg] < b[:ttg]
            result
          end

          collided_mids = Set.new

          # iterate in time order
          collisions.each do |collision|
            next if collided_mids.include?(collision[:interceptor_mob].mid)
            next if collided_mids.include?(collision[:mob2].mid)
            collided_mids.add(collision[:interceptor_mob].mid)
            collided_mids.add(collision[:mob2].mid)

            # interceptor_mob and mob2 have collided

            # tell interceptor fleet that interceptor hit something
            Paidgeeks::RubyFC::Engine::GameStateChanger::munition_intercept_msg(gs, {
              "type" => "munition_intercept",
              "munition_mid" => collision[:interceptor_mob].mid,
              "target_mid" => collision[:mob2].mid,
              "exact_time" => collision[:interceptor_mob].valid_time + collision[:ttg],
              "remaining_target_hitpoints" => collision[:mob2].hitpoints - collision[:interceptor_mob].template.damage_caused,
              "fleet_source" => false,
              })
            # destroy interceptor
            Paidgeeks::RubyFC::Engine::GameStateChanger::delete_mob_msg(gs, {
              "type" => "delete_mob",
              "mid" => collision[:interceptor_mob].mid,
              "reason" => "munition intercepted target",
              "fleet_source" => false,
              })
            # subtract hit points from mob2
            Paidgeeks::RubyFC::Engine::GameStateChanger::reduce_hitpoints_msg(gs, {
              "type" => "reduce_hitpoints",
              "mid" => collision[:mob2].mid,
              "amount" => collision[:interceptor_mob].template.damage_caused,
              "fleet_source" => false,
              })
            # destroy mob2 if hitpoints <= 0, retrieve by mid just to be sure (paranoia)
            Paidgeeks::RubyFC::Engine::GameStateChanger::delete_mob_msg(gs, {
              "type" => "delete_mob",
              "mid" => collision[:mob2].mid,
              "reason" => "destroyed by munition",
              "fleet_source" => false,
              }) if gs.mobs[collision[:mob2].mid].hitpoints <= 0
          end # end each collision sorted by ttg

          # for remaining missile munitions, send target if munution has target
          # and missile target updates are enabled
          if gs.config[:enable_missile_target_update]
            munitions.each do |mun_mob|
              mun_mob = gs.mobs[mun_mob.mid] # will be nil if mun_mob hit target
              next if mun_mob.nil? or mun_mob.target_mid.nil?

              target_mob = gs.mobs[mun_mob.target_mid]
              next if target_mob.nil? # target already destroyed

              # send target_mob to mun_mob's fleet as a missile target update
              Paidgeeks::RubyFC::Engine::GameStateChanger::missile_target_update_msg(gs, {
                "type" => "missile_target_update",
                "munition_mid" => mun_mob.mid,
                "target_mid" => target_mob.mid,
                "x_pos" => target_mob.x_pos,
                "y_pos" => target_mob.y_pos,
                "heading" => target_mob.heading,
                "velocity" => target_mob.velocity,
                "valid_time" => target_mob.valid_time,
                "template" => target_mob.template.class.name,
                "fleet_source" => false,
                })
            end
          end # if enable_missile_target_update
        end

        # Check if mobs are within their mutual collision zone.
        # This assumes that mob1.valid_time == mob2.valid time,
        # and delta_time is offset from valid_time that needs
        # to be checked.
        def within_collision_zone(mob1, mob2, delta_time)
          mob1 = mob1.integrate(mob1.valid_time + delta_time)
          mob2 = mob2.integrate(mob2.valid_time + delta_time)

          x1min = mob1.x_pos - mob1.template.collision_size
          x1max = mob1.x_pos + mob1.template.collision_size
          y1min = mob1.y_pos - mob1.template.collision_size
          y1max = mob1.y_pos + mob1.template.collision_size

          x2min = mob2.x_pos - mob2.template.collision_size
          x2max = mob2.x_pos + mob2.template.collision_size
          y2min = mob2.y_pos - mob2.template.collision_size
          y2max = mob2.y_pos + mob2.template.collision_size

          return false if x1min > x2max
          return false if x1max < x2min
          return false if y1min > y2max
          return false if y1max < y2min
          true
        end

        # Update a mobs energy
        # Parameters:
        # - last_time => the last time (same units as gs.time) that this method was called, used for interval calculations
        # - gs => The gamestate
        # - mob => The mob to update
        def update_energy(last_time, gs, mob)
          return if mob.energy >= mob.template.max_energy

          delta_time = gs.time - last_time
          return if delta_time <= 0.0

          delta_energy = delta_time * mob.template.energy_recovery_rate
          new_energy = [mob.energy + delta_energy, mob.template.max_energy].min

          Paidgeeks::RubyFC::Engine::GameStateChanger::set_energy_msg(gs, {
            "type" => "set_energy",
            "new_energy" => new_energy,
            "mid" => mob.mid,
            "fleet_source" => false,
            })
        end
      end
    end
  end
end
