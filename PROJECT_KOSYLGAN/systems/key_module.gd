class_name KeyModule
extends Area3D

@export var module_name: String = "Ключевой Модуль"
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_core: MeshInstance3D = $CoreMesh

var is_carried: bool = false
var time_passed: float = 0.0

func _ready() -> void:
	add_to_group("key_module")
	add_to_group("interactable")

func _process(delta: float) -> void:
	if not is_carried:
		time_passed += delta
		if mesh_core:
			mesh_core.position.y = 0.5 + sin(time_passed * 3.0) * 0.08
			mesh_core.rotation.y += delta * 1.5

func pick_up(carrier: Marker3D) -> void:
	is_carried = true
	collision_shape.disabled = true
	get_parent().remove_child(self)
	carrier.add_child(self)
	position = Vector3.ZERO
	rotation = Vector3.ZERO

func drop(drop_pos: Vector3) -> void:
	is_carried = false
	collision_shape.disabled = false
	var scene_root = get_tree().current_scene
	get_parent().remove_child(self)
	scene_root.add_child(self)
	global_position = drop_pos
