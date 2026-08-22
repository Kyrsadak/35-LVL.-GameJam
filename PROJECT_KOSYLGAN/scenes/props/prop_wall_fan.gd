class_name WallFan
extends Node3D

@export var rotation_speed: float = 3.5
@onready var turbine_blades: Node3D = $VentFrame/Turbine

func _process(delta: float) -> void:
	if turbine_blades:
		turbine_blades.rotation.z += rotation_speed * delta
