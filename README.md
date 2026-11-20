# AZONE Geometry Engine v2.0.0 — development

Native offline parametric geometry extension for SketchUp 2023 on Windows, from AZONE STUDIO. Dimensions are in millimetres. **This is a development build, not a verified release.** Ruby math tests do not replace SketchUp runtime QA.

## Implemented
- Extruded semicircular arch reference panel, configurable 8–256 segments; not yet a boolean opening in an existing wall.
- Four-plane hip roof **open shell** for long, wide and square building footprints; thickness and tile layout not yet implemented.
- Rectangular wall assemblies with actual rectangular openings, split into editable native SketchUp solid panel groups.
- Native rectangular columns, reusable metadata, input validation and undo transactions.
- Pure Ruby geometry mathematical core with tests.

## Install / use

Package the root `azone_geometry_engine.rb` and folder `azone_geometry_engine/` as an RBZ (ZIP) and install via SketchUp Extension Manager. Menu: Extensions > AZONE Geometry Engine v2.0.0.

Ruby Console API:

```ruby
AZONE::GeometryEngine.build_wall(length_mm: 8000, height_mm: 3600, thickness_mm: 220,
  openings: [{x_mm: 1000, z_mm: 0, width_mm: 1200, height_mm: 2200}])
AZONE::GeometryEngine.build_hip_roof(width_mm: 10000, depth_mm: 8000,
  eave_z_mm: 3900, overhang_mm: 600, pitch_deg: 30)
```

## Test

```sh
ruby -c azone_geometry_engine.rb
ruby -c azone_geometry_engine/main.rb
ruby -c azone_geometry_engine/geometry.rb
ruby tests/test_geometry.rb
```

Five pure Ruby tests passed locally (32 assertions). **Not tested inside SketchUp.** Before releasing, test extension loading, face orientations, wall solidity, undo/redo, different scene sizes, many instances and runtime performance.

## Next phase

- Benchmark/optimize large models and reusable Component definitions.
- Thick roof, ridge/fascia/clay tiles and correct roof intersections.
- Parametric frames, glass, window/door hardware and curved wall openings.
- Floor slabs, beams, building assembly + importable JSON schema, then optional image/PDF ingestion.

No merge or deployment without owner approval.
