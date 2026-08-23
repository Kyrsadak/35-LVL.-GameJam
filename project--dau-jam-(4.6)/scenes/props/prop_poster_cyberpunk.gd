@tool
class_name PropPosterCyberpunk
extends Node3D

func _ready() -> void:
	_load_poster_material()

func _load_poster_material() -> void:
	var path_tex = "res://assets/textures/tex_poster_cyberpunk.png"
	# globalize_path replaced
	var global_p_loaded = load(path_tex)
	var img = global_p_loaded if (global_p_loaded != null) else load(global_p_loaded)
	if img:
		if img is Image:
			img.generate_mipmaps()
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = (img if img is Texture2D else (ImageTexture.create_from_image(img) if img != null else null))
		mat.emission_enabled = true
		mat.emission_texture = mat.albedo_texture
		mat.emission_energy_multiplier = 0.35
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.roughness = 0.35
		mat.metallic = 0.05
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var face = find_child("PosterFace", true, false) as MeshInstance3D
		if face:
			face.set_surface_override_material(0, mat)
