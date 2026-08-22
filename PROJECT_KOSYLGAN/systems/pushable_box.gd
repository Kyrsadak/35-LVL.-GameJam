class_name PushableBox
extends CharacterBody3D

@export var push_friction: float = 8.0
@export var gravity: float = 20.0
@export var push_speed_factor: float = 0.8

func push(direction: Vector3, strength: float) -> void:
	direction.y = 0.0
	direction = direction.normalized()
	velocity.x = direction.x * max(strength * push_speed_factor, 3.5)
	velocity.z = direction.z * max(strength * push_speed_factor, 3.5)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	velocity.x = move_toward(velocity.x, 0.0, push_friction * delta)
	velocity.z = move_toward(velocity.z, 0.0, push_friction * delta)

	move_and_slide()
