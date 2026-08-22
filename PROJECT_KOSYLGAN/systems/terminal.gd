class_name Terminal
extends Area3D

@export var terminal_id: String = "terminal_1"
@export var wires_count: int = 3
@export var solution_wires: Array[int] = [0]
@export var require_exact_order: bool = false
@export var clue_id: String = "guide_1"
@export var target_gate_path: NodePath

@onready var front_hatch: MeshInstance3D = $FrontHatch
@onready var screen_mesh: MeshInstance3D = $AngledTop/ScreenMesh
@onready var omni_light: OmniLight3D = $OmniLight3D

var is_hacked: bool = false
var minigame_scene = preload("res://minigames/wire_cutting.tscn")
var time_passed: float = 0.0

func _ready() -> void:
	add_to_group("terminal")
	add_to_group("interactable")

	# Apply Front Hatch Texture
	if front_hatch:
		var path_f = "res://assets/textures/tex_terminal_front.png"
		var global_f = ProjectSettings.globalize_path(path_f)
		var img_f = Image.load_from_file(global_f)
		if img_f:
			var tex_f = ImageTexture.create_from_image(img_f)
			var mat_f = StandardMaterial3D.new()
			mat_f.albedo_texture = tex_f
			mat_f.metallic = 0.55
			mat_f.roughness = 0.4
			mat_f.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			front_hatch.set_surface_override_material(0, mat_f)

	# Apply Screen Deck Texture (Locked)
	_update_screen_texture(false)

func _process(delta: float) -> void:
	time_passed += delta
	if omni_light:
		if is_hacked:
			omni_light.light_energy = 0.8 + 0.15 * sin(time_passed * 2.0)
		else:
			# Slow pulsing amber/red security beacon
			omni_light.light_energy = 0.6 + 0.3 * sin(time_passed * 3.5)

func _update_screen_texture(solved: bool) -> void:
	if screen_mesh:
		var path_s = "res://assets/textures/tex_terminal_screen_solved.png" if solved else "res://assets/textures/tex_terminal_screen.png"
		var global_s = ProjectSettings.globalize_path(path_s)
		var img_s = Image.load_from_file(global_s)
		if img_s:
			var tex_s = ImageTexture.create_from_image(img_s)
			var mat_s = StandardMaterial3D.new()
			mat_s.albedo_texture = tex_s
			mat_s.emission_enabled = true
			mat_s.emission_texture = tex_s
			mat_s.emission_energy_multiplier = 0.9 if solved else 0.75
			mat_s.metallic = 0.45
			mat_s.roughness = 0.35
			mat_s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			screen_mesh.set_surface_override_material(0, mat_s)

func start_hack(robot: Node) -> void:
	if is_hacked:
		if RobotManager:
			RobotManager.show_message("✅ Терминал уже взломан! Лазеры отключены.")
		return

	var minigame = minigame_scene.instantiate()
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
		
		if gate and gate.has_method("open"):
			gate.open()

		if RobotManager:
			RobotManager.show_message("🔓 Взлом успешен! Защитные гермодвери открыты.")
