class_name PalletLarge
extends StaticBody3D

func _ready() -> void:
	# 1. Apply realistic wood pallet texture
	_apply_tex("res://assets/textures/tex_wood_pallet.png", "WoodMesh", 0.02, 0.85)
	
	# 2. Apply realistic cardboard box texture to cargo boxes
	_apply_tex("res://assets/textures/tex_cardboard_box.png", "BoxMesh", 0.02, 0.9)

func _apply_tex(tex_path: String, group_prefix: String, metallic: float, roughness: float) -> void:
	var global_p = ProjectSettings.globalize_path(tex_path)
	var img = Image.load_from_file(global_p)
	if img:
		var tex = ImageTexture.create_from_image(img)
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.metallic = metallic
		mat.roughness = roughness
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		
		for child in find_children("*", "MeshInstance3D", true, false):
			var m = child as MeshInstance3D
			if m and m.name.begins_with(group_prefix):
				m.set_surface_override_material(0, mat)
