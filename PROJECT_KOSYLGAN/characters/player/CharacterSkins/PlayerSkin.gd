class_name PlayerSkin
extends Node3D

@export var character_id: String = "atlas"
@export var rotation_speed := 16.0

var _last_strong_direction := Vector3(0, 0, -1)
var anim_player: AnimationPlayer = null
var current_anim: String = ""
var is_holding: bool = false
var is_lifting: bool = false

var screen_face: MeshInstance3D = null
var mat_screen_normal: StandardMaterial3D = null
var mat_screen_blink: StandardMaterial3D = null
var blink_timer: float = 0.0

var is_sleeping: bool = false
var sleep_zzz_node: Node3D = null
var head_node: Node3D = null
var sleep_tween: Tween = null

func _ready() -> void:
	anim_player = find_child("AnimationPlayer", true, false)
	screen_face = find_child("ScreenFace", true, false) as MeshInstance3D
	head_node = find_child("HeadNode", true, false) as Node3D
	
	_setup_screen_materials()
	_setup_tshirt_material()
	_setup_sleep_zzz()
	
	if anim_player and anim_player.has_animation("Idle"):
		anim_player.play("Idle")
		current_anim = "Idle"
	
	blink_timer = randf_range(2.0, 4.5)

func _setup_sleep_zzz() -> void:
	var zzz_script = load("res://characters/player/CharacterSkins/SleepZzzEffect.gd")
	if zzz_script:
		sleep_zzz_node = Node3D.new()
		sleep_zzz_node.set_script(zzz_script)
		sleep_zzz_node.theme_color = Color(0.91, 0.44, 0.36) if character_id == "atlas" else Color(0.24, 0.72, 0.47)
		sleep_zzz_node.position = Vector3(0.20, 1.80, 0.0)
		add_child(sleep_zzz_node)

