# res://game/scripts/GameManager.gd
extends Node

## Центральный менеджер: список уровней, прогресс, respawn, победы/поражения.
## Реализован как autoload-синглтон.

const LEVELS: Array[String] = [
	"res://game/scenes/levels/Level1.tscn",
	"res://game/scenes/levels/Level2.tscn",
	"res://game/scenes/levels/Level3.tscn",
]

const HUD_SCENE := "res://game/scenes/ui/HUD.tscn"
const MAIN_MENU_SCENE := "res://game/scenes/ui/MainMenu.tscn"
const VICTORY_SCENE := "res://game/scenes/ui/VictoryScreen.tscn"

## Игровой лор: 35 "Оазисов Свободы" — счётчик прогресса
const TOTAL_OASES: int = 35

var current_level_index: int = 0
var oases_collected: int = 0
var best_times: Dictionary = {}      # level_index -> best time (сек)
var current_level_start_msec: int = 0
var deaths_current_level: int = 0

# ссылки на активные объекты уровня
var player: Node = null
var last_checkpoint: Vector2 = Vector2.ZERO
var last_checkpoint_valid: bool = false

func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)
	EventBus.level_completed.connect(_on_level_completed)
	EventBus.socket_reached.connect(_on_socket_reached)

# ---------------------------------------------------------
# ЗАПУСК И ПРОГРЕСС
# ---------------------------------------------------------

func start_new_game() -> void:
	current_level_index = 0
	oases_collected = 0
	deaths_current_level = 0
	last_checkpoint_valid = false
	_load_level(current_level_index)

func load_level(idx: int) -> void:
	current_level_index = idx
	deaths_current_level = 0
	last_checkpoint_valid = false
	_load_level(current_level_index)

func _load_level(idx: int) -> void:
	if idx < 0 or idx >= LEVELS.size():
		push_error("GameManager: неверный индекс уровня %d" % idx)
		return
	current_level_start_msec = Time.get_ticks_msec()
	# Через deferred, чтобы это работало и из сигналов
	get_tree().change_scene_to_file.call_deferred(LEVELS[idx])

func restart_current_level() -> void:
	deaths_current_level = 0
	last_checkpoint_valid = false
	current_level_start_msec = Time.get_ticks_msec()
	get_tree().reload_current_scene.call_deferred()

func go_to_main_menu() -> void:
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU_SCENE)

# ---------------------------------------------------------
# CHECKPOINT & RESPAWN
# ---------------------------------------------------------

func set_checkpoint(pos: Vector2) -> void:
	last_checkpoint = pos
	last_checkpoint_valid = true

func register_player(p: Node) -> void:
	player = p

func _on_socket_reached(pos: Vector2, progress_value: int) -> void:
	set_checkpoint(pos)
	oases_collected = min(oases_collected + progress_value, TOTAL_OASES)
	EventBus.oasis_progress_changed.emit(oases_collected, TOTAL_OASES)

func _on_player_died() -> void:
	deaths_current_level += 1
	# небольшой delay + вспышка, потом respawn
	EventBus.request_flash.emit(Color(1.0, 0.2, 0.2, 0.55), 0.35)
	EventBus.request_camera_shake.emit(14.0, 0.35)
	get_tree().create_timer(0.35, true, false, true).timeout.connect(_do_respawn)

func _do_respawn() -> void:
	if player == null or not is_instance_valid(player):
		# Если игрока уже нет — просто рестартим сцену
		get_tree().reload_current_scene.call_deferred()
		return
	if last_checkpoint_valid and player.has_method("respawn_at"):
		player.respawn_at(last_checkpoint)
		EventBus.player_respawned.emit(last_checkpoint)
	else:
		get_tree().reload_current_scene.call_deferred()

# ---------------------------------------------------------
# ПОБЕДА
# ---------------------------------------------------------

func _on_level_completed() -> void:
	var elapsed := float(Time.get_ticks_msec() - current_level_start_msec) / 1000.0
	if not best_times.has(current_level_index) or elapsed < best_times[current_level_index]:
		best_times[current_level_index] = elapsed

	# Заполним оставшийся прогресс до "все оазисы этого уровня"
	# (для наглядности счётчика 35/35 в финале)
	if current_level_index == LEVELS.size() - 1:
		oases_collected = TOTAL_OASES
		EventBus.oasis_progress_changed.emit(oases_collected, TOTAL_OASES)

	if current_level_index + 1 >= LEVELS.size():
		EventBus.game_won.emit()
		get_tree().create_timer(1.4, true, false, true).timeout.connect(_go_to_victory)
	else:
		get_tree().create_timer(1.4, true, false, true).timeout.connect(_next_level)

func _next_level() -> void:
	load_level(current_level_index + 1)

func _go_to_victory() -> void:
	get_tree().change_scene_to_file.call_deferred(VICTORY_SCENE)

# ---------------------------------------------------------
# УТИЛИТЫ
# ---------------------------------------------------------

func format_time(seconds: float) -> String:
	var m := int(seconds) / 60
	var s := int(seconds) % 60
	var ms := int(fmod(seconds, 1.0) * 100.0)
	return "%02d:%02d.%02d" % [m, s, ms]

func get_level_name(idx: int) -> String:
	match idx:
		0: return "СЕКТОР 1 — ОБУЧЕНИЕ"
		1: return "СЕКТОР 2 — НАТЯЖЕНИЕ"
		2: return "СЕКТОР 3 — АВТОНОМИЯ"
		_: return "СЕКТОР %d" % (idx + 1)
