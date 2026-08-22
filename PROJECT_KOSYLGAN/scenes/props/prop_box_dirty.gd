class_name PropBoxDirty
extends StaticBody3D

func _ready() -> void:
	var path = "res://assets/textures/tex_box_dirty.png"
	var global_p = ProjectSettings.globalize_path(path)
	var img = Image.load_from_file(global_p)
	if img:
		img.generate_mipmaps()
		var tex = ImageTexture.create_from_image(img)
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.metallic = 0.02
		mat.roughness = 0.88
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		for child in find_children("*", "MeshInstance3D", true, false):
			var m = child as MeshInstance3D
			if m and not m.name.begins_with("Filled"):
				m.set_surface_override_material(0, mat)
