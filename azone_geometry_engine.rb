require 'sketchup.rb'
require 'extensions.rb'

module AZONE
  module GeometryEngine
    VERSION = '2.0.0'
  end
end

unless file_loaded?(__FILE__)
  extension = SketchupExtension.new('AZONE Geometry Engine', 'azone_geometry_engine/main')
  extension.description = 'AZONE Geometry Engine 2.0: native parametric SketchUp geometry, dimensions in mm.'
  extension.version = AZONE::GeometryEngine::VERSION
  extension.creator = 'AZONE STUDIO'
  Sketchup.register_extension(extension, true)
  file_loaded(__FILE__)
end
