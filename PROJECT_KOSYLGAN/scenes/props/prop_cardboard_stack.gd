class_name PropCardboardStack
extends StaticBody3D

func _ready() -> void:
	var path = "res://assets/textures/tex_cardboard_red_tape.png"
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
		
		var tall_box = find_child("TallBox", true, false) as MeshInstance3D
		if tall_box:
			tall_box.set_surface_override_material(0, mat)
