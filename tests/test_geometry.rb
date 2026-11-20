require 'minitest/autorun'
require_relative '../azone_geometry_engine/geometry'

class AZONEGeometryTest < Minitest::Test
  G = AZONE::GeometryEngine::Geometry

  def test_arch_segments_and_peak
    outline = G.arch_outline(width_mm: 2600, spring_mm: 2600, segments: 64)
    assert_equal 67, outline.length
    assert_in_delta 3900.0, outline[34][2], 0.001
  end

  def test_roof_every_aspect_ratio
    [[8000, 10000], [10000, 8000], [8000, 8000]].each do |w, d|
      faces = G.hip_roof_faces(width_mm: w, depth_mm: d, eave_z_mm: 3900, overhang_mm: 600, pitch_deg: 30)
      assert_equal 4, faces.length
      faces.each do |face|
        assert_operator face.length, :>=, 3
        refute_equal face[0], face[-1]
      end
    end
  end

  def test_opening_panels_preserve_area
    openings = [{x_mm: 1000, z_mm: 0, width_mm: 1200, height_mm: 2200},
                {x_mm: 4000, z_mm: 900, width_mm: 1500, height_mm: 1200}]
    panels = G.wall_panels(length_mm: 8000, height_mm: 3600, openings: openings)
    area = panels.sum { |x0, z0, x1, z1| (x1 - x0) * (z1 - z0) }
    assert_in_delta 8000 * 3600 - (1200 * 2200 + 1500 * 1200), area, 0.001
  end

  def test_overlapping_openings_rejected
    assert_raises(ArgumentError) do
      G.wall_panels(length_mm: 5000, height_mm: 3000, openings: [
        {x_mm: 1000, z_mm: 0, width_mm: 1200, height_mm: 2000},
        {x_mm: 1500, z_mm: 0, width_mm: 1200, height_mm: 2000}
      ])
    end
  end

  def test_bad_pitch_rejected
    assert_raises(ArgumentError) do
      G.hip_roof_faces(width_mm: 8000, depth_mm: 9000, eave_z_mm: 3900, overhang_mm: 600, pitch_deg: 80)
    end
  end
end
