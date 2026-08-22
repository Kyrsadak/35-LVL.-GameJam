class_name GuideTablet
extends Area3D

@export var guide_id: String = "guide_1"
@export_multiline var clue_text: String = "СХЕМА: ПЕРЕРЕЖЬТЕ КРАСНЫЙ ПРОВОД"

@onready var hologram: Node3D = $Hologram
@onready var tablet_screen: MeshInstance3D = $Hologram/TabletScreen
@onready var holo_beam: MeshInstance3D = $Hologram/HoloBeam
@onready var light: OmniLight3D = $OmniLight3D

var is_read: bool = false
var time_passed: float = 0.0

func _ready() -> void:
	add_to_group("guide_tablet")
	add_to_group("interactable")

	# Apply custom sci-fi schematic texture to the tablet screen
	if tablet_screen:
		var path = "res://assets/textures/tex_guide_tablet.png"
		var global_p = ProjectSettings.globalize_path(path)
		var img = Image.load_from_file(global_p)
		if img:
			var tex = ImageTexture.create_from_image(img)
			var mat = StandardMaterial3D.new()
			mat.albedo_texture = tex
			mat.emission_enabled = true
			mat.emission_texture = tex
			mat.emission_energy_multiplier = 1.0
			mat.metallic = 0.4
			mat.roughness = 0.3
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			tablet_screen.set_surface_override_material(0, mat)

func _process(delta: float) -> void:
	time_passed += delta
	if hologram:
		# Smooth levitation bobbing
		hologram.position.y = 1.25 + sin(time_passed * 2.5) * 0.05
		# Slow holographic rotation
		hologram.rotation.y += delta * 0.8

	# Hologram pulse
	if light:
		light.light_energy = 0.8 + 0.3 * sin(time_passed * 3.0)

func read_guide() -> Dictionary:
	is_read = true
	if light:
		light.light_color = Color(0.2, 1.0, 0.4) # Turn green when scanned
	return {
		"id": guide_id,
		"text": clue_text
	}
