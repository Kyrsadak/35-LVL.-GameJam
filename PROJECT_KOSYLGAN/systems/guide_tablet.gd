class_name GuideTablet
extends Area3D

@export var guide_id: String = "guide_1"
@export_multiline var clue_text: String = "СХЕМА: ПЕРЕРЕЖЬТЕ КРАСНЫЙ ПРОВОД"

@onready var mesh_holder: Node3D = $MeshHolder

var is_read: bool = false
var time_passed: float = 0.0

func _ready() -> void:
	add_to_group("guide_tablet")
	add_to_group("interactable")

func _process(delta: float) -> void:
	time_passed += delta
	if mesh_holder:
		mesh_holder.position.y = 0.4 + sin(time_passed * 2.5) * 0.08
		mesh_holder.rotation.y += delta * 1.0

func read_guide() -> Dictionary:
	is_read = true
	return {
		"id": guide_id,
		"text": clue_text
	}
