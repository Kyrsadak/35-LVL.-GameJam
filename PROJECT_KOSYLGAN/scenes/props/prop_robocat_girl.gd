class_name PropRoboCatGirl
extends Area3D

@onready var tail_root: Node3D = find_child("TailRoot", true, false) as Node3D
@onready var head_node: Node3D = find_child("HeadNode", true, false) as Node3D
@onready var screen_face: MeshInstance3D = find_child("ScreenFace", true, false) as MeshInstance3D

var anim_time: float = 0.0
var blink_timer: float = 0.0
var mat_screen_normal: StandardMaterial3D
var mat_screen_blink: StandardMaterial3D

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("robocat")
	_load_materials()

func _load_materials() -> void:
	# 1. Normal Screen Material
	var path_s = "res://assets/textures/tex_tv_cat_screen.png"
	var img_s = Image.load_from_file(ProjectSettings.globalize_path(path_s))
	if img_s:
		img_s.generate_mipmaps()
		mat_screen_normal = StandardMaterial3D.new()
		mat_screen_normal.albedo_texture = ImageTexture.create_from_image(img_s)
		mat_screen_normal.emission_enabled = true
		mat_screen_normal.emission_texture = mat_screen_normal.albedo_texture
		mat_screen_normal.emission_energy_multiplier = 0.6
		mat_screen_normal.roughness = 0.2
		mat_screen_normal.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	# 2. Blink Screen Material
	var path_sb = "res://assets/textures/tex_tv_cat_screen_blink.png"
	var img_sb = Image.load_from_file(ProjectSettings.globalize_path(path_sb))
	if img_sb:
		img_sb.generate_mipmaps()
		mat_screen_blink = StandardMaterial3D.new()
		mat_screen_blink.albedo_texture = ImageTexture.create_from_image(img_sb)
		mat_screen_blink.emission_enabled = true
		mat_screen_blink.emission_texture = mat_screen_blink.albedo_texture
		mat_screen_blink.emission_energy_multiplier = 0.6
		mat_screen_blink.roughness = 0.2
		mat_screen_blink.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	if screen_face and mat_screen_normal:
		screen_face.set_surface_override_material(0, mat_screen_normal)

	# 3. Off-White Hoodie
	var path_h = "res://assets/textures/tex_tv_cat_hoodie.png"
	var img_h = Image.load_from_file(ProjectSettings.globalize_path(path_h))
	var mat_hood = StandardMaterial3D.new()
	if img_h:
		img_h.generate_mipmaps()
		mat_hood.albedo_texture = ImageTexture.create_from_image(img_h)
		mat_hood.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	else:
		mat_hood.albedo_color = Color(0.96, 0.95, 0.93)
	mat_hood.roughness = 0.65
	for hood_part in find_children("*Hood*", "MeshInstance3D", true, false):
		(hood_part as MeshInstance3D).set_surface_override_material(0, mat_hood)

	# 4. Pastel Pink Armor Material
	var mat_pink = StandardMaterial3D.new()
	mat_pink.albedo_color = Color(0.96, 0.56, 0.69)
	mat_pink.metallic = 0.08
	mat_pink.roughness = 0.35
	for pink_part in find_children("*Pink*", "MeshInstance3D", true, false):
		(pink_part as MeshInstance3D).set_surface_override_material(0, mat_pink)

	# 5. Glowing Mint Green Accents (Ears, Dials, Core)
	var mat_mint = StandardMaterial3D.new()
	mat_mint.albedo_color = Color(0.47, 0.92, 0.82)
	mat_mint.emission_enabled = true
	mat_mint.emission = Color(0.47, 0.92, 0.82)
	mat_mint.emission_energy_multiplier = 1.8
	mat_mint.roughness = 0.2
	for mint_part in find_children("*Mint*", "MeshInstance3D", true, false):
		(mint_part as MeshInstance3D).set_surface_override_material(0, mat_mint)

	# 6. Dark Charcoal Cybernetic Chassis
	var mat_dark = StandardMaterial3D.new()
	mat_dark.albedo_color = Color(0.20, 0.22, 0.26)
	mat_dark.metallic = 0.2
	mat_dark.roughness = 0.5
	for dark_part in find_children("*Dark*", "MeshInstance3D", true, false):
		(dark_part as MeshInstance3D).set_surface_override_material(0, mat_dark)

	# 7. Silver Prongs for Electrical Plug
	var mat_metal = StandardMaterial3D.new()
	mat_metal.albedo_color = Color(0.85, 0.88, 0.92)
	mat_metal.metallic = 0.95
	mat_metal.roughness = 0.2
	for metal_part in find_children("*Prong*", "MeshInstance3D", true, false):
		(metal_part as MeshInstance3D).set_surface_override_material(0, mat_metal)

func _process(delta: float) -> void:
	anim_time += delta
	blink_timer += delta

	# Head and hip idle breathing sway
	if head_node:
		head_node.position.y = 1.36 + 0.008 * sin(anim_time * 2.0)
		head_node.rotation.z = 0.03 * sin(anim_time * 1.5)

	# Cable Plug Tail Sway (graceful springy curve)
	if tail_root:
		tail_root.rotation.y = 0.35 * sin(anim_time * 2.4)
		tail_root.rotation.x = 0.12 + 0.08 * sin(anim_time * 3.0)

	# CRT Screen Blink Animation
	if blink_timer > 3.2:
		if screen_face and mat_screen_blink:
			screen_face.set_surface_override_material(0, mat_screen_blink)
		if blink_timer > 3.45:
			if screen_face and mat_screen_normal:
				screen_face.set_surface_override_material(0, mat_screen_normal)
			blink_timer = 0.0

func interact() -> void:
	if screen_face and mat_screen_blink:
		screen_face.set_surface_override_material(0, mat_screen_blink)
		blink_timer = 3.0

	var rm = get_node_or_null("/root/RobotManager")
	if rm and rm.has_method("show_message"):
		var phrases = [
			"(=^･ω･^=)⚡ [CRT-CAT] // ПИТАНИЕ В НОРМЕ! ЗАРЯДКА 220V ПОДКЛЮЧЕНА!",
			"🔌 // ЭНЕРГОСЕТЬ СЕКТОРА 35 СТАБИЛЬНА, СЭМПАЙ!",
			"(^•ﻌ•^ ⚡) // ПОДКЛЮЧАЙСЯ К МОЕМУ КАБЕЛЮ ДЛЯ СВЕРХЗАРЯДА!"
		]
		var text = phrases[randi() % phrases.size()]
		rm.show_message(text, 3.2)

	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_success"):
		sm.play_success()
