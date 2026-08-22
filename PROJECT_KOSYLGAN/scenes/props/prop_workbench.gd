class_name PropWorkbench
extends StaticBody3D

func _ready() -> void:
	# 1. Tabletop ESD mat texture
	_apply_tex("TableTopMat", "res://assets/textures/tex_workbench_top.png", false, 0.05, 0.8)
	
	# 2. Pegboard tool wall texture
	_apply_tex("PegboardPanel", "res://assets/textures/tex_workbench_pegboard.png", false, 0.1, 0.7)
	
	# 3. Drawer unit front texture
	_apply_tex("DrawerFront", "res://assets/textures/tex_workbench_drawers.png", false, 0.1, 0.6)
	
	# 4. Monitor screen with glowing emission
	_apply_tex("MonitorScreen", "res://assets/textures/tex_workbench_screen.png", true, 0.0, 0.4)

func _apply_tex(node_name: String, path: String, is_screen: bool, metallic: float, roughness: float) -> void:
	var global_p = ProjectSettings.globalize_path(path)
	var img = Image.load_from_file(global_p)
	if img:
		var node = find_child(node_name, true, false) as MeshInstance3D
		if node:
			var tex = ImageTexture.create_from_image(img)
			var mat = StandardMaterial3D.new()
			mat.albedo_texture = tex
			mat.metallic = metallic
			mat.roughness = roughness
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			if is_screen:
				mat.emission_enabled = true
				mat.emission_texture = tex
				mat.emission_energy_multiplier = 0.55
			node.set_surface_override_material(0, mat)
