class_name PropTrashBin
extends StaticBody3D

func _ready() -> void:
	var path = "res://assets/textures/tex_trash_bin.png"
	var global_p = ProjectSettings.globalize_path(path)
	var img = Image.load_from_file(global_p)
	if img:
		img.generate_mipmaps()
		var tex = ImageTexture.create_from_image(img)
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.metallic = 0.65
		mat.roughness = 0.35
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		
		for child in find_children("*", "MeshInstance3D", true, false):
			var m = child as MeshInstance3D
			if m:
				m.set_surface_override_material(0, mat)
