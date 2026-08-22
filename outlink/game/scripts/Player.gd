# res://game/scripts/Player.gd
extends CharacterBody2D
class_name Player

## Дрон-игрок. FSM: TETHERED (на кабеле) <-> INDEPENDENT (автономность).
## В TETHERED — бесконечная энергия, но радиус ограничен.
## В INDEPENDENT — запас батареи (увеличивается от найденных Оазисов Свободы!).

enum State { TETHERED, INDEPENDENT }

@export_group("Движение и Скорость")
@export_range(50.0, 600.0, 10.0, "suffix:px/s") var tethered_speed: float = 240.0
@export_range(100.0, 800.0, 10.0, "suffix:px/s") var independent_speed: float = 360.0

@export_group("Механика Троса (Tether & Slingshot)")
@export_range(100.0, 800.0, 10.0, "suffix:px") var max_tether_length: float = 280.0
@export_range(200.0, 1500.0, 20.0, "suffix:px/s") var slingshot_power_min: float = 450.0
@export_range(200.0, 2000.0, 20.0, "suffix:px/s") var slingshot_power_max: float = 950.0
@export_range(0.0, 1.0, 0.05) var release_threshold: float = 0.35 ## Минимальное натяжение для рывка

@export_group("Батарея и Автономность")
@export_range(1.0, 30.0, 0.5, "suffix:сек") var max_battery: float = 6.0

@export_group("Автономность — физика")
@export_range(0.5, 1.0, 0.01) var free_damping: float = 0.985
@export_range(0.0, 3000.0, 10.0) var free_dash_decay: float = 900.0

var current_state: State = State.TETHERED
var current_socket_pos: Vector2 = Vector2.ZERO
var current_battery: float = 6.0
var dash_velocity: Vector2 = Vector2.ZERO
var tension: float = 0.0
var alive: bool = true

@onready var tether_line: Line2D = $TetherLine
@onready var release_particles: CPUParticles2D = $ReleaseParticles
@onready var trail_particles: CPUParticles2D = $TrailParticles
@onready var visual_body: Node2D = $VisualBody
@onready var direction_pointer: Polygon2D = $DirectionPointer

func get_effective_max_battery() -> float:
	return max_battery + GameManager.get_battery_bonus()

func get_effective_slingshot_max() -> float:
	return slingshot_power_max * (1.0 + GameManager.get_slingshot_bonus())

func _ready() -> void:
	add_to_group("Player")
	current_battery = get_effective_max_battery()
	current_socket_pos = global_position
	alive = true

	# Регистрируемся в GameManager для respawn-логики
	GameManager.register_player(self)
	GameManager.set_checkpoint(global_position)

	# Стартовое состояние — на кабеле
	current_state = State.TETHERED
	EventBus.battery_changed.emit(current_battery, get_effective_max_battery())
	EventBus.tension_changed.emit(0.0)

func _physics_process(delta: float) -> void:
	if not alive:
		return

	if Input.is_action_just_pressed("restart"):
		die()
		return

	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	match current_state:
		State.TETHERED:
			_physics_tethered(delta, input_vector)
		State.INDEPENDENT:
			_physics_independent(delta, input_vector)

	# Поворот "носика" по направлению движения
	if velocity.length() > 5.0:
		direction_pointer.rotation = velocity.angle() + PI / 2.0

	# Пульсация тела
	if visual_body:
		var pulse := 1.0 + 0.05 * sin(Time.get_ticks_msec() / 180.0)
		visual_body.scale = Vector2(pulse, pulse)

