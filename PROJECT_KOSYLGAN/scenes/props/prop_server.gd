class_name PropServer
extends StaticBody3D

@onready var front_face: MeshInstance3D = $FrontFace

func _ready() -> void:
	var path = "res://assets/textures/tex_server_rack.png"
	var global_p = ProjectSettings.globalize_path(path)
	var img = Image.load_from_file(global_p)
	if img and front_face:
		var tex = ImageTexture.create_from_image(img)
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.emission_enabled = true
		mat.emission_texture = tex
		mat.emission_energy_multiplier = 0.4
		mat.metallic = 0.6
		mat.roughness = 0.4
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		front_face.set_surface_override_material(0, mat)
