extends Node
## PositionResetter — сбрасывает позицию игрока если он упал за пределы уровня
## Автоматически активируется при Y < threshold

@export var fall_threshold: float = -20.0
@export var reset_position: Vector3 = Vector3.ZERO

var _parent: Node3D = null
var _last_safe_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	_parent = get_parent() as Node3D
	if _parent:
		_last_safe_position = _parent.global_position

func _physics_process(_delta: float) -> void:
	if not _parent or not is_instance_valid(_parent):
		return
	
	var y = _parent.global_position.y
	
	# Обновляем последнюю безопасную позицию когда выше порога
	if y > fall_threshold + 2.0:
		_last_safe_position = _parent.global_position
	
	# Если упал ниже порога — сброс
	if y < fall_threshold:
		reset_to_safe()

func reset_to_safe() -> void:
	if not _parent or not is_instance_valid(_parent):
		return
	var target = reset_position if reset_position != Vector3.ZERO else _last_safe_position
	_parent.global_position = target + Vector3(0, 0.5, 0)
	# Обнуляем скорость если CharacterBody3D
	if _parent is CharacterBody3D:
		(_parent as CharacterBody3D).velocity = Vector3.ZERO
