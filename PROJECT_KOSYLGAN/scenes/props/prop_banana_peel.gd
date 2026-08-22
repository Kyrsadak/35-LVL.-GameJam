class_name PropBananaPeel
extends Node3D

func _ready() -> void:
	var path = "res://assets/textures/tex_banana_peel.png"
	var global_p = ProjectSettings.globalize_path(path)
	var img = Image.load_from_file(global_p)
	if img:
		var tex = ImageTexture.create_from_image(img)
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.metallic = 0.05
		mat.roughness = 0.6
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		for child in get_children():
			if child is MeshInstance3D and child.name.begins_with("Peel"):
				child.set_surface_override_material(0, mat)
