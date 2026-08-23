class_name Terminal
extends Area3D

@export var terminal_id: String = "terminal_1"
@export var minigame_type: String = "wires" # "wires", "switches", or "reaction_numpad"
@export var switch_sequence: Array[int] = [3, 1, 4, 2, 5]
@export var wires_count: int = 3
@export var solution_wires: Array[int] = [0]
@export var require_exact_order: bool = false
@export var clue_id: String = "guide_1"
@export var target_gate_path: NodePath
@export var requires_power: bool = false
@export var is_powered: bool = true

@onready var front_hatch: MeshInstance3D = $FrontHatch
@onready var screen_mesh: MeshInstance3D = $AngledTop/ScreenMesh
@onready var omni_light: OmniLight3D = $OmniLight3D

var is_hacked: bool = false
var minigame_wires_scene = preload("res://minigames/wire_cutting.tscn")
var minigame_switches_scene = preload("res://minigames/switch_puzzle.tscn")
var minigame_numpad_scene = preload("res://minigames/reaction_numpad.tscn")
var time_passed: float = 0.0

func _ready() -> void:
	add_to_group("terminal")
	add_to_group("interactable")

	# Apply Front Hatch Texture
	if front_hatch:
		var path_f = "res://assets/textures/tex_terminal_front.png"
		# globalize_path replaced
		var global_f_loaded = load(path_f)
		var img_f = global_f_loaded if (global_f_loaded != null) else load(global_f_loaded)
		if img_f:
			var tex_f = (img_f if img_f is Texture2D else (ImageTexture.create_from_image(img_f) if img_f != null else null))
			var mat_f = StandardMaterial3D.new()
			mat_f.albedo_texture = tex_f
			mat_f.metallic = 0.55
			mat_f.roughness = 0.4
			mat_f.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			front_hatch.set_surface_override_material(0, mat_f)

	# Apply Screen Deck Texture (Locked / Unpowered)
	_update_screen_texture(false)

func _process(delta: float) -> void:
	time_passed += delta
	if omni_light:
		if requires_power and not is_powered:
			# Unpowered dim flicker
			omni_light.light_energy = 0.15 + 0.05 * sin(time_passed * 1.5)
			omni_light.light_color = Color(0.4, 0.4, 0.4)
		elif is_hacked:
			omni_light.light_energy = 0.8 + 0.15 * sin(time_passed * 2.0)
			omni_light.light_color = Color(0.2, 1.0, 0.4)
		else:
			# Slow pulsing amber/red security beacon
			omni_light.light_energy = 0.6 + 0.3 * sin(time_passed * 3.5)
			omni_light.light_color = Color(1.0, 0.65, 0.15)

func set_powered(state: bool) -> void:
	if is_powered == state:
		return
	is_powered = state
	if is_powered:
		if SoundManager:
			SoundManager.play_gate_open()
		if RobotManager:
			RobotManager.show_message("⚡ ТЕРМИНАЛ ЗАПИТАН! Система взлома готова к работе.", 3.0)
	_update_screen_texture(is_hacked)

func _update_screen_texture(solved: bool) -> void:
	if screen_mesh:
		var path_s = "res://assets/textures/tex_terminal_screen_solved.png" if solved else "res://assets/textures/tex_terminal_screen.png"
		# globalize_path replaced
		var global_s_loaded = load(path_s)
		var img_s = global_s_loaded if (global_s_loaded != null) else load(global_s_loaded)
		if img_s:
			var tex_s = (img_s if img_s is Texture2D else (ImageTexture.create_from_image(img_s) if img_s != null else null))
			var mat_s = StandardMaterial3D.new()
			mat_s.albedo_texture = tex_s
			mat_s.emission_enabled = true
			mat_s.emission_texture = tex_s
			if requires_power and not is_powered:
				mat_s.albedo_color = Color(0.3, 0.3, 0.3)
				mat_s.emission_energy_multiplier = 0.05
			else:
				mat_s.albedo_color = Color.WHITE
				mat_s.emission_energy_multiplier = 0.9 if solved else 0.75
			mat_s.metallic = 0.45
			mat_s.roughness = 0.35
			mat_s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			screen_mesh.set_surface_override_material(0, mat_s)

func start_hack(robot: Node) -> void:
	if requires_power and not is_powered:
		if RobotManager:
			RobotManager.show_message("⚠️ ТЕРМИНАЛ ОБЕСТОЧЕН! Поставьте тяжелый ящик на нажимную энерго-плиту, чтобы подать питание.", 4.0)
		return

	if is_hacked:
		if RobotManager:
			RobotManager.show_message("✅ Терминал уже взломан! Гермодвери открыты.")
		return

	# Strictly enforce cooperative workflow: DAU MUST read the tablet clue first!
	if not clue_id.is_empty() and RobotManager and not RobotManager.discovered_clues.has(clue_id):
		if RobotManager:
			RobotManager.show_message("Терминал заблокирован шифром! Сначала DAU должен найти и просканировать планшет-инструкцию!", 4.5)
		if SoundManager and SoundManager.has_method("play_spark_error"):
			SoundManager.play_spark_error()
		return

	var minigame = null
	if minigame_type == "switches":
		minigame = minigame_switches_scene.instantiate()
		minigame.setup(self, switch_sequence, clue_id)
	elif minigame_type == "reaction_numpad" or minigame_type == "numpad":
		minigame = minigame_numpad_scene.instantiate()
		minigame.setup(self, clue_id, 2.00)
	else:
		minigame = minigame_wires_scene.instantiate()
		minigame.setup(self, wires_count, solution_wires, clue_id, require_exact_order)

	get_tree().root.add_child(minigame)
	minigame.completed.connect(_on_hack_completed)

func _on_hack_completed(success: bool) -> void:
	if success:
		is_hacked = true
		if omni_light:
			omni_light.light_color = Color(0.2, 1.0, 0.4)
			omni_light.light_energy = 1.0
		
		_update_screen_texture(true)

		var gate = null
		if not target_gate_path.is_empty():
			gate = get_node_or_null(target_gate_path)
		if not gate:
			gate = get_tree().get_first_node_in_group("laser_gate")
		if not gate:
			gate = get_parent().find_child("LaserGate", true, false)
		
		if gate and gate.has_method("open"):
			gate.open()
		elif gate and "is_active" in gate:
			gate.is_active = false
			if gate.has_method("_apply_door_state"):
				gate._apply_door_state(false, false)

		if RobotManager:
			RobotManager.show_message("🔓 Взлом успешен! Защитные гермодвери открыты.")
