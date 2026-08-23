extends Node

var current_level_index: int = 0
var total_levels: int = 5
var level_scenes = [
	"res://scenes/levels/tutorial.tscn",
	"res://scenes/levels/level_bukhara.tscn",
	"res://scenes/levels/level_khiva.tscn",
	"res://scenes/levels/level_samarkand.tscn",
	"res://scenes/levels/level_tashkent.tscn"
]

var total_game_time: float = 0.0
var total_switches: int = 0
var is_timer_running: bool = false

func _ready() -> void:
	# Ensure the game window is maximized on startup
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# ESC to return to main menu from gameplay
		if event.keycode == KEY_ESCAPE:
			var current_scene = get_tree().current_scene
			if current_scene and not current_scene.scene_file_path.ends_with("main_menu.tscn"):
				return_to_main_menu()
				get_viewport().set_input_as_handled()
				return
		# F11 or Alt+Enter to toggle fullscreen
		elif event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			toggle_fullscreen()
		# F1 - F5 Quick Debug Level Jump
		elif event.keycode == KEY_F1:
			load_level(0)
		elif event.keycode == KEY_F2:
			load_level(1)
		elif event.keycode == KEY_F3:
			load_level(2)
		elif event.keycode == KEY_F4:
			load_level(3)
		elif event.keycode == KEY_F5:
			load_level(4)

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
	current_level_index = 0
	total_game_time = 0.0
	total_switches = 0
	is_timer_running = true
	load_level(0)

func load_level(idx: int) -> void:
	current_level_index = idx
	if idx >= 0 and idx < level_scenes.size():
		get_tree().change_scene_to_file(level_scenes[idx])
	else:
		show_victory()

func next_level() -> void:
	if current_level_index + 1 < total_levels:
		current_level_index += 1
		load_level(current_level_index)
	else:
		show_victory()

func show_victory() -> void:
	is_timer_running = false
	get_tree().change_scene_to_file("res://ui/captcha_ending.tscn")

func return_to_main_menu() -> void:
	is_timer_running = false
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func restart_current_level() -> void:
	load_level(current_level_index)
