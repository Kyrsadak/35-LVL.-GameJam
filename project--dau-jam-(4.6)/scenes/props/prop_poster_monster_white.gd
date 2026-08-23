class_name PropPosterMonsterWhite
extends Node3D

func _ready() -> void:
	_load_poster_material()

func _load_poster_material() -> void:
	var path_tex = "res://assets/textures/tex_poster_monster_white.png"
	var tex = load(path_tex)
	if tex:
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.emission_enabled = true
		mat.emission_texture = tex
		mat.emission_energy_multiplier = 0.35
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.roughness = 0.35
		mat.metallic = 0.05
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var face = find_child("PosterFace", true, false) as MeshInstance3D
		if face: face.set_surface_override_material(0, mat)
