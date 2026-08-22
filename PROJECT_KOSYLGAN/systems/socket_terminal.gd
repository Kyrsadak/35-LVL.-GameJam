class_name SocketTerminal
extends Area3D

@onready var socket_marker: Marker3D = $SocketMarker
@onready var light: OmniLight3D = $OmniLight3D

var is_filled: bool = false

func _ready() -> void:
	add_to_group("socket_terminal")
	add_to_group("interactable")

func insert_module(module: Node) -> void:
	if is_filled or not module:
		return
	is_filled = true
	if "is_carried" in module:
		module.is_carried = false
	module.get_parent().remove_child(module)
	socket_marker.add_child(module)
	module.position = Vector3.ZERO
	module.rotation = Vector3.ZERO
	
	if light:
		light.light_color = Color(0.1, 1.0, 0.4)
		light.light_energy = 3.5

	if RobotManager:
		RobotManager.complete_level()
