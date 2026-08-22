class_name WallFan
extends Node3D

@export var rotation_speed: float = 4.0
@onready var blades: Node3D = $Housing/Blades

func _process(delta: float) -> void:
	if blades:
		blades.rotation.z += rotation_speed * delta
