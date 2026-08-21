# res://game/scripts/Hazard.gd
extends Area2D

## Статичное препятствие: убивает игрока в любом состоянии.
## Мигание для читаемости (visual pulsation).

@onready var core: Polygon2D = get_node_or_null("CoreDanger")

var _t: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_t += delta
	if core:
		var pulse: float = 0.6 + 0.4 * (0.5 + 0.5 * sin(_t * 6.0))
		var c := core.color
		c.a = pulse
		core.color = c

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and body.has_method("die"):
		body.die()
