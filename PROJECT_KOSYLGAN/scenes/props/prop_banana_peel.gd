class_name PropBananaPeel
extends Node3D

@onready var mesh_instance: MeshInstance3D = $BananaMesh
@onready var stem_instance: MeshInstance3D = $StemMesh

func _ready() -> void:
	_generate_banana_mesh()
	_apply_materials()

func _generate_banana_mesh() -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 3 curved peels at 120 degree angles
	var angles = [0.0, 2.0944, 4.18879] # 0, 120, 240 deg
	
	# Profile points along the peel length: [radius, y_height, half_width, ridge_height, v_coord]
	var profile = [
		[0.02, 0.080, 0.020, 0.008, 0.00], # Base
		[0.08, 0.075, 0.045, 0.015, 0.18], # Shoulder
		[0.17, 0.040, 0.052, 0.018, 0.42], # Mid drop
		[0.26, 0.006, 0.045, 0.012, 0.68], # Floor touch
		[0.33, 0.022, 0.024, 0.008, 0.88], # Curl up
		[0.37, 0.035, 0.002, 0.002, 1.00]  # Tip point
	]
	
	for angle in angles:
		var dir_forward = Vector3(cos(angle), 0, sin(angle))
		var dir_side = Vector3(-sin(angle), 0, cos(angle))
		
		# Build rings of 5 vertices across each profile step
		# 0: Left edge, 1: Left slope, 2: Center ridge, 3: Right slope, 4: Right edge
		for r in range(profile.size() - 1):
			var p0 = profile[r]
			var p1 = profile[r + 1]
			
			var ring0_verts = _get_ring_verts(dir_forward, dir_side, p0[0], p0[1], p0[2], p0[3], p0[4])
			var ring1_verts = _get_ring_verts(dir_forward, dir_side, p1[0], p1[1], p1[2], p1[3], p1[4])
			
			# Triangulate between ring 0 and ring 1 (4 quad strips = 8 triangles)
			for seg in range(4):
				var v00 = ring0_verts[seg]
				var v01 = ring0_verts[seg + 1]
				var v10 = ring1_verts[seg]
				var v11 = ring1_verts[seg + 1]
				
				# Outer surface (skin)
				_add_quad(st, v00, v01, v11, v10)
				# Inner surface (pale pulp side)
				_add_quad(st, v10, v11, v01, v00)
	
	st.generate_normals()
	var arr_mesh = st.commit()
	if mesh_instance:
		mesh_instance.mesh = arr_mesh

func _get_ring_verts(fwd: Vector3, side: Vector3, dist: float, y_val: float, hw: float, ridge: float, v: float) -> Array:
	var verts = []
	# 5 points across: Left edge (-1), Left slope (-0.5), Center ridge (0), Right slope (0.5), Right edge (1)
	var u_weights = [0.05, 0.28, 0.50, 0.72, 0.95]
	var x_factors = [-1.0, -0.5, 0.0, 0.5, 1.0]
	var y_offsets = [0.0, ridge * 0.6, ridge, ridge * 0.6, 0.0]
	
	var center_pos = fwd * dist + Vector3(0, y_val, 0)
	
	for i in range(5):
		var pos = center_pos + side * (hw * x_factors[i]) + Vector3(0, y_offsets[i], 0)
		var uv = Vector2(u_weights[i], v)
		verts.append({"pos": pos, "uv": uv})
	
	return verts

func _add_quad(st: SurfaceTool, v00: Dictionary, v01: Dictionary, v11: Dictionary, v10: Dictionary) -> void:
	# Triangle 1
	st.set_uv(v00.uv)
	st.add_vertex(v00.pos)
	st.set_uv(v01.uv)
	st.add_vertex(v01.pos)
	st.set_uv(v11.uv)
	st.add_vertex(v11.pos)
	
	# Triangle 2
	st.set_uv(v00.uv)
	st.add_vertex(v00.pos)
	st.set_uv(v11.uv)
	st.add_vertex(v11.pos)
	st.set_uv(v10.uv)
	st.add_vertex(v10.pos)

func _apply_materials() -> void:
	var path = "res://assets/textures/tex_banana_peel_hd.png"
	var global_p = ProjectSettings.globalize_path(path)
	var img = Image.load_from_file(global_p)
	if img and mesh_instance:
		var tex = ImageTexture.create_from_image(img)
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.metallic = 0.02
		mat.roughness = 0.55
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mesh_instance.set_surface_override_material(0, mat)
