class_name PropTrashBin
extends StaticBody3D

func _ready() -> void:
	var path = "res://assets/textures/tex_trash_bin.png"
	# globalize_path replaced
	var global_p_loaded = load(path)
	var img = global_p_loaded if (global_p_loaded != null) else load(global_p_loaded)
	if img:
		if img is Image:
			img.generate_mipmaps()
		var tex = (img if img is Texture2D else (ImageTexture.create_from_image(img) if img != null else null))
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.metallic = 0.65
		mat.roughness = 0.35
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		
		for child in find_children("*", "MeshInstance3D", true, false):
			var m = child as MeshInstance3D
			if m:
				m.set_surface_override_material(0, mat)
