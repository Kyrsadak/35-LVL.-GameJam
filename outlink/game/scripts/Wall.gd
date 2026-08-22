# res://game/scripts/Wall.gd
extends StaticBody2D
class_name Wall

## Стена — статичное физическое препятствие. Просто блокирует движение.
## Игрок не умирает при контакте, только не может проехать.

@export var size: Vector2 = Vector2(64, 64):
	set(v):
		size = v
		_apply_size()

@export var wall_color: Color = Color(0.18, 0.24, 0.32, 1.0):
	set(v):
		wall_color = v
		_apply_color()

@export var edge_color: Color = Color(0.35, 0.55, 0.85, 1.0):
	set(v):
		edge_color = v
		_apply_color()

@onready var body_rect: Polygon2D = $Body
@onready var edge_rect: Polygon2D = $Edge
@onready var shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_apply_size()
	_apply_color()

func _apply_size() -> void:
	var b := get_node_or_null("Body") as Polygon2D
	var e := get_node_or_null("Edge") as Polygon2D
	var sh := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if b:
		var hs := size * 0.5
		b.polygon = PackedVector2Array([Vector2(-hs.x, -hs.y), Vector2(hs.x, -hs.y), Vector2(hs.x, hs.y), Vector2(-hs.x, hs.y)])
	if e:
		var hs2 := size * 0.5 - Vector2(2, 2)
		e.polygon = PackedVector2Array([Vector2(-hs2.x, -hs2.y), Vector2(hs2.x, -hs2.y), Vector2(hs2.x, hs2.y), Vector2(-hs2.x, hs2.y)])
	if sh:
		# Создаем УНИКАЛЬНЫЙ шейп для каждой стены, чтобы они не делили один ресурс и не блокировали проходы!
		var rect := RectangleShape2D.new()
		rect.size = size
		sh.shape = rect

func _apply_color() -> void:
	var b := get_node_or_null("Body") as Polygon2D
	var e := get_node_or_null("Edge") as Polygon2D
	if b:
		b.color = edge_color
	if e:
		e.color = wall_color
