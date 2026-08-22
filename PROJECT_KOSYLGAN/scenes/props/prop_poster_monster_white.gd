class_name PropPosterMonsterWhite
extends Node3D

func _ready() -> void:
	_load_poster_material()

func _load_poster_material() -> void:
	var path_tex = "res://assets/textures/tex_poster_monster_white.png"
	var img = Image.load_from_file(ProjectSettings.globalize_path(path_tex))
	if img:
		img.generate_mipmaps()
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = ImageTexture.create_from_image(img)
		mat.emission_enabled = true
		mat.emission_texture = mat.albedo_texture
		mat.emission_energy_multiplier = 0.35
		mat.roughness = 0.4
		mat.metallic = 0.05
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var face = find_child("PosterFace", true, false) as MeshInstance3D
		if face: face.set_surface_override_material(0, mat)
