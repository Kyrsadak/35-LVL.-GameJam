class_name GuideTablet
extends Area3D

@export var guide_id: String = "guide_1"
@export_multiline var clue_text: String = "СХЕМА: ПЕРЕРЕЖЬТЕ КРАСНЫЙ ПРОВОД"

var hologram: Node3D = null
var is_read: bool = false
var time_passed: float = 0.0

func _ready() -> void:
	hologram = find_child("Hologram", true, false) as Node3D
	if not hologram:
		hologram = find_child("MeshHolder", true, false) as Node3D
	add_to_group("guide_tablet")
	add_to_group("interactable")

	var pad_mesh = find_child("TabletPad", true, false) as MeshInstance3D
	if not pad_mesh and hologram:
		pad_mesh = hologram.find_child("MeshInstance3D", true, false) as MeshInstance3D
	if pad_mesh:
		var path = "res://assets/textures/tex_guide_tablet.png"
		var global_p = ProjectSettings.globalize_path(path)
		var img = Image.load_from_file(global_p)
		if img:
			var tex = ImageTexture.create_from_image(img)
			var mat = StandardMaterial3D.new()
			mat.albedo_texture = tex
			mat.emission_enabled = true
			mat.emission_texture = tex
			mat.emission_energy_multiplier = 0.8
			mat.metallic = 0.6
			mat.roughness = 0.3
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			pad_mesh.set_surface_override_material(0, mat)

func _process(delta: float) -> void:
	time_passed += delta
	if hologram:
		hologram.position.y = 1.35 + sin(time_passed * 2.5) * 0.08
		hologram.rotation.y += delta * 1.5

func read_guide() -> Dictionary:
	is_read = true
	return {
		"id": guide_id,
		"text": clue_text
	}
