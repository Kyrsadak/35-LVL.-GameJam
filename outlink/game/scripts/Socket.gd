# res://game/scripts/Socket.gd
extends Area2D
class_name Socket

## Оазис / розетка / точка привязи.
## Игрок в состоянии INDEPENDENT, попадая сюда, — заново подключается (TETHERED).
## Поинты начисляются ТОЛЬКО ОДИН РАЗ при первой активации оазиса (фарм исключен!).

@export_group("Параметры Розетки / Базы")
@export var is_final_goal: bool = false              ## Финиш уровня
@export_range(1, 20, 1) var progress_value: int = 5 ## Сколько "оазисов" добавить в счётчик при ПЕРВОЙ активации
@export var is_starting_anchor: bool = false         ## Первый оазис уровня (игрок к нему уже привязан)

@onready var glow_core: Polygon2D = get_node_or_null("GlowCore")
@onready var glow_ring: Polygon2D = get_node_or_null("GlowRing")

var is_activated: bool = false
var _pulse_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if is_starting_anchor:
		is_activated = true
	_update_visuals()

func _update_visuals() -> void:
	if glow_core:
		if is_final_goal:
			glow_core.color = Color(1.0, 0.85, 0.2, 1.0) # Золото
		elif is_starting_anchor or is_activated:
			glow_core.color = Color(0.2, 1.0, 0.6, 1.0) # Ярко-зеленый (активирован)
		else:
			glow_core.color = Color(0.25, 0.6, 0.85, 0.85) # Спокойный синий (ждет активации)

func _process(delta: float) -> void:
	_pulse_time += delta
	if glow_ring:
		var s := 1.0 + 0.15 * sin(_pulse_time * 3.0)
		glow_ring.scale = Vector2(s, s)
		var a := 0.35 + 0.25 * (0.5 + 0.5 * sin(_pulse_time * 3.0))
		var col := glow_ring.color
		col.a = a
		glow_ring.color = col

func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	var p := body as Player

	if is_final_goal:
		if not is_activated:
			is_activated = true
			GameManager.add_oases(progress_value)
		EventBus.level_completed.emit()
		EventBus.request_camera_shake.emit(12.0, 0.4)
		EventBus.request_hitstop.emit(0.2, 0.3)
		return

	# Перепривязка ТОЛЬКО если игрок был в автономном режиме
	if p.current_state == Player.State.INDEPENDENT:
		var granted_points: int = 0
		if not is_activated:
			is_activated = true
			granted_points = progress_value
			_update_visuals()

		p.attach_to_socket(global_position, granted_points)
