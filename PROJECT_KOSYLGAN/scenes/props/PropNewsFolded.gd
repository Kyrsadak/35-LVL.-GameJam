class_name PropNewsFolded
extends Node3D

func _ready() -> void:
	var path = "res://assets/textures/tex_newspaper.png"
	var global_p = ProjectSettings.globalize_path(path)
	var img = Image.load_from_file(global_p)
	if img:
		img.generate_mipmaps()
		var tex = ImageTexture.create_from_image(img)
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.metallic = 0.02
		mat.roughness = 0.85
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var m_0 = find_child("TopPage", true, false) as MeshInstance3D
		if m_0:
			m_0.set_surface_override_material(0, mat)
		var m_1 = find_child("StackBase", true, false) as MeshInstance3D
		if m_1:
			m_1.set_surface_override_material(0, mat)
