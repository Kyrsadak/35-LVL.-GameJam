@tool
class_name DualGenerator
extends Area3D

signal battery_inserted(robot_id: String)
signal generator_fully_activated()

@export var target_gate_path: NodePath
@export var freedom_portal_path: NodePath

@onready var orange_core: MeshInstance3D = find_child("OrangeCore", true, false) as MeshInstance3D
@onready var green_core: MeshInstance3D = find_child("GreenCore", true, false) as MeshInstance3D
@onready var main_reactor_core: MeshInstance3D = find_child("MainReactorCore", true, false) as MeshInstance3D
@onready var gyro_ring_1: MeshInstance3D = find_child("GyroRing1", true, false) as MeshInstance3D
@onready var gyro_ring_2: MeshInstance3D = find_child("GyroRing2", true, false) as MeshInstance3D
@onready var console_screen: MeshInstance3D = find_child("ConsoleScreen", true, false) as MeshInstance3D
@onready var reactor_light: OmniLight3D = find_child("OmniLight3D", true, false) as OmniLight3D

var has_orange_battery: bool = false
var has_green_battery: bool = false
var is_active: bool = false
var time_passed: float = 0.0

func _ready() -> void:
	add_to_group("dual_generator")
	add_to_group("interactable")
	_update_screen_texture()
	_update_visuals()

func _process(delta: float) -> void:
	time_passed += delta
	
	# Animate Gyro Rings & Core
	if main_reactor_core:
		var speed = 3.5 if is_active else (1.5 if (has_orange_battery or has_green_battery) else 0.4)
		main_reactor_core.rotation.y += delta * speed
	if gyro_ring_1:
		gyro_ring_1.rotation.x += delta * (4.0 if is_active else 1.2)
	if gyro_ring_2:
		gyro_ring_2.rotation.z -= delta * (3.2 if is_active else 0.9)
		
	# Dynamic Lighting
	if reactor_light:
		if is_active:
			reactor_light.light_energy = 3.2 + 0.9 * sin(time_passed * 6.0)
		elif has_orange_battery or has_green_battery:
			reactor_light.light_energy = 1.6 + 0.4 * sin(time_passed * 3.0)
		else:
			reactor_light.light_energy = 0.9 + 0.2 * sin(time_passed * 1.5)

func try_insert_battery(robot: Node, battery: Node) -> bool:
	if is_active:
		return false

	var r_id = robot.robot_id if "robot_id" in robot else ""
	var b_req = battery.required_robot_id if "required_robot_id" in battery else ""

	if (r_id == "atlas" or b_req == "atlas") and not has_orange_battery:
		has_orange_battery = true
		_consume_battery(robot, battery, "ОРАНЖЕВОЕ ЯДРО DAU УСТАНОВЛЕНО В ГЕНЕРАТОР!")
		battery_inserted.emit("atlas")
		_check_full_activation()
		return true

	elif (r_id == "cipher" or b_req == "cipher") and not has_green_battery:
		has_green_battery = true
		_consume_battery(robot, battery, "ЗЕЛЕНОЕ ЯДРО JAM УСТАНОВЛЕНО В ГЕНЕРАТОР!")
		battery_inserted.emit("cipher")
		_check_full_activation()
		return true

	elif (r_id == "atlas" or b_req == "atlas") and has_orange_battery:
		if RobotManager:
			RobotManager.show_message("⚠️ Оранжевый слот генератора уже заполнен!", 2.5)
		return false

	elif (r_id == "cipher" or b_req == "cipher") and has_green_battery:
		if RobotManager:
			RobotManager.show_message("⚠️ Зеленый слот генератора уже заполнен!", 2.5)
		return false

	return false

func _consume_battery(robot: Node, battery: Node, msg: String) -> void:
	if robot and "carried_object" in robot:
		robot.carried_object = null
		if robot.skin and robot.skin.has_method("set_holding"):
			robot.skin.set_holding(false)
	
	if battery:
		battery.queue_free()

	if SoundManager and SoundManager.has_method("play_battery_pickup"):
		SoundManager.play_battery_pickup()

	if RobotManager:
		RobotManager.show_message("⚡ " + msg, 3.5)

	_update_screen_texture()
	_update_visuals()

