# res://game/scripts/Gate.gd
extends Area2D
class_name Gate

## Лазерные врата: блокируют игрока только когда он в состоянии TETHERED.
## В INDEPENDENT (после рывка) — пропускают. Это ключевой пазл-элемент.

@onready var beam: Polygon2D = get_node_or_null("Beam")
@onready var post_top: Polygon2D = get_node_or_null("PostTop")
@onready var post_bottom: Polygon2D = get_node_or_null("PostBottom")

var _t: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_t += delta
	if beam:
		# Пульсация луча
		var intensity: float = 0.6 + 0.4 * (0.5 + 0.5 * sin(_t * 10.0))
		var c := beam.color
		c.a = intensity
		beam.color = c

func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	var p := body as Player
	# Врата пропускают, только если игрок в INDEPENDENT
	if p.current_state == Player.State.TETHERED:
		p.die()
