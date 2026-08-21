# res://game/scripts/Sandstorm.gd
extends Area2D
class_name Sandstorm

## Движущаяся зона опасности: смерч. Патрулирует между двумя точками.
## Убивает игрока в любом состоянии.

@export_group("Патрулирование")
@export var patrol_offset: Vector2 = Vector2(300, 0) ## Направление и дальность патрулирования от старта
@export_range(20.0, 400.0, 5.0) var speed: float = 120.0
@export var start_moving: bool = true

@onready var visual: Node2D = get_node_or_null("Visual")

var _start_pos: Vector2
var _target_pos: Vector2
var _going_forward: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_start_pos = position
	_target_pos = _start_pos + patrol_offset

func _physics_process(delta: float) -> void:
	if not start_moving:
		return
	var dest: Vector2 = _target_pos if _going_forward else _start_pos
	position = position.move_toward(dest, speed * delta)
	if position.distance_to(dest) < 1.0:
		_going_forward = not _going_forward

func _process(delta: float) -> void:
	if visual:
		visual.rotation += delta * 2.5

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and body.has_method("die"):
		body.die()
