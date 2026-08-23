class_name PropBoxTorn
extends StaticBody3D

func _ready() -> void:
	var path = "res://assets/textures/tex_box_torn.png"
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
		for child in find_children("*", "MeshInstance3D", true, false):
			var m = child as MeshInstance3D
			if m and not m.name.begins_with("Filled"):
				m.set_surface_override_material(0, mat)
