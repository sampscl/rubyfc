require 'rubygems'
require 'bundler/setup'
require 'Qt'

require_relative 'image_cache'
require_relative '../../utilities/math_utils'

module Paidgeeks
  module RubyFC
    module UI
      class PlaybackWidget < Qt::Frame

        attr_accessor :gs
        attr_accessor :image_cache

        def initialize(gs, window)
          if(window)
            super(window)
          else
            super()
          end
          self.gs = gs
          self.image_cache = ImageCache.new
          setStyleSheet("background-color: black;")
        end

        def sizeHint
          $stdout.write("size_hint\n")
          Qt::Size.new(1280, 1024)
        end

        def paintEvent(pe)
          painter = Qt::Painter.new(self)

          gs.mobs.each do |mid, mob|
            center_x, center_y = mob_pos_to_screen(mob)
            img = apply_heading(mob, image_cache.image_for_mob(mob))
            point = Qt::PointF.new(center_x - (img.width / 2.0), center_y - (img.height / 2.0))
            painter.draw_image(point, img)
          end

          brush = Qt::Brush.new(Qt::Color.new(225, 225, 225))
          painter.set_brush(brush)

          gs.tick_scan_reports.each do |sr|
            sm = sr["scan_msg"]

            source_mob = gs.mobs[sm["source_ship"]]
            start_x, start_y = mob_pos_to_screen(source_mob)

            sm = sr["scan_msg"]
            angle_radians = Paidgeeks.deg_to_rad(sm["azimuth"])
            width_radians = Paidgeeks.deg_to_rad(sr["scan_width"])

            ccw_radians = angle_radians - width_radians
            cw_radians = angle_radians + width_radians

            range = sm["range"]

            ccw_x = start_x + range * Math.sin(ccw_radians)
            ccw_y = start_y - range * Math.cos(ccw_radians)

            ccw_vector = Qt::LineF.new(start_x + 0.0, start_y + 0.0, ccw_x, ccw_y)

            cw_x = start_x + range * Math.sin(cw_radians)
            cw_y = start_y - range * Math.cos(cw_radians)

            cw_vector = Qt::LineF.new(start_x + 0.0, start_y + 0.0, cw_x, cw_y)

            bridge_vector = Qt::LineF.new(ccw_x, ccw_y, cw_x, cw_y)

            painter.draw_line(ccw_vector)
            painter.draw_line(cw_vector)
            painter.draw_line(bridge_vector)

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

        def apply_heading(mob, mob_image)
          mob_image.transformed(Qt::Transform.new.rotate_radians(mob.heading))
        end

      end
    end
  end
end
