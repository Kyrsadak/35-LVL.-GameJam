class_name ChargingStation
extends Area3D

@onready var light: OmniLight3D = $OmniLight3D
@onready var platform_mesh: MeshInstance3D = $PlatformMesh

var robots_on_station: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if platform_mesh:
		var path = "res://assets/textures/tex_charging_station.png"
		var global_p = ProjectSettings.globalize_path(path)
		var img = Image.load_from_file(global_p)
		if img:
			var tex = ImageTexture.create_from_image(img)
			var mat = StandardMaterial3D.new()
			mat.albedo_texture = tex
			mat.emission_enabled = true
			mat.emission_texture = tex
			mat.emission_energy_multiplier = 0.5
			mat.metallic = 0.5
			mat.roughness = 0.4
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			platform_mesh.set_surface_override_material(0, mat)

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
