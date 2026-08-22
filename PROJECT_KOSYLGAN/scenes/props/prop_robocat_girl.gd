class_name PropRoboCatGirl
extends Area3D

@onready var tail_root: Node3D = find_child("TailRoot", true, false) as Node3D
@onready var ponytail: Node3D = find_child("PonytailRoot", true, false) as Node3D
@onready var ear_left: Node3D = find_child("EarLeft", true, false) as Node3D
@onready var ear_right: Node3D = find_child("EarRight", true, false) as Node3D
@onready var head_node: Node3D = find_child("HeadNode", true, false) as Node3D

var anim_time: float = 0.0
var ear_twitch_timer: float = 0.0

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("robocat")
	_load_materials()

func _load_materials() -> void:
	# 1. Face Material
	var path_f = "res://assets/textures/tex_robocat_face_v2.png"
	var img_f = Image.load_from_file(ProjectSettings.globalize_path(path_f))
	if img_f:
		img_f.generate_mipmaps()
		var mat_f = StandardMaterial3D.new()
		mat_f.albedo_texture = ImageTexture.create_from_image(img_f)
		mat_f.emission_enabled = true
		mat_f.emission_texture = mat_f.albedo_texture
		mat_f.emission_energy_multiplier = 0.35
		mat_f.roughness = 0.35
		mat_f.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var face = find_child("FaceMesh", true, false) as MeshInstance3D
		if face: face.set_surface_override_material(0, mat_f)

	# 2. Uniform & Skirt Material
	var path_u = "res://assets/textures/tex_robocat_uniform_v2.png"
	var img_u = Image.load_from_file(ProjectSettings.globalize_path(path_u))
	if img_u:
		img_u.generate_mipmaps()
		var mat_u = StandardMaterial3D.new()
		mat_u.albedo_texture = ImageTexture.create_from_image(img_u)
		mat_u.metallic = 0.05
		mat_u.roughness = 0.45
		mat_u.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var torso = find_child("TorsoMesh", true, false) as MeshInstance3D
		if torso: torso.set_surface_override_material(0, mat_u)
		var skirt = find_child("SkirtMesh", true, false) as MeshInstance3D
		if skirt: skirt.set_surface_override_material(0, mat_u)

	# 3. Soft Porcelain Android Skin
	var mat_skin = StandardMaterial3D.new()
	mat_skin.albedo_color = Color(0.99, 0.94, 0.90)
	mat_skin.roughness = 0.35
	for skin_part in find_children("*Skin*", "MeshInstance3D", true, false):
		(skin_part as MeshInstance3D).set_surface_override_material(0, mat_skin)

	# 4. White Silk Stockings
	var mat_stocking = StandardMaterial3D.new()
	mat_stocking.albedo_color = Color(0.96, 0.96, 0.98)
	mat_stocking.roughness = 0.4
	for leg_part in find_children("*Stocking*", "MeshInstance3D", true, false):
		(leg_part as MeshInstance3D).set_surface_override_material(0, mat_stocking)

	# 5. Cyber Navy Blue (Hair, Skirt, Shoes)
	var mat_navy = StandardMaterial3D.new()
	mat_navy.albedo_color = Color(0.10, 0.13, 0.22)
	mat_navy.roughness = 0.45
	for navy_part in find_children("*Navy*", "MeshInstance3D", true, false):
		(navy_part as MeshInstance3D).set_surface_override_material(0, mat_navy)
	for hair_part in find_children("*Hair*", "MeshInstance3D", true, false):
		(hair_part as MeshInstance3D).set_surface_override_material(0, mat_navy)

	# 6. Crimson Red (Ribbon, Hair Tie)
	var mat_red = StandardMaterial3D.new()
	mat_red.albedo_color = Color(0.90, 0.15, 0.20)
	mat_red.roughness = 0.3
	for red_part in find_children("*Red*", "MeshInstance3D", true, false):
		(red_part as MeshInstance3D).set_surface_override_material(0, mat_red)

	# 7. Cyan Neon LEDs (Ear inners, tail tip, chest core)
	var mat_led = StandardMaterial3D.new()
	mat_led.albedo_color = Color(0.0, 0.9, 1.0)
	mat_led.emission_enabled = true
	mat_led.emission = Color(0.0, 0.9, 1.0)
	mat_led.emission_energy_multiplier = 2.2
	for led in find_children("*LED*", "MeshInstance3D", true, false):
		(led as MeshInstance3D).set_surface_override_material(0, mat_led)

func _process(delta: float) -> void:
	anim_time += delta
	ear_twitch_timer += delta

	# Gentle breathing / subtle torso sway
	if head_node:
		head_node.position.y = 0.58 + 0.005 * sin(anim_time * 2.0)
		head_node.rotation.z = 0.02 * sin(anim_time * 1.5)

	# Tail sway (graceful mechanical cat tail wave)
	if tail_root:
		tail_root.rotation.y = 0.28 * sin(anim_time * 2.4)
		tail_root.rotation.x = 0.15 + 0.10 * sin(anim_time * 3.2)

	# Ponytail soft sway
	if ponytail:
		ponytail.rotation.y = 0.12 * sin(anim_time * 2.0)
		ponytail.rotation.z = 0.08 * sin(anim_time * 1.6)

	# Cute ear twitching
	if ear_twitch_timer > 3.0:
		if ear_left:
			ear_left.rotation.z = 0.18 * sin((ear_twitch_timer - 3.0) * 16.0)
		if ear_right:
			ear_right.rotation.z = -0.18 * sin((ear_twitch_timer - 3.0) * 16.0)
		if ear_twitch_timer > 3.6:
			ear_twitch_timer = 0.0

func interact() -> void:
	var rm = get_node_or_null("/root/RobotManager")
	if rm and rm.has_method("show_message"):
		var phrases = [
			"(=^･ω･^=) // НЯ! СИСТЕМЫ В НОРМЕ, СЭМПАЙ!",
			"(=^-ω-^=) // МЯУ! ДАННЫЕ СЕКТОРА 35 ЗАГРУЖЕНЫ!",
			"(^•ﻌ•^ ⚡) // ВСЕ ЭНЕРГОЦЕПИ ИСПРАВНЫ! УДАЧИ, СЭМПАЙ!"
		]
		var text = phrases[randi() % phrases.size()]
		rm.show_message(text, 3.0)
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_success"):
		sm.play_success()
