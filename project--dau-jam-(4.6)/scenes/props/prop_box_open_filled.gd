class_name PropBoxOpenFilled
extends StaticBody3D

func _ready() -> void:
	# 1. Outer cardboard
	var path_box = "res://assets/textures/tex_cardboard_box.png"
	var img_box = Image.load_from_file(ProjectSettings.globalize_path(path_box))
	if img_box:
		if img_box is Image:
			img_box.generate_mipmaps()
		var mat_box = StandardMaterial3D.new()
		mat_box.albedo_texture = (img_box if img_box is Texture2D else (ImageTexture.create_from_image(img_box) if img_box != null else null))
		mat_box.metallic = 0.02
		mat_box.roughness = 0.88
		mat_box.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		for child in find_children("Box*", "MeshInstance3D", true, false):
			child.set_surface_override_material(0, mat_box)
		for child in find_children("Flap*", "MeshInstance3D", true, false):
			child.set_surface_override_material(0, mat_box)

	# 2. Inner electronic parts / foam
	var path_parts = "res://assets/textures/tex_box_parts.png"
	var img_parts = Image.load_from_file(ProjectSettings.globalize_path(path_parts))
	if img_parts:
		if img_parts is Image:
			img_parts.generate_mipmaps()
		var mat_p = StandardMaterial3D.new()
		mat_p.albedo_texture = (img_parts if img_parts is Texture2D else (ImageTexture.create_from_image(img_parts) if img_parts != null else null))
		mat_p.emission_enabled = true
		mat_p.emission = Color(0.0, 0.8, 0.9)
		mat_p.emission_energy_multiplier = 0.8
		mat_p.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var filled_mesh = find_child("FilledContents", true, false) as MeshInstance3D
		if filled_mesh:
			filled_mesh.set_surface_override_material(0, mat_p)
