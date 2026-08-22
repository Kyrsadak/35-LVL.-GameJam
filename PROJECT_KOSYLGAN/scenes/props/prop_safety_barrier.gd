class_name PropSafetyBarrier
extends StaticBody3D

@onready var flasher_left: MeshInstance3D = find_child("FlasherLeft", true, false) as MeshInstance3D
@onready var flasher_right: MeshInstance3D = find_child("FlasherRight", true, false) as MeshInstance3D

var flasher_mat: StandardMaterial3D
var anim_time: float = 0.0

func _ready() -> void:
	# 1. Main Barrier Texture
	var path = "res://assets/textures/tex_safety_barrier.png"
	var global_p = ProjectSettings.globalize_path(path)
	var img = Image.load_from_file(global_p)
	if img:
		img.generate_mipmaps()
		var tex = ImageTexture.create_from_image(img)
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.metallic = 0.1
		mat.roughness = 0.6
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		
		for child in find_children("*", "MeshInstance3D", true, false):
			var m = child as MeshInstance3D
			if m and not m.name.begins_with("Flasher"):
				m.set_surface_override_material(0, mat)

	# 2. Amber Flasher Beacon Material
	flasher_mat = StandardMaterial3D.new()
	flasher_mat.albedo_color = Color(1.0, 0.75, 0.15)
	flasher_mat.emission_enabled = true
	flasher_mat.emission = Color(1.0, 0.70, 0.10)
	flasher_mat.emission_energy_multiplier = 1.8
	flasher_mat.roughness = 0.2
	
	if flasher_left: flasher_left.set_surface_override_material(0, flasher_mat)
	if flasher_right: flasher_right.set_surface_override_material(0, flasher_mat)

func _process(delta: float) -> void:
	anim_time += delta * 5.0
	if flasher_mat:
		var flash = 0.8 + 1.2 * max(0.0, sin(anim_time))
		flasher_mat.emission_energy_multiplier = flash
