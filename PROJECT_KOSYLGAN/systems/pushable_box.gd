class_name PushableBox
extends CharacterBody3D

@export var push_friction: float = 8.0
@export var gravity: float = 20.0
@export var push_speed_factor: float = 0.8

var collision_shape: CollisionShape3D = null
var is_carried: bool = false

func _ready() -> void:
	collision_shape = find_child("CollisionShape3D", true, false) as CollisionShape3D
	add_to_group("pushable_box")
	add_to_group("interactable")
	add_to_group("boxes")

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

func push(direction: Vector3, strength: float) -> void:
	if is_carried:
		return
	direction.y = 0.0
	direction = direction.normalized()
	velocity.x = direction.x * max(strength * push_speed_factor, 3.5)
	velocity.z = direction.z * max(strength * push_speed_factor, 3.5)

func _physics_process(delta: float) -> void:
	if is_carried:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	velocity.x = move_toward(velocity.x, 0.0, push_friction * delta)
	velocity.z = move_toward(velocity.z, 0.0, push_friction * delta)

	move_and_slide()
