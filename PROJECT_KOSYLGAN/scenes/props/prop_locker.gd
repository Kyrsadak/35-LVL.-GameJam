class_name PropLocker
extends StaticBody3D

@onready var front_face: MeshInstance3D = $FrontFace

func _ready() -> void:
	var path = "res://assets/textures/tex_locker.png"
	var global_p = ProjectSettings.globalize_path(path)
	var img = Image.load_from_file(global_p)
	if img and front_face:
		var tex = ImageTexture.create_from_image(img)
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.metallic = 0.4
		mat.roughness = 0.5
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		front_face.set_surface_override_material(0, mat)
