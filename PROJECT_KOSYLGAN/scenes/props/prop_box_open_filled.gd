class_name PropBoxOpenFilled
extends StaticBody3D

func _ready() -> void:
	# 1. Outer cardboard
	var path_box = "res://assets/textures/tex_cardboard_box.png"
	var tex_box = load(path_box)
	if tex_box:
		var mat_box = StandardMaterial3D.new()
		mat_box.albedo_texture = tex_box
		mat_box.metallic = 0.02
		mat_box.roughness = 0.88
		mat_box.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		for child in find_children("Box*", "MeshInstance3D", true, false):
			child.set_surface_override_material(0, mat_box)
		for child in find_children("Flap*", "MeshInstance3D", true, false):
			child.set_surface_override_material(0, mat_box)

	# 2. Inner electronic parts / foam
	var path_parts = "res://assets/textures/tex_box_parts.png"
	var tex_parts = load(path_parts)
	if tex_parts:
		var mat_p = StandardMaterial3D.new()
		mat_p.albedo_texture = tex_parts
		mat_p.emission_enabled = true
		mat_p.emission = Color(0.0, 0.8, 0.9)
		mat_p.emission_texture = tex_parts
		mat_p.emission_energy_multiplier = 0.25
		mat_p.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var parts_mesh = find_child("InnerParts", true, false) as MeshInstance3D
		if parts_mesh: parts_mesh.set_surface_override_material(0, mat_p)
