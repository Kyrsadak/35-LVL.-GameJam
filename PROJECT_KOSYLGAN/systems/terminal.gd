class_name Terminal
extends Area3D

@export var terminal_id: String = "terminal_1"
@export var wires_count: int = 3
@export var solution_wires: Array[int] = [0]
@export var require_exact_order: bool = false
@export var clue_id: String = "guide_1"
@export var target_gate_path: NodePath

var screen_mesh: MeshInstance3D = null
var omni_light: OmniLight3D = null

var is_hacked: bool = false
var minigame_scene = preload("res://minigames/wire_cutting.tscn")

func _ready() -> void:
	screen_mesh = find_child("ScreenMesh", true, false) as MeshInstance3D
	omni_light = find_child("OmniLight3D", true, false) as OmniLight3D
	add_to_group("terminal")
	add_to_group("interactable")

func start_hack(robot: Node) -> void:
	if is_hacked:
		if RobotManager:
			RobotManager.show_message("✅ Терминал уже взломан! Лазеры отключены.")
		return

	var minigame = minigame_scene.instantiate()
	get_tree().root.add_child(minigame)
	minigame.setup(self, wires_count, solution_wires, clue_id, require_exact_order)
	minigame.completed.connect(_on_hack_completed)

func _on_hack_completed(success: bool) -> void:
	if success:
		is_hacked = true
		if omni_light:
			omni_light.light_color = Color(0.1, 1.0, 0.3)
		if screen_mesh:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.1, 1.0, 0.3)
			mat.emission_enabled = true
			mat.emission = Color(0.1, 1.0, 0.3)
			screen_mesh.material_override = mat

		if not target_gate_path.is_empty():
			var gate = get_node_or_null(target_gate_path)
			if gate and gate.has_method("open"):
				gate.open()

		if RobotManager:
			RobotManager.show_message("🔓 Взлом успешен! Защитный барьер отключен.")
