class_name PropLocker
extends StaticBody3D

@onready var front_face: MeshInstance3D = $FrontFace

func _ready() -> void:
	var path = "res://assets/textures/tex_locker.png"
	# globalize_path replaced
	var global_p_loaded = load(path)
	var img = global_p_loaded if (global_p_loaded != null) else load(global_p_loaded)
	if img and front_face:
		var tex = (img if img is Texture2D else (ImageTexture.create_from_image(img) if img != null else null))
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.metallic = 0.4
		mat.roughness = 0.5
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		front_face.set_surface_override_material(0, mat)
