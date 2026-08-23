class_name PropBananaPeel
extends Node3D

@onready var mesh_instance: MeshInstance3D = $BananaMesh
@onready var stem_instance: MeshInstance3D = $StemMesh

func _ready() -> void:
	_generate_clean_banana_mesh()

func _generate_clean_banana_mesh() -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 3 peels at 120 degree angles
	var angles = [0.0, 2.0944, 4.18879]
	
	# Profile along length: [dist_along_forward, height_y, half_width, color]
	var col_yellow = Color(1.0, 0.82, 0.08) # Rich vibrant banana yellow
	var col_tip = Color(0.24, 0.14, 0.08)    # Brown tip
	var col_green = Color(0.55, 0.72, 0.15)  # Slight green tint near stem
	
	var profile = [
		{"d": 0.02, "y": 0.075, "w": 0.025, "c": col_green},
		{"d": 0.08, "y": 0.065, "w": 0.045, "c": col_yellow},
		{"d": 0.16, "y": 0.035, "w": 0.050, "c": col_yellow},
		{"d": 0.24, "y": 0.008, "w": 0.042, "c": col_yellow},
		{"d": 0.30, "y": 0.015, "w": 0.025, "c": col_yellow},
		{"d": 0.34, "y": 0.025, "w": 0.005, "c": col_tip}
	]
	
	for angle in angles:
		var dir_fwd = Vector3(cos(angle), 0, sin(angle))
		var dir_side = Vector3(-sin(angle), 0, cos(angle))
		
		for r in range(profile.size() - 1):
			var p0 = profile[r]
			var p1 = profile[r + 1]
			
			var c0 = dir_fwd * p0.d + Vector3(0, p0.y, 0)
			var c1 = dir_fwd * p1.d + Vector3(0, p1.y, 0)
			
			var v0_left = c0 - dir_side * p0.w
			var v0_right = c0 + dir_side * p0.w
			var v1_left = c1 - dir_side * p1.w
			var v1_right = c1 + dir_side * p1.w
			
			# Triangle 1 (Double sided)
			st.set_color(p0.c)
			st.add_vertex(v0_left)
			st.set_color(p0.c)
			st.add_vertex(v0_right)
			st.set_color(p1.c)
			st.add_vertex(v1_right)
			
			st.set_color(p1.c)
			st.add_vertex(v1_right)
			st.set_color(p0.c)
			st.add_vertex(v0_right)
			st.set_color(p0.c)
			st.add_vertex(v0_left)
			
			# Triangle 2 (Double sided)
			st.set_color(p0.c)
			st.add_vertex(v0_left)
			st.set_color(p1.c)
			st.add_vertex(v1_right)
			st.set_color(p1.c)
			st.add_vertex(v1_left)
			
			st.set_color(p1.c)
			st.add_vertex(v1_left)
			st.set_color(p1.c)
			st.add_vertex(v1_right)
			st.set_color(p0.c)
			st.add_vertex(v0_left)
			
	st.generate_normals()
	var arr_mesh = st.commit()
	
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.4
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	if mesh_instance:
		mesh_instance.mesh = arr_mesh
		mesh_instance.material_override = mat
