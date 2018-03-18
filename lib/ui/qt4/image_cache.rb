require 'rubygems'
require 'bundler/setup'
require 'Qt'

require_relative '../../utilities/class_utils'

module Paidgeeks
  module RubyFC
    module UI
      class ImageCache
        attr_accessor :template_map # {template => Qt::Image}
        attr_accessor :not_found_image # Qt::Image

        def initialize
          self.template_map = {}
          self.not_found_image = Qt::Image.new(32, 32, Qt::Image::Format_RGB32)
          not_found_image.fill(Qt::Color::from_rgb(255,0,0))
        end

        def image_for_mob(mob)
          template_map[mob.template] || cache_image(mob) || not_found_image
        end

        def cache_image(mob)
          path = Paidgeeks.class_from_string(mob.template).png_file_path
          return nil if path.nil?
          img = Qt::Image.new(path)
          return nil if img.is_null
          template_map[mob.template] = img
          img
        end
      end
    end
  end
end
