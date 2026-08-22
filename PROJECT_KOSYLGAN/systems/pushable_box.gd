class_name PushableBox
extends CharacterBody3D

@export var gravity: float = 20.0

var collision_shape: CollisionShape3D = null
var is_carried: bool = false

func _ready() -> void:
	collision_shape = find_child("CollisionShape3D", true, false) as CollisionShape3D
	add_to_group("pushable_box")
	add_to_group("interactable")
	add_to_group("boxes")

	var box_mesh = find_child("BoxBody", true, false) as MeshInstance3D
	if box_mesh:
		var path = "res://assets/textures/tex_scifi_crate.png"
		var global_p = ProjectSettings.globalize_path(path)
		var img = Image.load_from_file(global_p)
		if img:
			var tex = ImageTexture.create_from_image(img)
			var mat = StandardMaterial3D.new()
			mat.albedo_texture = tex
			mat.metallic = 0.4
			mat.roughness = 0.5
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			box_mesh.set_surface_override_material(0, mat)

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
	tween.tween_property(self, "position", Vector3(0, 0.4, 0), 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", Vector3.ZERO, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

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
