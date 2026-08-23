class_name WallFan
extends Node3D

@export var rotation_speed: float = 6.5
@onready var turbine_node: Node3D = find_child("Turbine", true, false) as Node3D
@onready var fan_mesh_inst: MeshInstance3D = find_child("FanBladeMesh", true, false) as MeshInstance3D

func _ready() -> void:
	_generate_fan_impeller_mesh()

func _process(delta: float) -> void:
	if turbine_node:
		turbine_node.rotation.z -= rotation_speed * delta

func _generate_fan_impeller_mesh() -> void:
	if not fan_mesh_inst:
		return
		
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 4 broad fan-shaped aerodynamic petals (веерные широкие лопасти)
	var num_blades = 4
	var r_inner = 0.08
	var r_outer = 0.37
	var num_radial_steps = 8
	var num_arc_steps = 10
	var blade_span_rad = deg_to_rad(54.0) # Broad 54 degree fan coverage per blade
	var pitch_angle = deg_to_rad(22.0)   # Aerodynamic tilt
	
	for b in range(num_blades):
		var base_angle = float(b) * (TAU / float(num_blades))
		
		# Generate a smooth curved 2D grid for the broad fan petal
		for r_i in range(num_radial_steps):
			var t0 = float(r_i) / float(num_radial_steps)
			var t1 = float(r_i + 1) / float(num_radial_steps)
			
			var rad0 = lerp(r_inner, r_outer, t0)
			var rad1 = lerp(r_inner, r_outer, t1)
			
			# Fan widens towards the outer edge (petal shape)
			var span0 = lerp(blade_span_rad * 0.45, blade_span_rad, pow(t0, 0.7))
			var span1 = lerp(blade_span_rad * 0.45, blade_span_rad, pow(t1, 0.7))
			
			for a_i in range(num_arc_steps):
				var u0 = float(a_i) / float(num_arc_steps) - 0.5
				var u1 = float(a_i + 1) / float(num_arc_steps) - 0.5
				
				var ang00 = base_angle + u0 * span0
				var ang01 = base_angle + u1 * span0
				var ang10 = base_angle + u0 * span1
				var ang11 = base_angle + u1 * span1
				
				# Aerodynamic pitch elevation (Z offset based on angular position)
				var z00 = u0 * span0 * rad0 * sin(pitch_angle)
				var z01 = u1 * span0 * rad0 * sin(pitch_angle)
				var z10 = u0 * span1 * rad1 * sin(pitch_angle)
				var z11 = u1 * span1 * rad1 * sin(pitch_angle)
				
				var v00 = Vector3(cos(ang00) * rad0, sin(ang00) * rad0, z00)
				var v01 = Vector3(cos(ang01) * rad0, sin(ang01) * rad0, z01)
				var v10 = Vector3(cos(ang10) * rad1, sin(ang10) * rad1, z10)
				var v11 = Vector3(cos(ang11) * rad1, sin(ang11) * rad1, z11)
				
				# Double-sided quad (Front & Back face)
				st.add_vertex(v00)
				st.add_vertex(v01)
				st.add_vertex(v11)
				
				st.add_vertex(v11)
				st.add_vertex(v01)
				st.add_vertex(v00)
				
				st.add_vertex(v00)
				st.add_vertex(v11)
				st.add_vertex(v10)
				
				st.add_vertex(v10)
				st.add_vertex(v11)
				st.add_vertex(v00)
				
	st.generate_normals()
	var arr_mesh = st.commit()
	fan_mesh_inst.mesh = arr_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.28, 0.34, 0.44) # Sleek steel-blue industrial fan
	mat.metallic = 0.85
	mat.roughness = 0.35
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	fan_mesh_inst.material_override = mat
