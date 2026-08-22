extends Node

var current_level_index: int = 1
var total_levels: int = 3
var level_scenes = [
	"res://scenes/levels/level1.tscn",
	"res://scenes/levels/level2.tscn",
	"res://scenes/levels/level3.tscn"
]

var total_game_time: float = 0.0
var total_switches: int = 0
var is_timer_running: bool = false

func _ready() -> void:
	# Ensure the game window is maximized on startup
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

func _unhandled_input(event: InputEvent) -> void:
	# F11 or Alt+Enter to toggle fullscreen
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			toggle_fullscreen()

func toggle_fullscreen() -> void:
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _process(delta: float) -> void:
	if is_timer_running:
		total_game_time += delta

func start_new_game() -> void:
	current_level_index = 1
	total_game_time = 0.0
	total_switches = 0
	is_timer_running = true
	load_level(1)

func load_level(idx: int) -> void:
	current_level_index = idx
	if idx >= 1 and idx <= level_scenes.size():
		get_tree().change_scene_to_file(level_scenes[idx - 1])
	else:
		show_victory()

func next_level() -> void:
	if current_level_index < total_levels:
		current_level_index += 1
		load_level(current_level_index)
	else:
		show_victory()

func show_victory() -> void:
	is_timer_running = false
	get_tree().change_scene_to_file("res://ui/victory_screen.tscn")

func return_to_main_menu() -> void:
	is_timer_running = false
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
