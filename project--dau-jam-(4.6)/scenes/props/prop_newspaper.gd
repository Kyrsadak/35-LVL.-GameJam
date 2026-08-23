class_name PropNewspaper
extends Node3D

@onready var page_mesh: MeshInstance3D = $PageMesh

func _ready() -> void:
	var path = "res://assets/textures/tex_newspaper.png"
	# globalize_path replaced
	var global_p_loaded = load(path)
	var img = global_p_loaded if (global_p_loaded != null) else load(global_p_loaded)
	if img and page_mesh:
		var tex = (img if img is Texture2D else (ImageTexture.create_from_image(img) if img != null else null))
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.metallic = 0.02
		mat.roughness = 0.85
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		page_mesh.set_surface_override_material(0, mat)
