class_name PropWallPoster
extends Node3D

@export var poster_index: int = 0 # 0: Safety Hazard, 1: Blueprint, 2: Banana Slip, 3: Cyberpunk

@onready var poster_sheet: MeshInstance3D = $PosterSheet

var poster_paths = [
	"res://assets/textures/tex_poster_safety.png",
	"res://assets/textures/tex_poster_blueprint.png",
	"res://assets/textures/tex_poster_banana.png",
	"res://assets/textures/tex_poster_cyberpunk.png"
]

func _ready() -> void:
	var path = poster_paths[posmod(poster_index, poster_paths.size())]
	# globalize_path replaced
	var global_p_loaded = load(path)
	var img = global_p_loaded if (global_p_loaded != null) else load(global_p_loaded)
	if img and poster_sheet:
		if img is Image:
			img.generate_mipmaps()
		var tex = (img if img is Texture2D else (ImageTexture.create_from_image(img) if img != null else null))
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.metallic = 0.05
		mat.roughness = 0.55
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		poster_sheet.set_surface_override_material(0, mat)
