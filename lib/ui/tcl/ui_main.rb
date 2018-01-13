require 'tk'

module Paidgeeks
  module RubyFC
    module UI
      class TkMain
        def run
          root = TkRoot.new { title "Ruby Fleet Commander - Playback" }
          TkLabel.new(root) do
             text 'Hello, World!'
             pack { padx 15 ; pady 15; side 'left' }
          end
          Tk.mainloop
        end
      end
    end
  end
end
