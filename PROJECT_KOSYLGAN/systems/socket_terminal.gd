class_name SocketTerminal
extends Area3D

var socket_marker: Node3D = null
var light: OmniLight3D = null

var is_filled: bool = false

func _ready() -> void:
	socket_marker = find_child("SocketMarker", true, false) as Node3D
	if not socket_marker:
		socket_marker = find_child("SocketHole", true, false) as Node3D
	if not socket_marker:
		socket_marker = self
	light = find_child("OmniLight3D", true, false) as OmniLight3D
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
	module.position = Vector3(0, 0.4, 0)
	module.rotation = Vector3.ZERO
	
	if light:
		light.light_color = Color(0.1, 1.0, 0.4)
		light.light_energy = 2.0

	if RobotManager:
		RobotManager.complete_level()
