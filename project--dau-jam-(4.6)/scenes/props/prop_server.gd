class_name PropServer
extends StaticBody3D

@onready var front_face: MeshInstance3D = $FrontFace

func _ready() -> void:
	var path = "res://assets/textures/tex_server_rack.png"
	# globalize_path replaced
	var global_p_loaded = load(path)
	var img = global_p_loaded if (global_p_loaded != null) else load(global_p_loaded)
	if img and front_face:
		var tex = (img if img is Texture2D else (ImageTexture.create_from_image(img) if img != null else null))
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.emission_enabled = true
		mat.emission_texture = tex
		mat.emission_energy_multiplier = 0.4
		mat.metallic = 0.6
		mat.roughness = 0.4
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		front_face.set_surface_override_material(0, mat)
