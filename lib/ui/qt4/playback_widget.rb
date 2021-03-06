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
        attr_accessor :painter
        attr_accessor :white_brush
        attr_accessor :white_pen
        attr_accessor :scan_reports

        def initialize(gs, window)
          if(window)
            super(window)
          else
            super()
          end
          self.gs = gs
          self.image_cache = ImageCache.new
          setStyleSheet("background-color: black;")
          self.painter = Qt::Painter.new
          self.white_brush = Qt::Brush.new(Qt::Color.new(225, 225, 225))
          self.white_pen = Qt::Pen.new(Qt::Color.new(225, 225, 225))
          self.scan_reports = []
        end

        def sizeHint
          Qt::Size.new(1280, 1024)
        end

        def paintEvent(pe)

          painter.begin(self)
          painter.set_brush(white_brush)
          painter.set_pen(white_pen)

          gs.mobs.each do |mid, mob|
            center_x, center_y = game_pos_to_screen(mob.x_pos, mob.y_pos)
            img = apply_heading(mob, image_cache.image_for_mob(mob))
            point = Qt::PointF.new(center_x - (img.width / 2.0), center_y - (img.height / 2.0))
            painter.draw_image(point, img)
          end

          # use cached copy in case painting happens after the messages have
          # been processed and the per-tick scan reports are flushed
          scan_reports.each do |sr|
            sm = sr["scan_msg"]

            source_mob = gs.mobs[sm["source_ship"]]
            next if source_mob.nil?
            start_x, start_y = game_pos_to_screen(source_mob.x_pos, source_mob.y_pos)

            sm = sr["scan_msg"]
            angle_radians = Paidgeeks.deg_to_rad(sm["azimuth"])
            half_width_radians = Paidgeeks.deg_to_rad(sr["scan_width"]) / 2.0

            ccw_radians = angle_radians - half_width_radians
            cw_radians = angle_radians + half_width_radians

            range = sm["range"]

            ccw_game_x = source_mob.x_pos + (range * Math.sin(ccw_radians))
            ccw_game_y = source_mob.y_pos + (range * Math.cos(ccw_radians))

            ccw_x, ccw_y = game_pos_to_screen(ccw_game_x, ccw_game_y)

            ccw_vector = Qt::LineF.new(start_x + 0.0, start_y + 0.0, ccw_x, ccw_y)

            cw_game_x = source_mob.x_pos + (range * Math.sin(cw_radians))
            cw_game_y = source_mob.y_pos + (range * Math.cos(cw_radians))

            cw_x, cw_y = game_pos_to_screen(cw_game_x, cw_game_y)

            cw_vector = Qt::LineF.new(start_x + 0.0, start_y + 0.0, cw_x, cw_y)

            bridge_vector = Qt::LineF.new(ccw_x, ccw_y, cw_x, cw_y)

            painter.draw_line(ccw_vector)
            painter.draw_line(cw_vector)
            painter.draw_line(bridge_vector)

          end

          painter.end
        end # paintEvent

        # Take a game field position and transform it to screen coordinates. The
        # game state (gs) is needed to determine the playing field size. The
        # playing field (0,0) is at the lower left corner, whereas the display
        # (0,0) is in the upper left corner, so the Y coordinates are flipped
        # for display reasons.
        #
        # Returns: [screen_x, screen_y] (these are floats)
        def game_pos_to_screen(x,y)
          x_pct = x / gs.config[:field_width]
          y_pct = 1.0 - y / gs.config[:field_height]

          screen_size = size()
          screen_x = x_pct * screen_size.width
          screen_y = y_pct * screen_size.height

          [screen_x, screen_y]
        end # game_pos_to_screen

        def apply_heading(mob, mob_image)
          mob_image.transformed(Qt::Transform.new.rotate_radians(mob.heading))
        end

      end
    end
  end
end
