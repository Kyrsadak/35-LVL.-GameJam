class_name PropPallet
extends StaticBody3D

func _ready() -> void:
	_apply_tex("res://assets/textures/tex_wood_pallet.png", "WoodMesh", 0.02, 0.85)
	_apply_tex("res://assets/textures/tex_cardboard_box.png", "BoxMesh", 0.02, 0.9)

func _apply_tex(tex_path: String, group_prefix: String, metallic: float, roughness: float) -> void:
	# globalize_path replaced
	var global_p_loaded = load(tex_path)
	var img = global_p_loaded if (global_p_loaded != null) else load(global_p_loaded)
	if img:
		var tex = (img if img is Texture2D else (ImageTexture.create_from_image(img) if img != null else null))
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.metallic = metallic
		mat.roughness = roughness
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		
		for child in find_children("*", "MeshInstance3D", true, false):
			var m = child as MeshInstance3D
			if m and m.name.begins_with(group_prefix):
				m.set_surface_override_material(0, mat)
