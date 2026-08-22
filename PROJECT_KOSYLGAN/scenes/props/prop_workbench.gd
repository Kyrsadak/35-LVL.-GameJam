class_name PropWorkbench
extends StaticBody3D

@onready var table_top: MeshInstance3D = $TableTop

func _ready() -> void:
	var path = "res://assets/textures/tex_workbench.png"
	var global_p = ProjectSettings.globalize_path(path)
	var img = Image.load_from_file(global_p)
	if img and table_top:
		var tex = ImageTexture.create_from_image(img)
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.metallic = 0.3
		mat.roughness = 0.5
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		table_top.set_surface_override_material(0, mat)
