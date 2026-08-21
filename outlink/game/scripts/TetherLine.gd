# res://game/scripts/TetherLine.gd
extends Line2D

## Визуализация кабеля от игрока к якорю. Цвет зависит от натяжения.
## Волновой эффект — небольшая синусоида для "живого" провода.

@export_group("Визуал Троса")
@export var normal_color: Color = Color(0.2, 0.8, 1.0, 0.95)   ## синий
@export var tension_color: Color = Color(1.0, 0.2, 0.2, 1.0)   ## красный
@export_range(2, 32, 1) var segments: int = 14                 ## Число сегментов для волнистости
@export_range(0.0, 30.0, 0.5) var wave_amplitude: float = 6.0
@export_range(0.0, 20.0, 0.1) var wave_speed: float = 8.0

@onready var player: CharacterBody2D = get_parent()
var _time: float = 0.0

func _process(delta: float) -> void:
	if player == null:
		visible = false
		return

	_time += delta

	if player.current_state == player.State.TETHERED and player.alive:
		visible = true
		clear_points()
		var start := Vector2.ZERO                                          # локальные координаты игрока
		var end := to_local(player.current_socket_pos)
		var seg_vec := end - start
		var length := seg_vec.length()
		var normal := Vector2.ZERO
		if length > 0.001:
			normal = seg_vec.normalized().rotated(PI / 2.0)

		var tension_amp: float = wave_amplitude * (1.0 - player.tension * 0.7)
		var slack_droop: float = 24.0 * (1.0 - player.tension)             # провис на слабом натяжении

		for i in range(segments + 1):
			var t: float = float(i) / segments
			var point := start.lerp(end, t)
			# Синусоидальная волна вдоль кабеля
			var wave: float = sin(t * PI * 2.0 - _time * wave_speed) * tension_amp * sin(t * PI)
			# Провис — параболическая форма
			var droop: float = 4.0 * t * (1.0 - t) * slack_droop
			point += normal * wave
			point += Vector2(0, droop)
			add_point(point)

		# Плавная интерполяция цвета по натяжению
		var t_ratio: float = clampf(player.tension, 0.0, 1.0)
		default_color = normal_color.lerp(tension_color, t_ratio)

		# Ширина: чуть толще на натяжении
		width = lerpf(3.0, 5.0, t_ratio)
	else:
		visible = false
