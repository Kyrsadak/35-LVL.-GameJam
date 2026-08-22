extends Node

signal robot_switched(active_robot: Node)
signal hud_message_requested(text: String, duration: float)
signal clue_revealed(text: String)
signal level_completed()
signal level_failed(reason: String)

var atlas: Node = null
var cipher: Node = null
var active_robot: Node = null
var charging_station: Node3D = null
var camera_pivot: Node3D = null

var current_level_index: int = 1
var is_game_paused: bool = false

var discovered_clues: Dictionary = {}

func register_level(level_idx: int, atlas_node: Node, cipher_node: Node, station: Node3D, cam_pivot: Node3D = null) -> void:
	current_level_index = level_idx
	atlas = atlas_node
	cipher = cipher_node
	charging_station = station
	camera_pivot = cam_pivot
	discovered_clues.clear()

	# Configure battery discharge rates per level
	var rate = 2.8 # ~35s on lvl 1
	if level_idx == 2:
		rate = 3.2 # ~30s on lvl 2
	elif level_idx >= 3:
		rate = 3.6 # ~27s on lvl 3

	if atlas:
		if "discharge_rate" in atlas:
			atlas.discharge_rate = rate
		if atlas.has_signal("discharged") and not atlas.discharged.is_connected(_on_robot_discharged):
			atlas.discharged.connect(_on_robot_discharged.bind(atlas))
		if atlas.has_signal("guide_read") and not atlas.guide_read.is_connected(_on_guide_read):
			atlas.guide_read.connect(_on_guide_read)
		if "battery" in atlas and "max_battery" in atlas:
			atlas.battery_changed.emit(atlas.battery, atlas.max_battery)
			
	if cipher:
		if "discharge_rate" in cipher:
			cipher.discharge_rate = rate
		if cipher.has_signal("discharged") and not cipher.discharged.is_connected(_on_robot_discharged):
			cipher.discharged.connect(_on_robot_discharged.bind(cipher))
		if "battery" in cipher and "max_battery" in cipher:
			cipher.battery_changed.emit(cipher.battery, cipher.max_battery)

	# By default start with Atlas
	set_active_robot(atlas)

func set_active_robot(robot: Node) -> void:
	if not robot:
		return
	active_robot = robot
	if atlas and atlas.has_method("set_active"):
		atlas.set_active(atlas == active_robot)
	if cipher and cipher.has_method("set_active"):
		cipher.set_active(cipher == active_robot)
	
	robot_switched.emit(active_robot)

func _unhandled_input(event: InputEvent) -> void:
	if is_game_paused:
		return

	if event.is_action_pressed("switch_robot"):
		try_switch_robot()
	elif event.is_action_pressed("restart_level"):
		restart_level()

func try_switch_robot() -> void:
	if not atlas or not cipher or not active_robot:
		return
	
	var target_robot = cipher if active_robot == atlas else atlas
	var target_name = target_robot.robot_display_name if "robot_display_name" in target_robot else "РОБОТ"

	# Stop motion of current robot so it stands still where it is
	if active_robot is CharacterBody3D:
		active_robot.velocity = Vector3.ZERO

	# Switch control without any teleportation
	set_active_robot(target_robot)
	show_message("🔄 Управление: " + target_name, 1.5)
	if SoundManager:
		SoundManager.play_switch()

func _on_robot_discharged(robot: Node) -> void:
	var r_name = robot.robot_display_name if "robot_display_name" in robot else "РОБОТ"
	show_message("⚡ БАТАРЕЯ " + r_name + " РАЗРЯЖЕНА! Перезапуск...", 2.5)
	if SoundManager:
		SoundManager.play_spark_error()
	level_failed.emit("Батарея разряжена")
	get_tree().create_timer(2.0).timeout.connect(restart_level)

func _on_guide_read(guide_id: String, clue_text: String) -> void:
	discovered_clues[guide_id] = clue_text
	clue_revealed.emit(clue_text)
	show_message(clue_text, 3.5)
	if SoundManager:
		SoundManager.play_tablet_read()

func show_message(text: String, duration: float = 2.0) -> void:
	hud_message_requested.emit(text, duration)

func complete_level() -> void:
	level_completed.emit()
	if SoundManager:
		SoundManager.play_success()
	show_message("🎉 ЭНЕРГОБЛОК ЗАПУЩЕН! Уровень пройден!", 3.0)
	get_tree().create_timer(2.0).timeout.connect(func():
		if GameManager:
			GameManager.next_level()
	)

func restart_level() -> void:
	get_tree().reload_current_scene()
