class_name DualGenerator
extends Area3D

signal battery_inserted(robot_id: String)
signal generator_fully_activated()

@export var target_gate_path: NodePath
@export var freedom_portal_path: NodePath

@onready var orange_core: MeshInstance3D = $Visuals/OrangeCore
@onready var green_core: MeshInstance3D = $Visuals/GreenCore
@onready var main_reactor_core: MeshInstance3D = $Visuals/MainReactorCore
@onready var reactor_light: OmniLight3D = $OmniLight3D

var has_orange_battery: bool = false
var has_green_battery: bool = false
var is_active: bool = false
var time_passed: float = 0.0

func _ready() -> void:
	add_to_group("dual_generator")
	add_to_group("interactable")
	_update_visuals()

func _process(delta: float) -> void:
	time_passed += delta
	if is_active:
		if reactor_light:
			reactor_light.light_energy = 3.5 + 0.8 * sin(time_passed * 6.0)
		if main_reactor_core:
			main_reactor_core.rotation.y += delta * 3.0
	elif has_orange_battery or has_green_battery:
		if reactor_light:
			reactor_light.light_energy = 1.8 + 0.4 * sin(time_passed * 3.0)

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
	if orange_core:
		var mat_o = StandardMaterial3D.new()
		mat_o.albedo_color = Color(0.9, 0.45, 0.15) if has_orange_battery else Color(0.25, 0.18, 0.12)
		mat_o.emission_enabled = has_orange_battery
		mat_o.emission = Color(0.9, 0.45, 0.15)
		mat_o.emission_energy_multiplier = 1.2 if has_orange_battery else 0.0
		orange_core.set_surface_override_material(0, mat_o)

	if green_core:
		var mat_g = StandardMaterial3D.new()
		mat_g.albedo_color = Color(0.3, 0.85, 0.45) if has_green_battery else Color(0.12, 0.22, 0.15)
		mat_g.emission_enabled = has_green_battery
		mat_g.emission = Color(0.3, 0.85, 0.45)
		mat_g.emission_energy_multiplier = 1.2 if has_green_battery else 0.0
		green_core.set_surface_override_material(0, mat_g)

	if main_reactor_core:
		var mat_m = StandardMaterial3D.new()
		if is_active:
			mat_m.albedo_color = Color(0.4, 0.85, 0.95)
			mat_m.emission_enabled = true
			mat_m.emission = Color(0.4, 0.85, 0.95)
			mat_m.emission_energy_multiplier = 1.5
		else:
			mat_m.albedo_color = Color(0.25, 0.28, 0.32)
			mat_m.emission_enabled = false
		main_reactor_core.set_surface_override_material(0, mat_m)

	if reactor_light:
		if is_active:
			reactor_light.light_color = Color(0.4, 0.85, 0.95)
			reactor_light.light_energy = 1.8
		elif has_orange_battery or has_green_battery:
			reactor_light.light_color = Color(0.95, 0.75, 0.35)
			reactor_light.light_energy = 1.2
		else:
			reactor_light.light_color = Color(0.4, 0.4, 0.4)
			reactor_light.light_energy = 0.3
