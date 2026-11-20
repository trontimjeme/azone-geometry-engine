require 'sketchup.rb'
module AZONE
  module GeometryEngine
    extend self
    VERSION = '0.1.0' unless const_defined?(:VERSION)
    def positive!(v, label)
      n = Float(v)
      raise ArgumentError, "#{label} must be positive" unless n.finite? && n > 0
      n
    end
    def mm_point(x,y,z)
      Geom::Point3d.new(x.mm,y.mm,z.mm)
    end
    def add_face!(ents, points)
      face = ents.add_face(points.map { |p| mm_point(*p) })
      raise 'Cannot create face: invalid or nonplanar geometry' unless face
      face
    end
    def operation(label)
      model = Sketchup.active_model
      model.start_operation(label, true)
      begin
        result = yield(model)
        model.commit_operation
        model.active_view.zoom(result) if result.respond_to?(:bounds)
        result
      rescue => e
        model.abort_operation
        UI.messagebox("AZONE Geometry Engine: #{e.message}")
        nil
      end
    end
    # A true semicircular opening profile in the XZ plane, 64 chords by default.
    # This creates a solid arch-shaped reference panel, not a boolean wall opening.
    def build_arch(width_mm:2600, spring_mm:2600, depth_mm:200, segments:64)
      w=positive!(width_mm,'width'); h=positive!(spring_mm,'spring'); d=positive!(depth_mm,'depth')
      n=Integer(segments)
      raise ArgumentError, 'segments must be 8..256' unless (8..256).cover?(n)
      operation('AZONE - Arch') do |model|
        g=model.active_entities.add_group
        g.name="AZONE_ARCH_#{w.to_i}mm_#{n}seg"
        e=g.entities
        r=w/2.0
        # Counterclockwise along upper semicircle from right spring to left spring.
        arc=(0..n).map do |i|
          theta=Math::PI*i/n
          [r+r*Math.cos(theta),0.0,h+r*Math.sin(theta)]
        end
        outline=[[0.0,0.0,0.0],[w,0.0,0.0]]+arc
        face=add_face!(e,outline)
        face.pushpull(d.mm)
        g.set_attribute('AZONE','units','mm')
        g.set_attribute('AZONE','width_mm',w)
        g.set_attribute('AZONE','spring_height_mm',h)
        g.set_attribute('AZONE','segments',n)
        g
      end
    end
    # Four-sided rectangular hip roof, constant slope, with eaves and ridge.
    # All four roof faces are planar. Supports equal pitches only.
    def build_hip_roof(width_mm:8000, depth_mm:10000, eave_z_mm:3900, overhang_mm:600, pitch_deg:30)
      w=positive!(width_mm,'width'); d=positive!(depth_mm,'depth')
      z=positive!(eave_z_mm,'eave height'); o=positive!(overhang_mm,'overhang')
      pitch=Float(pitch_deg)
      raise ArgumentError, 'pitch must be between 1 and 70 degrees' unless pitch.finite? && pitch>1 && pitch<70
      operation('AZONE - Hip Roof') do |model|
        g=model.active_entities.add_group
        g.name='AZONE_ROOF_HIP_4_SIDES'
        e=g.entities
        x0=-o; x1=w+o; y0=-o; y1=d+o
        run=(x1-x0)/2.0
        rise=run*Math.tan(pitch*Math::PI/180.0)
        zr=z+rise
        # For a long rectangular footprint, the ridge runs along Y.
        a=[x0,y0,z]; b=[x1,y0,z]; c=[x1,y1,z]; f=[x0,y1,z]
        ridge1=[(x0+x1)/2.0,y0+run,zr]
        ridge2=[(x0+x1)/2.0,y1-run,zr]
        raise ArgumentError,'roof dimensions invalid' if ridge1[1]>ridge2[1]
        [[a,b,ridge1],[b,c,ridge2,ridge1],[c,f,ridge2],[f,a,ridge1,ridge2]].each do |vertices|
          face=add_face!(e,vertices)
          face.reverse! if face.normal.z<0
        end
        # Eave boundary and underside; roof is an open shell, not a thick solid.
        g.set_attribute('AZONE','units','mm')
        {'width_mm'=>w,'depth_mm'=>d,'eave_z_mm'=>z,'overhang_mm'=>o,'pitch_deg'=>pitch}.each {|k,v|g.set_attribute('AZONE',k,v)}
        g
      end
    end
    def ask_arch
      values=UI.inputbox(['Width (mm)','Spring height (mm)','Depth (mm)','Arc segments'],[2600,2600,200,64],'AZONE - Arch')
      return unless values
      build_arch(width_mm:values[0],spring_mm:values[1],depth_mm:values[2],segments:values[3])
    end
    def ask_roof
      labels=['Building width (mm)','Building depth (mm)','Eave elevation (mm)','Overhang (mm)','Pitch (degrees)']
      values=UI.inputbox(labels,[8000,10000,3900,600,30],'AZONE - Hip Roof')
      return unless values
      build_hip_roof(width_mm:values[0],depth_mm:values[1],eave_z_mm:values[2],overhang_mm:values[3],pitch_deg:values[4])
    end
    unless @menu_loaded
      menu=UI.menu('Extensions').add_submenu('AZONE Geometry Engine v0.1.0')
      menu.add_item('Create semicircular arch (mm)') { ask_arch }
      menu.add_item('Create 4-sided hip roof (mm)') { ask_roof }
      @menu_loaded=true
    end
  end
end
