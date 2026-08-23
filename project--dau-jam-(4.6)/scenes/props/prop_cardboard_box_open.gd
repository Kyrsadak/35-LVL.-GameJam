class_name PropCardboardBoxOpen
extends StaticBody3D

func _ready() -> void:
	var path = "res://assets/textures/tex_cardboard_box.png"
	# globalize_path replaced
	var global_p_loaded = load(path)
	var img = global_p_loaded if (global_p_loaded != null) else load(global_p_loaded)
	if img:
		if img is Image:
			img.generate_mipmaps()
		var tex = (img if img is Texture2D else (ImageTexture.create_from_image(img) if img != null else null))
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.metallic = 0.02
		mat.roughness = 0.88
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		
		for m_name in ["BoxBody", "FlapLeft", "FlapRight", "FlapFront", "FlapBack"]:
			var m = find_child(m_name, true, false) as MeshInstance3D
			if m:
				m.set_surface_override_material(0, mat)
