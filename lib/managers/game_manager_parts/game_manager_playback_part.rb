module Paidgeeks
  module RubyFC
    module Managers
      # extend the game manager interface
      class GameManager
        def playback_while(prerecorded_stream, &continue_block)
          @playback = true
          while((msg = Paidgeeks.read_object(prerecorded_stream)) != nil && continue_block.call)
            self.send("#{msg['type']}_msg".to_sym, msg)
            fleets.each { |fid, fleet| fleet.flush_output }
          end
          end_game
          nil
        end

        def show_transcript(prerecorded_stream)
          while((msg = Paidgeeks.read_object(prerecorded_stream)) != nil)
            puts msg
          end
          end_game
          nil
        end
      end
    end
  end
end