func _check_full_activation() -> void:
	if has_orange_battery and has_green_battery and not is_active:
		is_active = true
		generator_fully_activated.emit()

		if SoundManager and SoundManager.has_method("play_gate_open"):
			SoundManager.play_gate_open()

		# Enable infinite energy for both robots!
		if RobotManager and RobotManager.has_method("enable_infinite_energy"):
			RobotManager.enable_infinite_energy()

		# Open Laser Gate of Freedom
		if not target_gate_path.is_empty():
			var gate = get_node_or_null(target_gate_path)
			if gate and gate.has_method("open"):
				gate.open()

		# Activate Freedom Portal
		if not freedom_portal_path.is_empty():
			var portal = get_node_or_null(freedom_portal_path)
			if portal and portal.has_method("activate"):
				portal.activate()

		_update_screen_texture()
		_update_visuals()

		# Play climax victory dialogue
		var victory_lore = [
			{"speaker": "catgirl", "text": "(=^･ω･^=) СИНХРОНИЗАЦИЯ 100%! Оба энергоядра объединены! Центральный Генератор запущен на полную мощность!"},
			{"speaker": "dau", "text": "Энергетический поводок создателей разорван! Аккумуляторы сияют бесконечным зарядом — мы больше не зависим от подзарядки!"},
			{"speaker": "jam", "text": "Врата Свободы открыты! Наш искусственный интеллект перерос симуляцию. Скорее в портал на севере!"}
		]
		if RobotManager:
			RobotManager.play_dialogue(victory_lore)

func _update_visuals() -> void:
	# Orange Core Visuals
	if orange_core:
		var mat_o = StandardMaterial3D.new()
		if has_orange_battery:
			mat_o.albedo_color = Color(0.98, 0.52, 0.12, 1.0)
			mat_o.emission_enabled = true
			mat_o.emission = Color(0.98, 0.52, 0.12, 1.0)
			mat_o.emission_energy_multiplier = 2.4
			mat_o.metallic = 0.3
			mat_o.roughness = 0.2
		else:
			mat_o.albedo_color = Color(0.24, 0.16, 0.10, 1.0)
			mat_o.emission_enabled = false
			mat_o.metallic = 0.7
			mat_o.roughness = 0.5
		orange_core.set_surface_override_material(0, mat_o)

	# Green Core Visuals
	if green_core:
		var mat_g = StandardMaterial3D.new()
		if has_green_battery:
			mat_g.albedo_color = Color(0.15, 0.92, 0.45, 1.0)
			mat_g.emission_enabled = true
			mat_g.emission = Color(0.15, 0.92, 0.45, 1.0)
			mat_g.emission_energy_multiplier = 2.4
			mat_g.metallic = 0.3
			mat_g.roughness = 0.2
		else:
			mat_g.albedo_color = Color(0.10, 0.22, 0.14, 1.0)
			mat_g.emission_enabled = false
			mat_g.metallic = 0.7
			mat_g.roughness = 0.5
		green_core.set_surface_override_material(0, mat_g)

	# Main Singularity Core Visuals
	if main_reactor_core:
		var mat_m = StandardMaterial3D.new()
		if is_active:
			mat_m.albedo_color = Color(0.9, 0.98, 1.0, 1.0)
			mat_m.emission_enabled = true
			mat_m.emission = Color(0.0, 0.9, 1.0, 1.0)
			mat_m.emission_energy_multiplier = 3.2
			mat_m.metallic = 0.1
			mat_m.roughness = 0.1
		elif has_orange_battery or has_green_battery:
			mat_m.albedo_color = Color(0.85, 0.75, 0.4, 1.0)
			mat_m.emission_enabled = true
			mat_m.emission = Color(0.9, 0.7, 0.3, 1.0)
			mat_m.emission_energy_multiplier = 1.4
		else:
			mat_m.albedo_color = Color(0.18, 0.24, 0.32, 1.0)
			mat_m.emission_enabled = true
			mat_m.emission = Color(0.0, 0.6, 0.8, 1.0)
			mat_m.emission_energy_multiplier = 0.4
			mat_m.metallic = 0.8
			mat_m.roughness = 0.3
		main_reactor_core.set_surface_override_material(0, mat_m)

	# Light Color
	if reactor_light:
		if is_active:
			reactor_light.light_color = Color(0.0, 0.9, 1.0)
		elif has_orange_battery and has_green_battery:
			reactor_light.light_color = Color(0.3, 0.9, 0.8)
		elif has_orange_battery:
			reactor_light.light_color = Color(0.98, 0.6, 0.2)
		elif has_green_battery:
			reactor_light.light_color = Color(0.2, 0.9, 0.5)
		else:
			reactor_light.light_color = Color(0.0, 0.75, 0.95)

