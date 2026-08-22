class_name WallFan
extends Node3D

@export var rotation_speed: float = 9.0
@onready var turbine_blades: Node3D = find_child("Turbine", true, false) as Node3D

func _process(delta: float) -> void:
	if turbine_blades:
		turbine_blades.rotation.z -= rotation_speed * delta
