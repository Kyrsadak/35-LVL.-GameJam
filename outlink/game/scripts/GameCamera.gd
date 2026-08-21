# res://game/scripts/GameCamera.gd
extends Camera2D

## Игровая камера: следит за игроком, поддерживает screen shake и легкий lookahead.
## Также реагирует на глобальные запросы hitstop через Engine.time_scale.

@export var follow_target_group: String = "Player"
@export_range(0.02, 1.0, 0.01) var follow_smoothing: float = 0.12
@export_range(0.0, 400.0, 5.0) var lookahead_amount: float = 80.0
@export_range(0.0, 1.0, 0.05) var lookahead_smoothing: float = 0.08

var _shake_strength: float = 0.0
var _shake_time_left: float = 0.0
var _shake_duration: float = 0.0
var _target_position_smooth: Vector2 = Vector2.ZERO
var _lookahead_smooth: Vector2 = Vector2.ZERO
var _last_real_time_msec: int = 0
var _initialized: bool = false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_last_real_time_msec = Time.get_ticks_msec()
	EventBus.request_camera_shake.connect(_on_request_shake)
	EventBus.request_hitstop.connect(_on_request_hitstop)

func _process(_delta: float) -> void:
	# Используем реальное (unscaled) время, чтобы hitstop не растягивал шейк/сглаживание
	var now := Time.get_ticks_msec()
	var real_delta: float = float(now - _last_real_time_msec) / 1000.0
	_last_real_time_msec = now

	var player := _find_player()
	if player:
		var target := player.global_position
		if not _initialized:
			_target_position_smooth = target
			global_position = target
			_initialized = true

		# Lookahead — по направлению velocity
		var vel_target := Vector2.ZERO
		if "velocity" in player:
			var v: Vector2 = player.velocity
			if v.length() > 30.0:
				vel_target = v.normalized() * lookahead_amount
		_lookahead_smooth = _lookahead_smooth.lerp(vel_target, lookahead_smoothing)

		_target_position_smooth = _target_position_smooth.lerp(target + _lookahead_smooth, follow_smoothing)
		global_position = _target_position_smooth

	# Shake
	if _shake_time_left > 0.0:
		_shake_time_left -= real_delta
		var t: float = clampf(_shake_time_left / max(_shake_duration, 0.001), 0.0, 1.0)
		var strength: float = _shake_strength * t
		offset = Vector2(_rng.randf_range(-strength, strength), _rng.randf_range(-strength, strength))
	else:
		offset = offset.lerp(Vector2.ZERO, 0.3)

	# Hitstop: время сбрасывается таймером в _on_request_hitstop через SceneTreeTimer с ignore_time_scale.

func _find_player() -> Node2D:
	var players := get_tree().get_nodes_in_group(follow_target_group)
	if players.size() > 0:
		return players[0] as Node2D
	return null

func _on_request_shake(strength: float, duration: float) -> void:
	# Не гасим более сильный шейк более слабым
	if strength * duration > _shake_strength * _shake_time_left:
		_shake_strength = strength
		_shake_duration = duration
		_shake_time_left = duration

func _on_request_hitstop(duration: float, scale: float) -> void:
	Engine.time_scale = clampf(scale, 0.05, 1.0)
	# ignore_time_scale=true — таймер тикает по реальному времени
	var t := get_tree().create_timer(duration, true, false, true)
	t.timeout.connect(_reset_time_scale)

func _reset_time_scale() -> void:
	Engine.time_scale = 1.0
