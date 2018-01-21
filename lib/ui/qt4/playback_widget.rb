require 'rubygems'
require 'bundler/setup'
require 'Qt'

require_relative 'image_cache'

module Paidgeeks
  module RubyFC
    module UI
      class PlaybackWidget < Qt::Frame

        attr_accessor :gs
        attr_accessor :image_cache

        def initialize(gs)
          self.gs = gs
          self.image_cache = ImageCache.new
          super
        end
        def initialize(gs, window)
          self.gs = gs
          self.image_cache = ImageCache.new
          super(window)
        end

        def sizeHint
          $stdout.write("size_hint\n")
          Qt::Size.new(1280, 1024)
        end

        def paintEvent(pe)
          painter = Qt::Painter.new(self)

          painter.erase_rect(pe.rect)

          gs.mobs.each do |mid, mob|
            center_x, center_y = mob_pos_to_screen(mob)
            img = image_cache.image_for_mob(mob)
            point = Qt::PointF.new(center_x - (img.width / 2.0), center_y - (img.height / 2.0))
            painter.draw_image(point, img)
            #painter.draw_text(point, "#{mob.fid}:#{mid} #{mob.template}")
          end

          painter.end
        end # paintEvent

        # Take a mob position and transform it to screen coordinates. The
        # game state (gs) is needed to determine the playing field size. The
        # playing field (0,0) is at the lower left corner, whereas the display
        # (0,0) is in the upper left corner, so the Y coordinates are flipped
        # for display reasons.
        #
        # Returns: [screen_x, screen_y] (these are floats)
        def mob_pos_to_screen(mob)
          x_pct = mob.x_pos / gs.config[:field_width]
          y_pct = 1.0 - mob.y_pos / gs.config[:field_height]

          screen_size = size()
          screen_x = x_pct * screen_size.width
          screen_y = y_pct * screen_size.height

          [screen_x, screen_y]
        end # mob_pos_to_screen

      end
    end
  end
end
