class_name GuideTablet
extends Area3D

@export var guide_id: String = "guide_1"
@export_multiline var clue_text: String = "СХЕМА: ПЕРЕРЕЖЬТЕ КРАСНЫЙ ПРОВОД"

var hologram: Node3D = null
var is_read: bool = false
var time_passed: float = 0.0

func _ready() -> void:
	hologram = find_child("Hologram", true, false) as Node3D
	if not hologram:
		hologram = find_child("MeshHolder", true, false) as Node3D
	add_to_group("guide_tablet")
	add_to_group("interactable")

func _process(delta: float) -> void:
	time_passed += delta
	if hologram:
		hologram.position.y = 1.35 + sin(time_passed * 2.5) * 0.08
		hologram.rotation.y += delta * 1.5

func read_guide() -> Dictionary:
	is_read = true
	return {
		"id": guide_id,
		"text": clue_text
	}
