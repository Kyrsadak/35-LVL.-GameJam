class_name SecurityCamera
extends Node3D

@export var scan_speed: float = 1.0
@export var scan_angle_deg: float = 35.0
@export var is_blinking: bool = true

@onready var swivel: Node3D = $SwivelPivot
@onready var lens_mesh: MeshInstance3D = $SwivelPivot/Housing/RedLens
@onready var spot_light: SpotLight3D = $SwivelPivot/Housing/SpotLight3D

var _time: float = 0.0
var _base_yaw: float = 0.0

func _ready() -> void:
	if swivel:
		_base_yaw = swivel.rotation.y

func _process(delta: float) -> void:
	_time += delta * scan_speed
	
	# Smooth surveillance scan oscillation
	if swivel:
		swivel.rotation.y = _base_yaw + sin(_time) * deg_to_rad(scan_angle_deg)
	
	# Gentle LED pulsing
	if is_blinking and lens_mesh:
		var pulse = 0.6 + 0.4 * sin(_time * 4.0)
		var mat = lens_mesh.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat.emission_energy_multiplier = pulse * 1.5
		if spot_light:
			spot_light.light_energy = pulse * 0.4
