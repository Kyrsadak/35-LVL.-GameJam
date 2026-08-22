class_name LaserGate
extends StaticBody3D

@export var is_active: bool = true
var collision_shape: CollisionShape3D = null
var laser_beams: Node3D = null
var light: OmniLight3D = null

func _ready() -> void:
	collision_shape = find_child("CollisionShape3D", true, false) as CollisionShape3D
	laser_beams = find_child("Lasers", true, false) as Node3D
	if not laser_beams:
		laser_beams = find_child("LaserBeams", true, false) as Node3D
	light = find_child("OmniLight3D", true, false) as OmniLight3D
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
