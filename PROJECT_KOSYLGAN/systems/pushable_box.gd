class_name PushableBox
extends CharacterBody3D

## Wooden Cargo Crate (Room 1)
## Can be pushed or lifted with Atlas's forklift forks to clear pathways and unblock the room.

@export var gravity: float = 20.0

var collision_shape: CollisionShape3D = null
var is_carried: bool = false

@onready var inner_body: MeshInstance3D = $InnerBody
@onready var top_lid: MeshInstance3D = $TopLid

func _ready() -> void:
	collision_shape = find_child("CollisionShape3D", true, false) as CollisionShape3D
	add_to_group("pushable_box")
	add_to_group("interactable")
	add_to_group("boxes")
	add_to_group("wooden_crate")

	# 1. Apply Wooden Crate Side Texture (planks with X-bracing & stencils)
	if inner_body:
		var path_s = "res://assets/textures/tex_wooden_crate_side.png"
		# globalize_path replaced
		var global_s_loaded = load(path_s)
		var img_s = global_s_loaded if (global_s_loaded != null) else load(global_s_loaded)
		if img_s:
			if img_s is Image:
				img_s.generate_mipmaps()
			var tex_s = (img_s if img_s is Texture2D else (ImageTexture.create_from_image(img_s) if img_s != null else null))
			var mat_s = StandardMaterial3D.new()
			mat_s.albedo_texture = tex_s
			mat_s.metallic = 0.0
			mat_s.roughness = 0.85
			mat_s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			inner_body.set_surface_override_material(0, mat_s)

	# 2. Apply Wooden Crate Top Lid Texture
	if top_lid:
		var path_t = "res://assets/textures/tex_wooden_crate_top.png"
		# globalize_path replaced
		var global_t_loaded = load(path_t)
		var img_t = global_t_loaded if (global_t_loaded != null) else load(global_t_loaded)
		if img_t:
			if img_t is Image:
				img_t.generate_mipmaps()
			var tex_t = (img_t if img_t is Texture2D else (ImageTexture.create_from_image(img_t) if img_t != null else null))
			var mat_t = StandardMaterial3D.new()
			mat_t.albedo_texture = tex_t
			mat_t.metallic = 0.0
			mat_t.roughness = 0.85
			mat_t.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			top_lid.set_surface_override_material(0, mat_t)

func pick_up(carrier: Marker3D) -> void:
	is_carried = true
	if collision_shape:
		collision_shape.disabled = true
	velocity = Vector3.ZERO
	
	var start_global_pos = global_position
	var start_global_rot = global_rotation
	get_parent().remove_child(self)
	carrier.add_child(self)
	global_position = start_global_pos
	global_rotation = start_global_rot

	var tween = create_tween()
	tween.set_parallel(true)
	# Position crate securely onto Atlas forklift forks
	tween.tween_property(self, "position", Vector3.ZERO, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", Vector3.ZERO, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func drop(drop_pos: Vector3) -> void:
	is_carried = false
	var scene_root = get_tree().current_scene
	var start_global_pos = global_position
	get_parent().remove_child(self)
	scene_root.add_child(self)
	global_position = start_global_pos
	velocity = Vector3.ZERO

	var tween = create_tween()
	tween.tween_property(self, "global_position", drop_pos, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		if collision_shape:
			collision_shape.disabled = false
	)

func _physics_process(delta: float) -> void:
	if is_carried:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	velocity.x = 0.0
	velocity.z = 0.0

	move_and_slide()