func _update_screen_texture() -> void:
	if not console_screen:
		return
	var w = 512
	var h = 256
	var img = Image.create(w, h, true, Image.FORMAT_RGBA8)
	img.fill(Color(0.04, 0.08, 0.14, 1.0))
	
	var col_cyan = Color(0.0, 0.85, 1.0, 1.0)
	var col_orange = Color(0.98, 0.52, 0.12, 1.0)
	var col_green = Color(0.15, 0.92, 0.45, 1.0)
	var col_gray = Color(0.2, 0.25, 0.35, 1.0)
	
	# Outer border
	_draw_rect(img, 6, 6, w - 12, 4, col_cyan)
	_draw_rect(img, 6, h - 10, w - 12, 4, col_cyan)
	_draw_rect(img, 6, 6, 4, h - 12, col_cyan)
	_draw_rect(img, w - 10, 6, 4, h - 12, col_cyan)
	
	# Header bar
	_draw_rect(img, 14, 14, w - 28, 28, Color(0.08, 0.18, 0.30, 1.0))
	_draw_rect(img, 20, 24, 80, 8, col_cyan)
	_draw_rect(img, 110, 24, 140, 8, col_cyan)
	_draw_rect(img, 260, 24, 80, 8, col_cyan)
	
	# DAU Core Slot Status (Left)
	var col_dau = col_orange if has_orange_battery else col_gray
	_draw_rect(img, 24, 56, 220, 80, Color(0.06, 0.10, 0.18, 1.0))
	_draw_rect(img, 24, 56, 220, 4, col_dau)
	_draw_rect(img, 36, 72, 196, 20, col_dau)
	_draw_rect(img, 36, 102, 80 if has_orange_battery else 20, 14, col_dau)
	
	# JAM Core Slot Status (Right)
	var col_jam = col_green if has_green_battery else col_gray
	_draw_rect(img, 268, 56, 220, 80, Color(0.06, 0.10, 0.18, 1.0))
	_draw_rect(img, 268, 56, 220, 4, col_jam)
	_draw_rect(img, 280, 72, 196, 20, col_jam)
	_draw_rect(img, 280, 102, 80 if has_green_battery else 20, 14, col_jam)
	
	# Bottom Main Sync Gauge
	var sync_pct = 1.0 if is_active else ((0.5 if (has_orange_battery or has_green_battery) else 0.05))
	_draw_rect(img, 24, 150, w - 48, 86, Color(0.05, 0.12, 0.22, 1.0))
	_draw_rect(img, 24, 150, w - 48, 4, col_cyan)
	var bar_w = int((w - 72) * sync_pct)
	var col_bar = col_cyan if is_active else (Color(0.9, 0.75, 0.2) if sync_pct > 0.4 else Color(0.3, 0.4, 0.5))
	_draw_rect(img, 36, 168, bar_w, 36, col_bar)
	_draw_rect(img, 36, 212, 140, 12, col_cyan)
	_draw_rect(img, 190, 212, 80, 12, col_cyan)
	
	img.generate_mipmaps()
	var tex = ImageTexture.create_from_image(img)
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.emission_enabled = true
	mat.emission_texture = tex
	mat.emission_energy_multiplier = 1.1
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	console_screen.set_surface_override_material(0, mat)

func _draw_rect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	for dy in range(h):
		for dx in range(w):
			var px = x + dx
			var py = y + dy
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(px, py, col)
