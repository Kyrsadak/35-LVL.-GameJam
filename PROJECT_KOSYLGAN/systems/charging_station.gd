class_name ChargingStation
extends Area3D

@onready var light: OmniLight3D = $OmniLight3D
@onready var platform_mesh: MeshInstance3D = $PlatformMesh

var robots_on_station: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if "is_on_charging_station" in body:
		if not robots_on_station.has(body):
			robots_on_station.append(body)
			body.is_on_charging_station = true
			_update_visuals()

func _on_body_exited(body: Node3D) -> void:
	if "is_on_charging_station" in body:
		if robots_on_station.has(body):
			robots_on_station.erase(body)
			body.is_on_charging_station = false
			_update_visuals()

func _update_visuals() -> void:
	if light:
		if robots_on_station.size() > 0:
			light.light_energy = 2.5
			light.light_color = Color(0.2, 1.0, 0.4) # Green when charging
		else:
			light.light_energy = 1.2
			light.light_color = Color(0.1, 0.8, 1.0) # Cyan standby
