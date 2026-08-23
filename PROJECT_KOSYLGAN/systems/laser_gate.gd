class_name LaserGate
extends StaticBody3D

## Sci-Fi Sliding Blast Doors (Защитные гермодвери)

@export var is_active: bool = true # true = closed/locked, false = open

@onready var collision_shape: CollisionShape3D = find_child("CollisionShape3D", true, false) as CollisionShape3D
@onready var door_left: Node3D = find_child("DoorLeft", true, false) as Node3D
@onready var door_right: Node3D = find_child("DoorRight", true, false) as Node3D
@onready var door_frame: MeshInstance3D = find_child("DoorFrame", true, false) as MeshInstance3D
@onready var status_light: OmniLight3D = find_child("StatusLight", true, false) as OmniLight3D
@onready var status_beacon: MeshInstance3D = find_child("StatusBeacon", true, false) as MeshInstance3D

var door_tween: Tween
var beacon_mat: StandardMaterial3D

func _ready() -> void:
	add_to_group("laser_gate")
	_load_textures()
	_apply_door_state(is_active, true)

func _load_textures() -> void:
	# 1. Left Door Leaf Texture
	var path_l = "res://assets/textures/tex_lab_door_leaf_left.png"
	var global_l = ProjectSettings.globalize_path(path_l)
	var img_l = Image.load_from_file(global_l)
	if img_l:
		img_l.generate_mipmaps()
		var tex_l = ImageTexture.create_from_image(img_l)
		var mat_l = StandardMaterial3D.new()
		mat_l.albedo_texture = tex_l
		mat_l.metallic = 0.4
		mat_l.roughness = 0.5
		mat_l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var mesh_l = find_child("MeshLeft", true, false) as MeshInstance3D
		if mesh_l: mesh_l.set_surface_override_material(0, mat_l)

	# 2. Right Door Leaf Texture (Mirrored Symmetrical)
	var path_r = "res://assets/textures/tex_lab_door_leaf_right.png"
	var global_r = ProjectSettings.globalize_path(path_r)
	var img_r = Image.load_from_file(global_r)
	if img_r:
		img_r.generate_mipmaps()
		var tex_r = ImageTexture.create_from_image(img_r)
		var mat_r = StandardMaterial3D.new()
		mat_r.albedo_texture = tex_r
		mat_r.metallic = 0.4
		mat_r.roughness = 0.5
		mat_r.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var mesh_r = find_child("MeshRight", true, false) as MeshInstance3D
		if mesh_r: mesh_r.set_surface_override_material(0, mat_r)

	# 3. Door Frame Texture
	if door_frame:
		var path_f = "res://assets/textures/tex_lab_door_frame.png"
		var global_f = ProjectSettings.globalize_path(path_f)
		var img_f = Image.load_from_file(global_f)
		if img_f:
			img_f.generate_mipmaps()
			var tex_f = ImageTexture.create_from_image(img_f)
			var mat_f = StandardMaterial3D.new()
			mat_f.albedo_texture = tex_f
			mat_f.metallic = 0.3
			mat_f.roughness = 0.6
			mat_f.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			door_frame.set_surface_override_material(0, mat_f)

	# 4. Status Beacon Material
	beacon_mat = StandardMaterial3D.new()
	beacon_mat.emission_enabled = true
	if status_beacon:
		status_beacon.set_surface_override_material(0, beacon_mat)

func set_active(active: bool) -> void:
	is_active = active
	_apply_door_state(is_active, false)

func _apply_door_state(closed: bool, immediate: bool) -> void:
	if not collision_shape:
		collision_shape = find_child("CollisionShape3D", true, false) as CollisionShape3D
	if not door_left:
		door_left = find_child("DoorLeft", true, false) as Node3D
	if not door_right:
		door_right = find_child("DoorRight", true, false) as Node3D

	if collision_shape:
		collision_shape.disabled = not closed
		collision_shape.set_deferred("disabled", not closed)

	# Closed: left and right leaves meet seamlessly with overlap in center (±1.18)
	# Open: leaves fully retract into the side pillars and walls (±3.75)
	var target_left_x = -1.18 if closed else -3.75
	var target_right_x = 1.18 if closed else 3.75
	var color = Color(1.0, 0.25, 0.15) if closed else Color(0.2, 1.0, 0.45)

	if status_light:
		status_light.light_color = color
		status_light.light_energy = 0.9 if closed else 1.8

	if beacon_mat:
		beacon_mat.albedo_color = color
		beacon_mat.emission = color
		beacon_mat.emission_energy_multiplier = 2.5

	if immediate:
		if door_left:
			var p = door_left.position
			p.x = target_left_x
			door_left.position = p
		if door_right:
			var p = door_right.position
			p.x = target_right_x
			door_right.position = p
	else:
		if SoundManager and not closed:
			SoundManager.play_door_open()
			
		if door_tween and door_tween.is_valid():
			door_tween.kill()
		door_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if door_left:
			var p_l = door_left.position
			p_l.x = target_left_x
			door_tween.tween_property(door_left, "position", p_l, 0.85)
		if door_right:
			var p_r = door_right.position
			p_r.x = target_right_x
			door_tween.tween_property(door_right, "position", p_r, 0.85)

func open() -> void:
	set_active(false)

func close() -> void:
	set_active(true)
