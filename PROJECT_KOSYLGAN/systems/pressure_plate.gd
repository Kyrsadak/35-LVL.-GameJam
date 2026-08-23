class_name PressurePlate
extends Area3D

## High-fidelity 3D Heavy-Duty Industrial Pressure Plate
## Features authentic sci-fi mechanical aesthetics with hydraulic clamps,
## segmented bezel with status LEDs, and a responsive two-state plunger.

signal activated()
signal deactivated()

@export var target_node_path: NodePath
@export var is_pressed: bool = false

@onready var button_pad_pivot: Node3D = $ButtonPadPivot
@onready var button_disc: MeshInstance3D = $ButtonPadPivot/ButtonDisc
@onready var button_center_cap: MeshInstance3D = $ButtonPadPivot/ButtonCenterCap
@onready var status_light: OmniLight3D = $StatusLight
@onready var led_strips: Node3D = $BezelRing/LEDStrips

var overlapping_count: int = 0
var tween: Tween

# Materials
var mat_pad_inactive: StandardMaterial3D
var mat_pad_active: StandardMaterial3D
var mat_led_inactive: StandardMaterial3D
var mat_led_active: StandardMaterial3D

func _ready() -> void:
	add_to_group("pressure_plate")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_init_materials()
	_update_visuals(false, true)

func _init_materials() -> void:
	# 1. Inactive Pad (Industrial Crimson Red with subtle metallic grit)
	mat_pad_inactive = StandardMaterial3D.new()
	mat_pad_inactive.albedo_color = Color(0.85, 0.16, 0.16)
	mat_pad_inactive.metallic = 0.45
	mat_pad_inactive.roughness = 0.35
	mat_pad_inactive.emission_enabled = false

	# 2. Active Pad (Energized Emerald Green with bright glow)
	mat_pad_active = StandardMaterial3D.new()
	mat_pad_active.albedo_color = Color(0.12, 0.95, 0.52)
	mat_pad_active.metallic = 0.3
	mat_pad_active.roughness = 0.2
	mat_pad_active.emission_enabled = true
	mat_pad_active.emission = Color(0.12, 0.95, 0.52)
	mat_pad_active.emission_energy_multiplier = 1.8

	# 3. LED Indicator Strips (Standby soft cyan)
	mat_led_inactive = StandardMaterial3D.new()
	mat_led_inactive.albedo_color = Color(0.2, 0.65, 0.8)
	mat_led_inactive.emission_enabled = true
	mat_led_inactive.emission = Color(0.2, 0.65, 0.8)
	mat_led_inactive.emission_energy_multiplier = 0.6

	# 4. LED Indicator Strips (Active bright glowing green/cyan)
	mat_led_active = StandardMaterial3D.new()
	mat_led_active.albedo_color = Color(0.2, 0.95, 0.6)
	mat_led_active.emission_enabled = true
	mat_led_active.emission = Color(0.2, 0.95, 0.6)
	mat_led_active.emission_energy_multiplier = 2.8

func _on_body_entered(body: Node3D) -> void:
	overlapping_count += 1
	if not is_pressed and overlapping_count > 0:
		_press()

func _on_body_exited(body: Node3D) -> void:
	overlapping_count = max(0, overlapping_count - 1)
	if is_pressed and overlapping_count == 0:
		_release()

func _press() -> void:
	is_pressed = true
	_update_visuals(true, false)
	
	if SoundManager and SoundManager.has_method("play_gate_open"):
		SoundManager.play_gate_open()
		
	activated.emit()
	
	if not target_node_path.is_empty():
		var target = get_node_or_null(target_node_path)
		if target:
			if target.has_method("set_powered"):
				target.set_powered(true)
			elif target.has_method("open"):
				target.open()

func _release() -> void:
	is_pressed = false
	_update_visuals(false, false)
	
	deactivated.emit()
	
	if not target_node_path.is_empty():
		var target = get_node_or_null(target_node_path)
		if target:
			if target.has_method("set_powered"):
				target.set_powered(false)
			elif target.has_method("close"):
				target.close()

func _update_visuals(pressed: bool, instant: bool = false) -> void:
	var target_y = 0.025 if pressed else 0.075
	var target_pad_mat = mat_pad_active if pressed else mat_pad_inactive
	var target_led_mat = mat_led_active if pressed else mat_led_inactive
	
	# Plunger Mesh Materials
	if button_disc:
		button_disc.set_surface_override_material(0, target_pad_mat)
	if button_center_cap:
		button_center_cap.set_surface_override_material(0, target_pad_mat)
		
	# LED Strips Material
	if led_strips:
		for led in led_strips.get_children():
			if led is MeshInstance3D:
				led.set_surface_override_material(0, target_led_mat)
				
	# OmniLight Status
	if status_light:
		status_light.light_color = Color(0.15, 0.95, 0.55) if pressed else Color(0.9, 0.25, 0.2)
		status_light.light_energy = 1.4 if pressed else 0.4
		
	# Smooth Mechanical Plunger Motion
	if button_pad_pivot:
		if instant:
			button_pad_pivot.position.y = target_y
		else:
			if tween and tween.is_valid():
				tween.kill()
			tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(button_pad_pivot, "position:y", target_y, 0.12)
