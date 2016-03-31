require 'thread'
require 'facter'
require_relative './game_state_changer'
module Paidgeeks
  module RubyFC
    module Engine
      class KinematicEngine
        # Initialize
        # Parameters:
        # - gs => The gamestate; used to determine how many CPUs can be used
        def initialize(gs)
          @threads = []
          @out_queues = []
          @in_queues = []
          limit = 0 # the real limit - 1 since (0..limit) will loop once if limit == 0
          if 0 == gs.config[:kinematic_threads_limit] # unlimited: use cpu count
            limit = Facter.value('processors')['count'] - 1
          else # use kinematic_threads_limit as upper limit but try to use all the cpus
            limit = ([gs.config[:kinematic_threads_limit],Facter.value('processors')['count']].min) - 1
          end
          (0..limit).each do |cpu|
            @out_queues << Queue.new
            @in_queues << Queue.new
            @threads << Thread.new { update_thread(@in_queues[cpu], @out_queues[cpu]) } 
          end
        end

        def cleanup
          @in_queues.each { |q| q.enq([nil,nil]) }
          @threads.each { |t| t.join }
        end

        # Perform once-a-tick updates on mobs: kinematic integration and
        # collision detection with munitions
        # Parameters:
        # - last_time => the last time (same units as gs.time) that this method was called, used for interval calculations
        # - gs => The gamestate
        def update(last_time, gs)
          munitions = []
          to_time = gs.time
          gs.mobs.each do |mid,mob|  
            @in_queues.sample.enq([to_time, mob]) 
            if Paidgeeks::RubyFC::Templates::Rocket == mob.template or Paidgeeks::RubyFC::Templates::Missile == mob.template
              munitions << mob
            end
          end

          # wait for threads to consume their input
          more = true
          while more do
            Thread.pass
            more = false
            @in_queues.each { |q| more |= (not q.empty?)}
          end

          # wait for threads to be waiting on more input (so we know they've produced all their output)
          more = true
          while more do
            Thread.pass
            more = false
            @in_queues.each { |q| more |= (q.num_waiting() == 0) }
          end
          
          # process all output
          @out_queues.each do |q| 
            begin
              loop do 
                msg = q.deq(true)
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
                  end
                elsif Paidgeeks::RubyFC::Templates::Rocket == updated_mob.template
                  if updated_mob.create_time + gs.config[:rocket_life_time] < updated_mob.valid_time
                    Paidgeeks::RubyFC::Engine::GameStateChanger::delete_mob_msg(gs, {
                      "type" => "delete_mob",
                      "mid" => updated_mob.mid,
                      "reason" => "no fuel",
                      "fleet_source" => false,
                      })
                  end
                end
              end
            rescue ThreadError # silently consume exception when queue is empty (deq(true) raises ThreadError when empty)
            end
          end # end all out_queues

          # reprocess all mobs for collisions
          process_collisions(last_time, munitions, gs) if munitions.any?
        end

        # Detect and process munition collisions for a game update interval. This is normally called
        # from update, although it is possible (mostly for testing) to call independently. This function
        # assumes that all mobs have been integrated to the same valid_time (which is true when called from
        # update)
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

            # subtract hit points from mob2
            Paidgeeks::RubyFC::Engine::GameStateChanger::reduce_hitpoints_msg(gs, {
              "type" => "reduce_hitpoints",
              "mid" => collision[:mob2].mid,
              "amount" => collision[:interceptor_mob].template.damage_caused,
              "fleet_source" => false,
              })
            # tell interceptor fleet that interceptor hit something
            Paidgeeks::RubyFC::Engine::GameStateChanger::munition_intercept_msg(gs, {
              "type" => "munition_intercept",
              "munition_mid" => collision[:interceptor_mob].mid,
              "target_mid" => collision[:mob2].mid,
              "exact_time" => collision[:interceptor_mob].valid_time + collision[:ttg],
              "remaining_target_hitpoints" => collision[:mob2].hitpoints,
              "fleet_source" => false,
              })
            # destroy interceptor
            Paidgeeks::RubyFC::Engine::GameStateChanger::delete_mob_msg(gs, {
              "type" => "delete_mob",
              "mid" => collision[:interceptor_mob].mid,
              "reason" => "munition intercepted target",
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

        # This thread waits on to_time,mob on the input queue, 
        # integrates the mob and puts the update message on 
        # the output queue. The thread will exit when [nil,nil]
        # is passed on the input.
        # Parameters:
        # - inq => a Queue instance containing [to_time, mob] pairs
        # - outq => a Queue instance containing message hashes
        def update_thread(inq, outq)
          loop do
            to_time,mob = inq.deq
            break if to_time.nil? or mob.nil?
            updated_mob = mob.integrate(to_time)

            outq.enq({
              "type" => "integrate_mob",
              "mid" => updated_mob.mid,
              "fid" => updated_mob.fid,
              "x_pos" => updated_mob.x_pos,
              "y_pos" => updated_mob.y_pos,
              "heading" => updated_mob.heading,
              "velocity" => updated_mob.velocity,
              "turn_rate" => updated_mob.turn_rate,
              "valid_time" => updated_mob.valid_time,
              "turn_start_time" => updated_mob.turn_stop_time,
              "turn_stop_time" => updated_mob.turn_stop_time,
              "turn_stop" => updated_mob.turn_stop,
              "fleet_source" => false,
            })
          end
        end
      end
    end
  end
end
