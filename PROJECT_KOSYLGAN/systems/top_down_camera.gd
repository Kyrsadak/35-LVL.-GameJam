class_name TopDownCamera
extends Node3D

@export var follow_speed: float = 6.5
@export var camera_offset: Vector3 = Vector3(1.8, 9.2, 7.2)
@export var camera_rotation_deg: Vector3 = Vector3(-48.0, 12.0, 0.0)

@onready var camera_3d: Camera3D = $Camera3D

func _ready() -> void:
	if camera_3d:
		camera_3d.position = camera_offset
		camera_3d.rotation_degrees = camera_rotation_deg
		camera_3d.fov = 44.0

func _process(delta: float) -> void:
	var target = null
	if RobotManager and RobotManager.active_robot:
		target = RobotManager.active_robot

	if target:
		var target_pos = target.global_position
		global_position = global_position.lerp(target_pos, follow_speed * delta)
