class_name PropNewspaper
extends Node3D

@onready var page_mesh: MeshInstance3D = $PageMesh

func _ready() -> void:
	var path = "res://assets/textures/tex_newspaper.png"
	var global_p = ProjectSettings.globalize_path(path)
	var img = Image.load_from_file(global_p)
	if img and page_mesh:
		var tex = ImageTexture.create_from_image(img)
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.metallic = 0.02
		mat.roughness = 0.85
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		page_mesh.set_surface_override_material(0, mat)
