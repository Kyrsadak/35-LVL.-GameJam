class_name LaserGate
extends StaticBody3D

@export var is_active: bool = true # true = closed/locked, false = open

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var door_left: Node3D = $DoorLeft
@onready var door_right: Node3D = $DoorRight
@onready var door_frame: MeshInstance3D = $DoorFrame
@onready var status_light: OmniLight3D = $StatusLight
@onready var status_beacon: MeshInstance3D = $StatusBeacon

var door_tween: Tween
var beacon_mat: StandardMaterial3D

func _ready() -> void:
	_load_textures()
	_apply_door_state(is_active, true)

func _load_textures() -> void:
	# 1. Door Leaf Texture
	var path_leaf = "res://assets/textures/tex_lab_door_leaf.png"
	var global_leaf = ProjectSettings.globalize_path(path_leaf)
	var img_leaf = Image.load_from_file(global_leaf)
	if img_leaf:
		img_leaf.generate_mipmaps()
		var tex_l = ImageTexture.create_from_image(img_leaf)
		var mat_l = StandardMaterial3D.new()
		mat_l.albedo_texture = tex_l
		mat_l.metallic = 0.4
		mat_l.roughness = 0.5
		mat_l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		
		var mesh_l = find_child("MeshLeft", true, false) as MeshInstance3D
		var mesh_r = find_child("MeshRight", true, false) as MeshInstance3D
		if mesh_l: mesh_l.set_surface_override_material(0, mat_l)
		if mesh_r: mesh_r.set_surface_override_material(0, mat_l)
	
	# 2. Door Frame Texture
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
	
	# 3. Status Beacon Material
	beacon_mat = StandardMaterial3D.new()
	beacon_mat.emission_enabled = true
	if status_beacon:
		status_beacon.set_surface_override_material(0, beacon_mat)

func set_active(active: bool) -> void:
	is_active = active
	_apply_door_state(is_active, false)

func _apply_door_state(closed: bool, immediate: bool) -> void:
	if collision_shape:
		collision_shape.set_deferred("disabled", not closed)
	
	# Closed: left and right leaves overlap securely in center (0 gap!)
	# Open: leaves retract into wall pockets (clear opening)
	var target_left_x = -1.18 if closed else -2.90
	var target_right_x = 1.18 if closed else 2.90
	var color = Color(1.0, 0.25, 0.15) if closed else Color(0.2, 1.0, 0.45)
	
	if status_light:
		status_light.light_color = color
		status_light.light_energy = 0.9 if closed else 1.5
	
	if beacon_mat:
		beacon_mat.albedo_color = color
		beacon_mat.emission = color
		beacon_mat.emission_energy_multiplier = 2.0
	
	if immediate:
		if door_left: door_left.position.x = target_left_x
		if door_right: door_right.position.x = target_right_x
	else:
		if door_tween and door_tween.is_valid():
			door_tween.kill()
		door_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if door_left:
			door_tween.tween_property(door_left, "position:x", target_left_x, 0.65)
		if door_right:
			door_tween.tween_property(door_right, "position:x", target_right_x, 0.65)

func open() -> void:
	set_active(false)

func close() -> void:
	set_active(true)
