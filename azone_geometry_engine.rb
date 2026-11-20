require 'sketchup.rb'
require 'extensions.rb'
module AZONE
  module GeometryEngine
    VERSION = '0.1.0'
  end
end
unless file_loaded?(__FILE__)
  extension = SketchupExtension.new('AZONE Geometry Engine', 'azone_geometry_engine/main')
  extension.description = 'Offline parametric arch and rectangular hip roof prototype, millimetre inputs.'
  extension.version = AZONE::GeometryEngine::VERSION
  extension.creator = 'AZONE STUDIO'
  Sketchup.register_extension(extension, true)
  file_loaded(__FILE__)
end
