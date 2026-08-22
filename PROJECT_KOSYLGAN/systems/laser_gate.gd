class_name LaserGate
extends StaticBody3D

@export var is_active: bool = true # true = closed/locked, false = open

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var door_left: Node3D = $DoorLeft
@onready var door_right: Node3D = $DoorRight
@onready var beacon_light: OmniLight3D = $WallBeacon/BeaconLight
@onready var beacon_lens: MeshInstance3D = $WallBeacon/BeaconLens
@onready var reader_button: MeshInstance3D = $ReaderBox/ButtonMesh

var door_tween: Tween
var beacon_mat: StandardMaterial3D
var reader_mat: StandardMaterial3D

func _ready() -> void:
	_load_textures()
	_apply_door_state(is_active, true)

func _load_textures() -> void:
	# 1. Hazard Frame Texture
	var path_f = "res://assets/textures/tex_door_frame_hazard.png"
	var global_f = ProjectSettings.globalize_path(path_f)
	var img_f = Image.load_from_file(global_f)
	if img_f:
		img_f.generate_mipmaps()
		var tex_f = ImageTexture.create_from_image(img_f)
		var mat_f = StandardMaterial3D.new()
		mat_f.albedo_texture = tex_f
		mat_f.metallic = 0.35
		mat_f.roughness = 0.65
		mat_f.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		
		for child in find_children("Frame*", "MeshInstance3D", true, false):
			var m = child as MeshInstance3D
			if m: m.set_surface_override_material(0, mat_f)
	
	# 2. Left Door Leaf Texture (GATE 35 + chevrons + teeth)
	var path_l = "res://assets/textures/tex_door_leaf_left.png"
	var global_l = ProjectSettings.globalize_path(path_l)
	var img_l = Image.load_from_file(global_l)
	if img_l:
		img_l.generate_mipmaps()
		var tex_l = ImageTexture.create_from_image(img_l)
		var mat_l = StandardMaterial3D.new()
		mat_l.albedo_texture = tex_l
		mat_l.metallic = 0.55
		mat_l.roughness = 0.45
		mat_l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var mesh_l = find_child("MeshLeft", true, false) as MeshInstance3D
		if mesh_l: mesh_l.set_surface_override_material(0, mat_l)
	
	# 3. Right Door Leaf Texture (LEVEL 35 + triangles + slots)
	var path_r = "res://assets/textures/tex_door_leaf_right.png"
	var global_r = ProjectSettings.globalize_path(path_r)
	var img_r = Image.load_from_file(global_r)
	if img_r:
		img_r.generate_mipmaps()
		var tex_r = ImageTexture.create_from_image(img_r)
		var mat_r = StandardMaterial3D.new()
		mat_r.albedo_texture = tex_r
		mat_r.metallic = 0.55
		mat_r.roughness = 0.45
		mat_r.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var mesh_r = find_child("MeshRight", true, false) as MeshInstance3D
		if mesh_r: mesh_r.set_surface_override_material(0, mat_r)
	
	# Beacon & Reader Materials
	beacon_mat = StandardMaterial3D.new()
	beacon_mat.emission_enabled = true
	if beacon_lens: beacon_lens.set_surface_override_material(0, beacon_mat)
	
	reader_mat = StandardMaterial3D.new()
	reader_mat.emission_enabled = true
	if reader_button: reader_button.set_surface_override_material(0, reader_mat)

func set_active(active: bool) -> void:
	is_active = active
	_apply_door_state(is_active, false)

func _apply_door_state(closed: bool, immediate: bool) -> void:
	if collision_shape:
		collision_shape.set_deferred("disabled", not closed)
	
	var target_left_x = -0.76 if closed else -2.35
	var target_right_x = 0.76 if closed else 2.35
	var col_beacon = Color(1.0, 0.45, 0.1) if closed else Color(0.2, 1.0, 0.45)
	var col_btn = Color(0.95, 0.2, 0.1) if closed else Color(0.2, 1.0, 0.45)
	
	if beacon_light:
		beacon_light.light_color = col_beacon
		beacon_light.light_energy = 1.6 if closed else 2.2
	
	if beacon_mat:
		beacon_mat.albedo_color = col_beacon
		beacon_mat.emission = col_beacon
		beacon_mat.emission_energy_multiplier = 2.5
		
	if reader_mat:
		reader_mat.albedo_color = col_btn
		reader_mat.emission = col_btn
		reader_mat.emission_energy_multiplier = 2.0
	
	if immediate:
		if door_left: door_left.position.x = target_left_x
		if door_right: door_right.position.x = target_right_x
	else:
		if door_tween and door_tween.is_valid():
			door_tween.kill()
		door_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if door_left:
			door_tween.tween_property(door_left, "position:x", target_left_x, 0.70)
		if door_right:
			door_tween.tween_property(door_right, "position:x", target_right_x, 0.70)

func open() -> void:
	set_active(false)

func close() -> void:
	set_active(true)
