# frozen_string_literal: true
# Mathematical geometry independent of the SketchUp runtime.
module AZONE
  module GeometryEngine
    module Geometry
      module_function

      def finite_number(value, label, positive: false, nonnegative: false)
        n = Float(value)
        raise ArgumentError, "#{label} must be finite" unless n.finite?
        raise ArgumentError, "#{label} must be positive" if positive && n <= 0
        raise ArgumentError, "#{label} must not be negative" if nonnegative && n < 0
        n
      rescue TypeError, ArgumentError => e
        raise ArgumentError, "Invalid #{label}: #{e.message}"
      end

      def arch_outline(width_mm:, spring_mm:, segments: 64)
        w = finite_number(width_mm, 'width', positive: true)
        spring = finite_number(spring_mm, 'spring height', nonnegative: true)
        n = Integer(segments)
        raise ArgumentError, 'segments must be 8..256' unless (8..256).cover?(n)
        radius = w / 2.0
        points = [[0.0, 0.0, 0.0], [w, 0.0, 0.0]]
        (0..n).each do |i|
          theta = Math::PI * i / n
          points << [radius + radius * Math.cos(theta), 0.0, spring + radius * Math.sin(theta)]
        end
        points
      end

      # Four equal-pitch planes. Ridge follows the longest side.
      def hip_roof_faces(width_mm:, depth_mm:, eave_z_mm:, overhang_mm:, pitch_deg:)
        w = finite_number(width_mm, 'width', positive: true)
        d = finite_number(depth_mm, 'depth', positive: true)
        z = finite_number(eave_z_mm, 'eave elevation', nonnegative: true)
        o = finite_number(overhang_mm, 'overhang', nonnegative: true)
        pitch = finite_number(pitch_deg, 'roof pitch', positive: true)
        raise ArgumentError, 'roof pitch must be less than 70 degrees' unless pitch < 70
        x0, x1, y0, y1 = -o, w + o, -o, d + o
        across = x1 - x0
        along = y1 - y0
        run = [across, along].min / 2.0
        rise = run * Math.tan(pitch * Math::PI / 180.0)
        roof_z = z + rise
        a = [x0, y0, z]; b = [x1, y0, z]
        c = [x1, y1, z]; dpt = [x0, y1, z]
        if across <= along
          p = [(x0 + x1) / 2.0, y0 + run, roof_z]
          q = [(x0 + x1) / 2.0, y1 - run, roof_z]
          faces = [[a, b, p], [b, c, q, p], [c, dpt, q], [dpt, a, p, q]]
        else
          p = [x0 + run, (y0 + y1) / 2.0, roof_z]
          q = [x1 - run, (y0 + y1) / 2.0, roof_z]
          faces = [[a, b, q, p], [b, c, q], [c, dpt, p, q], [dpt, a, p]]
        end
        # Square roofs have a single apex, not a zero-length ridge.
        faces.map { |vertices| vertices.each_with_object([]) { |v, arr| arr << v unless arr.last == v } }
             .map { |vertices| vertices.last == vertices.first ? vertices[0...-1] : vertices }
      end

      # Partition wall cross-section into non-overlapping solid rectangles.
      # Empty opening cells are left unmeshed (real rectangular voids).
      def wall_panels(length_mm:, height_mm:, openings: [])
        length = finite_number(length_mm, 'wall length', positive: true)
        height = finite_number(height_mm, 'wall height', positive: true)
        rects = openings.map do |item|
          x = finite_number(item.fetch(:x_mm), 'opening x', nonnegative: true)
          z = finite_number(item.fetch(:z_mm), 'opening z', nonnegative: true)
          w = finite_number(item.fetch(:width_mm), 'opening width', positive: true)
          h = finite_number(item.fetch(:height_mm), 'opening height', positive: true)
          raise ArgumentError, 'opening is outside wall' if x + w > length || z + h > height
          [x, z, x + w, z + h]
        end
        rects.each_with_index do |r, i|
          rects[(i + 1)..-1].each do |s|
            raise ArgumentError, 'openings overlap' if r[0] < s[2] && s[0] < r[2] && r[1] < s[3] && s[1] < r[3]
          end
        end
        xs = ([0.0, length] + rects.flat_map { |r| [r[0], r[2]] }).uniq.sort
        panels = []
        xs.each_cons(2) do |x0, x1|
          spans = rects.select { |r| r[0] < x1 && r[2] > x0 }.map { |r| [r[1], r[3]] }.sort
          previous = 0.0
          spans.each do |low, high|
            panels << [x0, previous, x1, low] if low > previous
            previous = high
          end
          panels << [x0, previous, x1, height] if height > previous
        end
        panels
      end
    end
  end
end
