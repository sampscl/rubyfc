require 'thread'
require 'facter'
require_relative './game_state_changer'
module Paidgeeks
  module RubyFC
    module Engine
      class KinematicEngine
        def initialize(gs)
          @threads = []
          @out_queues = []
          @in_queues = []
          limit = ([gs.config[:kinematic_threads],Facter.value('processors')['count']].min) - 1
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

        def update(gs)
          to_time = gs.time
          gs.mobs.each { |mid,mob|  @in_queues.sample.enq([to_time, mob]) }

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
                if Paidgeeks::RubyRC::Templates::Missile == updated_mob.template 
                  if create_time + gs.config[:missile_life_time] < updated_mob.valid_time
                    Paidgeeks::RubyFC::Engine::GameStateChanger::delete_mob_msg(gs, {
                      "type" => "delete_mob",
                      "mid" => updated_mob.mid,
                      "reason" => "no fuel",
                      })
                  end
                elsif Paidgeeks::RubyRC::Templates::Rocket == updated_mob.template
                  if create_time + gs.config[:rocket_life_time] < updated_mob.valid_time
                    Paidgeeks::RubyFC::Engine::GameStateChanger::delete_mob_msg(gs, {
                      "type" => "delete_mob",
                      "mid" => updated_mob.mid,
                      "reason" => "no fuel",
                      })
                  end
                end
              end
            rescue ThreadError # silently consume queue is empty (deq(true) raises ThreadError when empty)
            end
          end
        end

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
