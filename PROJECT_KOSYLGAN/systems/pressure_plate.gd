class_name PressurePlate
extends Area3D

signal activated()
signal deactivated()

@export var target_node_path: NodePath
@onready var button_mesh: MeshInstance3D = $ButtonMesh

var overlapping_count: int = 0
var is_pressed: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	overlapping_count += 1
	if not is_pressed and overlapping_count > 0:
		_press()

func _on_body_exited(body: Node3D) -> void:
	overlapping_count = max(0, overlapping_count - 1)
	if is_pressed and overlapping_count == 0:
		_release()

func _press() -> void:
	is_pressed = true
	if button_mesh:
		var tween = create_tween()
		tween.tween_property(button_mesh, "position:y", 0.02, 0.15)
	activated.emit()
	
	if target_node_path != NodePath():
		var target = get_node_or_null(target_node_path)
		if target and target.has_method("open"):
			target.open()

func _release() -> void:
	is_pressed = false
	if button_mesh:
		var tween = create_tween()
		tween.tween_property(button_mesh, "position:y", 0.08, 0.15)
	deactivated.emit()
	
	if target_node_path != NodePath():
		var target = get_node_or_null(target_node_path)
		if target and target.has_method("close"):
			target.close()
