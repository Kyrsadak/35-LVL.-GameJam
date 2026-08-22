class_name PropRoboCatGirl
extends Area3D

@onready var tail_root: Node3D = find_child("TailRoot", true, false) as Node3D
@onready var ear_left: Node3D = find_child("EarLeft", true, false) as Node3D
@onready var ear_right: Node3D = find_child("EarRight", true, false) as Node3D
@onready var head_node: Node3D = find_child("HeadNode", true, false) as Node3D

var anim_time: float = 0.0
var ear_twitch_timer: float = 0.0

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("robocat")
	_load_textures()

func _load_textures() -> void:
	# 1. Face Material
	var path_f = "res://assets/textures/tex_robocat_face.png"
	var img_f = Image.load_from_file(ProjectSettings.globalize_path(path_f))
	if img_f:
		img_f.generate_mipmaps()
		var mat_f = StandardMaterial3D.new()
		mat_f.albedo_texture = ImageTexture.create_from_image(img_f)
		mat_f.emission_enabled = true
		mat_f.emission_texture = mat_f.albedo_texture
		mat_f.emission_energy_multiplier = 0.4
		mat_f.roughness = 0.35
		mat_f.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var face = find_child("FaceMesh", true, false) as MeshInstance3D
		if face: face.set_surface_override_material(0, mat_f)

	# 2. Body / Sailor Uniform Material
	var path_b = "res://assets/textures/tex_robocat_body.png"
	var img_b = Image.load_from_file(ProjectSettings.globalize_path(path_b))
	if img_b:
		img_b.generate_mipmaps()
		var mat_b = StandardMaterial3D.new()
		mat_b.albedo_texture = ImageTexture.create_from_image(img_b)
		mat_b.metallic = 0.05
		mat_b.roughness = 0.5
		mat_b.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var body = find_child("TorsoMesh", true, false) as MeshInstance3D
		if body: body.set_surface_override_material(0, mat_b)
		var skirt = find_child("SkirtMesh", true, false) as MeshInstance3D
		if skirt: skirt.set_surface_override_material(0, mat_b)

	# 3. Cyan Glowing LED Material (Ear inners, tail tip, eye core)
	var mat_led = StandardMaterial3D.new()
	mat_led.albedo_color = Color(0.0, 0.9, 1.0)
	mat_led.emission_enabled = true
	mat_led.emission = Color(0.0, 0.9, 1.0)
	mat_led.emission_energy_multiplier = 2.0
	for led in find_children("*LED*", "MeshInstance3D", true, false):
		(led as MeshInstance3D).set_surface_override_material(0, mat_led)

	# 4. Cyber Stockings & Skin Material
	var mat_skin = StandardMaterial3D.new()
	mat_skin.albedo_color = Color(0.98, 0.94, 0.90)
	mat_skin.roughness = 0.3
	for limb in find_children("*Skin*", "MeshInstance3D", true, false):
		(limb as MeshInstance3D).set_surface_override_material(0, mat_skin)

func _process(delta: float) -> void:
	anim_time += delta
	ear_twitch_timer += delta

	# Gentle breathing / head bob
	if head_node:
		head_node.position.y = 0.68 + 0.008 * sin(anim_time * 2.0)
		head_node.rotation.z = 0.03 * sin(anim_time * 1.2)

	# Tail sway (elegant cat tail wave)
	if tail_root:
		tail_root.rotation.y = 0.25 * sin(anim_time * 2.2)
		tail_root.rotation.x = 0.15 + 0.1 * sin(anim_time * 3.0)

	# Occasional cute ear twitch
	if ear_twitch_timer > 3.0:
		if ear_left:
			ear_left.rotation.z = 0.15 * sin((ear_twitch_timer - 3.0) * 15.0)
		if ear_right:
			ear_right.rotation.z = -0.15 * sin((ear_twitch_timer - 3.0) * 15.0)
		if ear_twitch_timer > 3.6:
			ear_twitch_timer = 0.0

func interact() -> void:
	if RobotManager:
		var phrases = [
			"(=^･ω･^=) // НЯ! СИСТЕМЫ В НОРМЕ, СЭМПАЙ!",
			"(=^-ω-^=) // МЯУ! ДАННЫЕ СЕКТОРА 35 ЗАГРУЖЕНЫ!",
			"(^•ﻌ•^ ⚡) // ЗАРЯД БАТАРЕИ 100%! УДАЧИ В ЛАБОРАТОРИИ!"
		]
		var text = phrases[randi() % phrases.size()]
		RobotManager.show_message(text, 3.0)
	if SoundManager:
		SoundManager.play_success()