func set_sleeping(sleeping: bool) -> void:
	if is_sleeping == sleeping:
		return
	is_sleeping = sleeping
	
	if sleep_tween and sleep_tween.is_valid():
		sleep_tween.kill()
	sleep_tween = create_tween().set_parallel(true)
	
	if is_sleeping:
		# 1. Enter sleep mode: Droop head down & tilt softly
		if sleep_zzz_node and sleep_zzz_node.has_method("set_active"):
			sleep_zzz_node.set_active(true)
			
		if head_node:
			sleep_tween.tween_property(head_node, "rotation", Vector3(deg_to_rad(24.0), 0.0, deg_to_rad(7.0)), 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			
		if screen_face and mat_screen_blink:
			screen_face.set_surface_override_material(0, mat_screen_blink)
			
		if anim_player:
			anim_player.speed_scale = 0.35 # Calm slow sleep breathing
	else:
		# 2. Wake up mode: Raise head back up & open eyes
		if sleep_zzz_node and sleep_zzz_node.has_method("set_active"):
			sleep_zzz_node.set_active(false)
			
		if head_node:
			sleep_tween.tween_property(head_node, "rotation", Vector3.ZERO, 0.40).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			
		if screen_face and mat_screen_normal:
			screen_face.set_surface_override_material(0, mat_screen_normal)
			
		if anim_player:
			anim_player.speed_scale = 1.0
			if current_anim != "Idle":
				anim_player.play("Idle", 0.15)
				current_anim = "Idle"

func _setup_tshirt_material() -> void:
	var tshirt_mesh = find_child("TshirtChestFront", true, false) as MeshInstance3D
	if not tshirt_mesh:
		return
	var prefix = "atlas" if character_id == "atlas" else "cipher"
	var tshirt_path = "res://assets/textures/tex_" + prefix + "_tshirt_21.png"
	var img = Image.load_from_file(ProjectSettings.globalize_path(tshirt_path))
	if img:
		img.generate_mipmaps()
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = ImageTexture.create_from_image(img)
		mat.roughness = 0.65
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tshirt_mesh.set_surface_override_material(0, mat)

func _setup_screen_materials() -> void:
	var prefix = "atlas" if character_id == "atlas" else "cipher"
	var normal_path = "res://assets/textures/tex_" + prefix + "_face.png"
	var blink_path = "res://assets/textures/tex_" + prefix + "_face_blink.png"
	
	var img_n = Image.load_from_file(ProjectSettings.globalize_path(normal_path))
	if img_n:
		img_n.generate_mipmaps()
		mat_screen_normal = StandardMaterial3D.new()
		mat_screen_normal.albedo_texture = ImageTexture.create_from_image(img_n)
		mat_screen_normal.emission_enabled = true
		mat_screen_normal.emission_texture = mat_screen_normal.albedo_texture
		mat_screen_normal.emission_energy_multiplier = 0.85
		mat_screen_normal.roughness = 0.25
		mat_screen_normal.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	var img_b = Image.load_from_file(ProjectSettings.globalize_path(blink_path))
	if img_b:
		img_b.generate_mipmaps()
		mat_screen_blink = StandardMaterial3D.new()
		mat_screen_blink.albedo_texture = ImageTexture.create_from_image(img_b)
		mat_screen_blink.emission_enabled = true
		mat_screen_blink.emission_texture = mat_screen_blink.albedo_texture
		mat_screen_blink.emission_energy_multiplier = 0.85
		mat_screen_blink.roughness = 0.25
		mat_screen_blink.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	if screen_face and mat_screen_normal:
		screen_face.set_surface_override_material(0, mat_screen_normal)

func _process(delta: float) -> void:
	if is_sleeping:
		if screen_face and mat_screen_blink:
			screen_face.set_surface_override_material(0, mat_screen_blink)
		return
		
	if not screen_face or not mat_screen_normal or not mat_screen_blink:
		return
		
	blink_timer -= delta
	if blink_timer <= 0.0:
		blink_timer = randf_range(2.8, 5.5)
		screen_face.set_surface_override_material(0, mat_screen_blink)
		get_tree().create_timer(0.16).timeout.connect(func():
			if is_instance_valid(screen_face) and mat_screen_normal and not is_sleeping:
				screen_face.set_surface_override_material(0, mat_screen_normal)
		)

func set_skin_material(_mat: Material) -> void:
	pass

func play_lift() -> void:
	if not anim_player:
		return
	is_lifting = true
	is_holding = true
	if anim_player.has_animation("Lift"):
		anim_player.play("Lift", 0.08)
		current_anim = "Lift"
		get_tree().create_timer(0.35).timeout.connect(func():
			is_lifting = false
		)
	else:
		is_lifting = false

func set_holding(holding: bool) -> void:
	is_holding = holding
	if not is_holding and current_anim in ["Lift", "Idle_Hold", "Run_Hold"]:
		if anim_player and anim_player.has_animation("Idle"):
			anim_player.play("Idle", 0.15)
			current_anim = "Idle"

func update_move_animation(velocity_ratio: float, _delta: float) -> void:
	if not anim_player or is_lifting:
		return

	if is_holding:
		if velocity_ratio > 0.1:
			var target_run = "Run_Hold" if anim_player.has_animation("Run_Hold") else "Run"
			if current_anim != target_run:
				anim_player.play(target_run, 0.12)
				current_anim = target_run
			anim_player.speed_scale = clamp(velocity_ratio * 0.9, 0.6, 1.0)
		else:
			var target_idle = "Idle_Hold" if anim_player.has_animation("Idle_Hold") else "Idle"
			if current_anim != target_idle:
				anim_player.play(target_idle, 0.15)
				current_anim = target_idle
			anim_player.speed_scale = 1.0
	else:
		if velocity_ratio > 0.1:
			if current_anim != "Run":
				if anim_player.has_animation("Run"):
					anim_player.play("Run", 0.12)
					current_anim = "Run"
			anim_player.speed_scale = clamp(velocity_ratio * 0.9, 0.6, 1.0)
		else:
			if current_anim != "Idle":
				if anim_player.has_animation("Idle"):
					anim_player.play("Idle", 0.15)
					current_anim = "Idle"
			anim_player.speed_scale = 1.0

func move_to_dead() -> void:
	if anim_player:
		if anim_player.has_animation("Dead"):
			anim_player.play("Dead", 0.2)
		current_anim = "Dead"

func reset_animations() -> void:
	is_holding = false
	is_lifting = false
	if anim_player and anim_player.has_animation("Idle"):
		anim_player.play("Idle", 0.1)
		current_anim = "Idle"

func orient_model_to_direction(direction: Vector3, delta: float) -> void:
	if direction.length() > 0.15:
		_last_strong_direction = direction

	# Model face is oriented along +Z, so atan2(x, z) points the face toward move direction
	var target_angle = atan2(_last_strong_direction.x, _last_strong_direction.z)
	global_rotation.y = lerp_angle(global_rotation.y, target_angle, delta * rotation_speed)
