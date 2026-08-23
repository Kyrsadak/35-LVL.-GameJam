class_name FreedomPortal
extends Area3D

@export var is_active: bool = false

@onready var light: OmniLight3D = $OmniLight3D
@onready var portal_mesh: MeshInstance3D = $PortalMesh

var triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_visuals()

func activate() -> void:
	is_active = true
	_update_visuals()

func _update_visuals() -> void:
	if portal_mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 1.0, 1.0) if is_active else Color(0.1, 0.1, 0.15)
		mat.emission_enabled = is_active
		mat.emission = Color(1.0, 1.0, 1.0)
		mat.emission_energy_multiplier = 5.0 if is_active else 0.0
		portal_mesh.set_surface_override_material(0, mat)
	if light:
		light.light_energy = 4.0 if is_active else 0.2

func _on_body_entered(body: Node3D) -> void:
	if not is_active or triggered:
		return

	if body is RobotBase or body.is_in_group("robot"):
		triggered = true
		_trigger_captcha_ending()

func _trigger_captcha_ending() -> void:
	if SoundManager and SoundManager.has_method("play_level_start"):
		SoundManager.play_level_start()
	
	var ending_scene = load("res://ui/captcha_ending.tscn")
	if ending_scene:
		var ending = ending_scene.instantiate()
		get_tree().root.add_child(ending)
