class_name PropSafetyBarrier
extends StaticBody3D

func _ready() -> void:
	# 1. Main Board with Diagonal Stripes
	var path_stripes = "res://assets/textures/tex_safety_barrier_stripes.png"
	var img_stripes = Image.load_from_file(ProjectSettings.globalize_path(path_stripes))
	if img_stripes:
		img_stripes.generate_mipmaps()
		var mat_s = StandardMaterial3D.new()
		mat_s.albedo_texture = ImageTexture.create_from_image(img_stripes)
		mat_s.metallic = 0.02
		mat_s.roughness = 0.45
		mat_s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var board = find_child("MainBoard", true, false) as MeshInstance3D
		if board: board.set_surface_override_material(0, mat_s)

	# 2. Smooth Orange for Legs and Frame
	var mat_orange = StandardMaterial3D.new()
	mat_orange.albedo_color = Color(0.97, 0.44, 0.09)
	mat_orange.metallic = 0.02
	mat_orange.roughness = 0.5
	for leg in find_children("Leg*", "MeshInstance3D", true, false):
		(leg as MeshInstance3D).set_surface_override_material(0, mat_orange)
	var lower = find_child("LowerBeam", true, false) as MeshInstance3D
	if lower: lower.set_surface_override_material(0, mat_orange)

	# 3. Dark Collars for Beacons
	var mat_collar = StandardMaterial3D.new()
	mat_collar.albedo_color = Color(0.25, 0.18, 0.14)
	mat_collar.roughness = 0.6
	for collar in find_children("Collar*", "MeshInstance3D", true, false):
		(collar as MeshInstance3D).set_surface_override_material(0, mat_collar)

	# 4. Glowing Warm Yellow Disc Lights
	var mat_light = StandardMaterial3D.new()
	mat_light.albedo_color = Color(1.0, 0.76, 0.12)
	mat_light.emission_enabled = true
	mat_light.emission = Color(1.0, 0.72, 0.10)
	mat_light.emission_energy_multiplier = 1.4
	mat_light.roughness = 0.25
	for lens in find_children("Lens*", "MeshInstance3D", true, false):
		(lens as MeshInstance3D).set_surface_override_material(0, mat_light)