func _physics_tethered(delta: float, input_vector: Vector2) -> void:
	trail_particles.emitting = false

	var target_vel := input_vector * tethered_speed
	var to_socket := global_position - current_socket_pos
	var dist := to_socket.length()

	# Если трос натянут на максимум — разрешаем скользить по кругу (тангенциально) и идти внутрь,
	# блокируя только дальнейшее движение наружу (игрок больше никогда не застревает!)
	if dist >= max_tether_length and dist > 0.001:
		var outward := to_socket.normalized()
		var outward_speed := target_vel.dot(outward)
		if outward_speed > 0.0:
			# Убираем только наружную составляющую скорости, оставляя свободное скольжение по орбите
			target_vel -= outward * outward_speed

	velocity = target_vel + dash_velocity
	dash_velocity = dash_velocity.move_toward(Vector2.ZERO, 1400.0 * delta)
	move_and_slide()

	# Мягкая фиксация максимального радиуса после физики
	to_socket = global_position - current_socket_pos
	dist = to_socket.length()
	if dist > max_tether_length and dist > 0.001:
		global_position = current_socket_pos + to_socket.normalized() * max_tether_length
		dist = max_tether_length

	# Обновление натяжения
	tension = clampf(dist / max_tether_length, 0.0, 1.0)
	EventBus.tension_changed.emit(tension)

	# Отрыв по SPACE
	if Input.is_action_just_pressed("ui_accept") and tension >= release_threshold:
		break_tether()

func _physics_independent(delta: float, input_vector: Vector2) -> void:
	trail_particles.emitting = true

	# Управление в свободном полёте — импульсно-инерционное
	var target_vel := input_vector * independent_speed
	velocity = velocity.lerp(target_vel + dash_velocity, 0.14)
	velocity *= free_damping
	dash_velocity = dash_velocity.move_toward(Vector2.ZERO, free_dash_decay * delta)

	move_and_slide()

	# Таймер батареи
	current_battery -= delta
	EventBus.battery_changed.emit(current_battery, get_effective_max_battery())
	if current_battery <= 0.0:
		die()

# ---------------------------------------------------------
# СМЕНА СОСТОЯНИЙ
# ---------------------------------------------------------

func break_tether() -> void:
	current_state = State.INDEPENDENT
	current_battery = get_effective_max_battery()
	tension = 0.0
	EventBus.tension_changed.emit(0.0)

	# Базовое направление рывка — ОТ якоря к игроку
	var away_from_socket := (global_position - current_socket_pos).normalized()
	if away_from_socket == Vector2.ZERO:
		away_from_socket = Vector2.RIGHT

	var dir := away_from_socket

	# Если игрок активно движется в согласованном направлении — используем движение
	var move_dir := velocity.normalized()
	if move_dir != Vector2.ZERO and move_dir.dot(away_from_socket) > 0.2:
		dir = move_dir

	# Сила рывка пропорциональна натяжению с учетом апгрейда
	var power: float = lerpf(slingshot_power_min, get_effective_slingshot_max(), tension)
	dash_velocity = dir * power
	velocity = dash_velocity

	# FX
	release_particles.restart()
	release_particles.emitting = true

	EventBus.tether_broken.emit(dash_velocity, tension)
	EventBus.request_camera_shake.emit(9.0, 0.25)
	EventBus.request_hitstop.emit(0.09, 0.25)
	EventBus.request_flash.emit(Color(0.4, 0.9, 1.0, 0.35), 0.15)

func attach_to_socket(pos: Vector2, progress_value: int) -> void:
	current_state = State.TETHERED
	current_socket_pos = pos
	current_battery = get_effective_max_battery()
	dash_velocity = Vector2.ZERO
	global_position = pos
	velocity = Vector2.ZERO

	GameManager.set_checkpoint(pos)
	EventBus.battery_changed.emit(current_battery, get_effective_max_battery())
	EventBus.tension_changed.emit(0.0)
	EventBus.socket_reached.emit(pos, progress_value)
	EventBus.request_camera_shake.emit(4.0, 0.12)

func die() -> void:
	if not alive:
		return
	alive = false
	trail_particles.emitting = false
	visible = false
	EventBus.player_died.emit()

func respawn_at(pos: Vector2) -> void:
	alive = true
	visible = true
	global_position = pos
	velocity = Vector2.ZERO
	dash_velocity = Vector2.ZERO
	current_battery = get_effective_max_battery()
	current_state = State.TETHERED
	current_socket_pos = pos
	EventBus.battery_changed.emit(current_battery, get_effective_max_battery())
	EventBus.tension_changed.emit(0.0)
