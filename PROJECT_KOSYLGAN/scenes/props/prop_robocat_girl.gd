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
		mat_screen_normal.emission_energy_multiplier = 0.65
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
		mat_screen_blink.emission_energy_multiplier = 0.65
		mat_screen_blink.roughness = 0.2
		mat_screen_blink.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	if screen_face and mat_screen_normal:
		screen_face.set_surface_override_material(0, mat_screen_normal)

	# 3. Navy Blazer Material
	var path_b = "res://assets/textures/tex_tv_cat_blazer_v2.png"
	var img_b = Image.load_from_file(ProjectSettings.globalize_path(path_b))
	var mat_blazer = StandardMaterial3D.new()
	if img_b:
		img_b.generate_mipmaps()
		mat_blazer.albedo_texture = ImageTexture.create_from_image(img_b)
		mat_blazer.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	else:
		mat_blazer.albedo_color = Color(0.10, 0.13, 0.24)
	mat_blazer.roughness = 0.45
	for b_part in find_children("*Blazer*", "MeshInstance3D", true, false):
		(b_part as MeshInstance3D).set_surface_override_material(0, mat_blazer)

	# 4. Red & Charcoal Plaid Skirt Material
	var path_skirt = "res://assets/textures/tex_tv_cat_skirt_plaid.png"
	var img_skirt = Image.load_from_file(ProjectSettings.globalize_path(path_skirt))
	var mat_skirt = StandardMaterial3D.new()
	if img_skirt:
		img_skirt.generate_mipmaps()
		mat_skirt.albedo_texture = ImageTexture.create_from_image(img_skirt)
		mat_skirt.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	else:
		mat_skirt.albedo_color = Color(0.75, 0.15, 0.22)
	mat_skirt.roughness = 0.5
	for s_part in find_children("*Skirt*", "MeshInstance3D", true, false):
		(s_part as MeshInstance3D).set_surface_override_material(0, mat_skirt)

	# 5. Crisp White Shirt & Collar & Cuffs
	var mat_white = StandardMaterial3D.new()
	mat_white.albedo_color = Color(0.98, 0.98, 1.0)
	mat_white.roughness = 0.35
	for w_part in find_children("*White*", "MeshInstance3D", true, false):
		(w_part as MeshInstance3D).set_surface_override_material(0, mat_white)

	# 6. High School White Knee Socks with Navy Stripes
	var mat_sock = StandardMaterial3D.new()
	mat_sock.albedo_color = Color(0.96, 0.96, 0.98)
	mat_sock.roughness = 0.4
	for sock in find_children("*Stocking*", "MeshInstance3D", true, false):
		(sock as MeshInstance3D).set_surface_override_material(0, mat_sock)

	# 7. Red Student Council Armband & Tie
	var mat_red = StandardMaterial3D.new()
	mat_red.albedo_color = Color(0.92, 0.12, 0.18)
	mat_red.roughness = 0.3
	for red_part in find_children("*Red*", "MeshInstance3D", true, false):
		(red_part as MeshInstance3D).set_surface_override_material(0, mat_red)

	# 8. Pastel Pink Armor Material
	var mat_pink = StandardMaterial3D.new()
	mat_pink.albedo_color = Color(0.96, 0.56, 0.69)
	mat_pink.metallic = 0.08
	mat_pink.roughness = 0.35
	for pink_part in find_children("*Pink*", "MeshInstance3D", true, false):
		(pink_part as MeshInstance3D).set_surface_override_material(0, mat_pink)

	# 9. Glowing Mint Green Accents (Ears, Dials, Core)
	var mat_mint = StandardMaterial3D.new()
	mat_mint.albedo_color = Color(0.47, 0.92, 0.82)
	mat_mint.emission_enabled = true
	mat_mint.emission = Color(0.47, 0.92, 0.82)
	mat_mint.emission_energy_multiplier = 1.8
	mat_mint.roughness = 0.2
	for mint_part in find_children("*Mint*", "MeshInstance3D", true, false):
		(mint_part as MeshInstance3D).set_surface_override_material(0, mat_mint)

	# 10. Classic Dark Brown Leather Loafers & Dark Joints
	var mat_loafer = StandardMaterial3D.new()
	mat_loafer.albedo_color = Color(0.24, 0.16, 0.12)
	mat_loafer.roughness = 0.35
	for loafer in find_children("*Loafer*", "MeshInstance3D", true, false):
		(loafer as MeshInstance3D).set_surface_override_material(0, mat_loafer)
	var mat_dark = StandardMaterial3D.new()
	mat_dark.albedo_color = Color(0.18, 0.20, 0.24)
	mat_dark.metallic = 0.25
	mat_dark.roughness = 0.45
	for dark_part in find_children("*Dark*", "MeshInstance3D", true, false):
		(dark_part as MeshInstance3D).set_surface_override_material(0, mat_dark)

	# 11. Metal Prongs
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
		head_node.position.y = 1.34 + 0.006 * sin(anim_time * 2.0)
		head_node.rotation.z = 0.025 * sin(anim_time * 1.5)

	# Cable Plug Tail Sway (graceful springy curve)
	if tail_root:
		tail_root.rotation.y = 0.32 * sin(anim_time * 2.4)
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
			"(=^･ω･^=)⚡ [СТАРОСТА CRT-CAT] // УРОК ЭНЕРГЕТИКИ СЕКТОРА 35 НАЧИНАЕТСЯ!",
			"🔌 // ПИТАНИЕ СТАБИЛЬНО! ЗАНИМАЙТЕ МЕСТА СОГЛАСНО РАСПИСАНИЮ, СЭМПАЙ!",
			"(^•ﻌ•^ ⚡) // 100% ЗАРЯДКИ ДЛЯ ЛУЧШЕГО УЧЕНИКА АКАДЕМИИ РОБОТОВ!"
		]
		var text = phrases[randi() % phrases.size()]
		rm.show_message(text, 3.2)

	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_success"):
		sm.play_success()
