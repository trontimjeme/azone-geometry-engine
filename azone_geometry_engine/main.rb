# frozen_string_literal: true
require 'sketchup.rb'
require_relative 'geometry'

module AZONE
  module GeometryEngine
    extend self
    VERSION = '2.0.0' unless const_defined?(:VERSION)
    DICT = 'AZONE'.freeze

    def point(x, y, z)
      Geom::Point3d.new(x.mm, y.mm, z.mm)
    end

    def face!(entities, vertices)
      face = entities.add_face(vertices.map { |v| point(*v) })
      raise ArgumentError, 'Invalid or nonplanar geometry' unless face
      face.reverse! if face.normal.z < 0
      face
    end

    def metadata(group, values)
      group.set_attribute(DICT, 'units', 'mm')
      group.set_attribute(DICT, 'engine_version', VERSION)
      values.each { |key, value| group.set_attribute(DICT, key.to_s, value) }
    end

    def operation(name)
      model = Sketchup.active_model
      raise 'No active SketchUp model' unless model
      model.start_operation(name, true)
      begin
        result = yield model
        model.commit_operation
        result
      rescue StandardError => e
        model.abort_operation
        warn("AZONE Geometry Engine: #{e.class}: #{e.message}")
        UI.messagebox("AZONE Geometry Engine: #{e.message}")
        nil
      end
    end

    def build_arch(width_mm: 2600, spring_mm: 2600, depth_mm: 200, segments: 64)
      depth = Geometry.finite_number(depth_mm, 'depth', positive: true)
      outline = Geometry.arch_outline(width_mm: width_mm, spring_mm: spring_mm, segments: segments)
      operation('AZONE - Semicircular arch') do |model|
        group = model.active_entities.add_group
        group.name = 'AZONE_ARCH'
        face!(group.entities, outline).pushpull(depth.mm)
        metadata(group, width_mm: Float(width_mm), spring_mm: Float(spring_mm), depth_mm: depth, segments: Integer(segments))
        group
      end
    end

    def build_hip_roof(width_mm: 8000, depth_mm: 10000, eave_z_mm: 3900, overhang_mm: 600, pitch_deg: 30)
      kwargs = {width_mm: width_mm, depth_mm: depth_mm, eave_z_mm: eave_z_mm, overhang_mm: overhang_mm, pitch_deg: pitch_deg}
      polygons = Geometry.hip_roof_faces(**kwargs)
      operation('AZONE - Hip roof') do |model|
        group = model.active_entities.add_group
        group.name = 'AZONE_ROOF_HIP_4_SIDES'
        polygons.each { |polygon| face!(group.entities, polygon) }
        metadata(group, kwargs)
        metadata(group, shell: true, thick_solid: false)
        group
      end
    end

    # Rectangular wall openings (arched openings planned in the roadmap).
    def build_wall(length_mm: 8000, height_mm: 3600, thickness_mm: 220, openings: [])
      thickness = Geometry.finite_number(thickness_mm, 'wall thickness', positive: true)
      panels = Geometry.wall_panels(length_mm: length_mm, height_mm: height_mm, openings: openings)
      operation('AZONE - Wall with openings') do |model|
        parent = model.active_entities.add_group
        parent.name = 'AZONE_WALL'
        panels.each_with_index do |(x0, z0, x1, z1), i|
          child = parent.entities.add_group
          child.name = "WALL_PANEL_#{i + 1}"
          face = face!(child.entities, [[x0, 0, z0], [x1, 0, z0], [x1, 0, z1], [x0, 0, z1]])
          face.pushpull(thickness.mm)
        end
        metadata(parent, length_mm: length_mm, height_mm: height_mm, thickness_mm: thickness, opening_count: openings.length)
        parent
      end
    end

    def build_column(width_mm: 250, depth_mm: 250, height_mm: 3600)
      w = Geometry.finite_number(width_mm, 'column width', positive: true)
      d = Geometry.finite_number(depth_mm, 'column depth', positive: true)
      h = Geometry.finite_number(height_mm, 'column height', positive: true)
      operation('AZONE - Column') do |model|
        group = model.active_entities.add_group
        group.name = 'AZONE_COLUMN'
        face!(group.entities, [[0, 0, 0], [w, 0, 0], [w, d, 0], [0, d, 0]]).pushpull(h.mm)
        metadata(group, width_mm: w, depth_mm: d, height_mm: h)
        group
      end
    end

    def ask_arch
      values = UI.inputbox(['Width (mm)', 'Spring height (mm)', 'Depth (mm)', 'Arc segments'], [2600, 2600, 200, 64], 'AZONE - Arch')
      build_arch(width_mm: values[0], spring_mm: values[1], depth_mm: values[2], segments: values[3]) if values
    end

    def ask_roof
      values = UI.inputbox(['Width (mm)', 'Depth (mm)', 'Eave elevation (mm)', 'Overhang (mm)', 'Pitch (degrees)'], [8000, 10000, 3900, 600, 30], 'AZONE - Hip roof')
      build_hip_roof(width_mm: values[0], depth_mm: values[1], eave_z_mm: values[2], overhang_mm: values[3], pitch_deg: values[4]) if values
    end

    def ask_wall
      values = UI.inputbox(['Length (mm)', 'Height (mm)', 'Thickness (mm)'], [8000, 3600, 220], 'AZONE - Wall')
      build_wall(length_mm: values[0], height_mm: values[1], thickness_mm: values[2]) if values
    end

    def ask_column
      values = UI.inputbox(['Width (mm)', 'Depth (mm)', 'Height (mm)'], [250, 250, 3600], 'AZONE - Column')
      build_column(width_mm: values[0], depth_mm: values[1], height_mm: values[2]) if values
    end

    unless @menu_loaded
      menu = UI.menu('Extensions').add_submenu("AZONE Geometry Engine v#{VERSION}")
      menu.add_item('Create semicircular arch (mm)') { ask_arch }
      menu.add_item('Create four-sided hip roof (mm)') { ask_roof }
      menu.add_item('Create native wall (mm)') { ask_wall }
      menu.add_item('Create native column (mm)') { ask_column }
      @menu_loaded = true
    end
  end
end
