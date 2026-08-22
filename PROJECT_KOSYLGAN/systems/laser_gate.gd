class_name LaserGate
extends StaticBody3D

@export var is_active: bool = true
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var laser_beams: Node3D = $LaserBeams
@onready var light: OmniLight3D = $OmniLight3D

func _ready() -> void:
	set_active(is_active)

func set_active(active: bool) -> void:
	is_active = active
	if collision_shape:
		collision_shape.disabled = not is_active
	if laser_beams:
		laser_beams.visible = is_active
	if light:
		light.visible = is_active

func open() -> void:
	set_active(false)

func close() -> void:
	set_active(true)
