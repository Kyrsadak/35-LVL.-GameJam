class_name PropPickleRick
extends StaticBody3D

@onready var body_mesh: MeshInstance3D = find_child("BodyMesh", true, false) as MeshInstance3D
@onready var face_decal: MeshInstance3D = find_child("FaceDecal", true, false) as MeshInstance3D
@onready var label_3d: Label3D = find_child("EasterEggLabel", true, false) as Label3D
@onready var anim_pivot: Node3D = find_child("AnimPivot", true, false) as Node3D

var _is_animating: bool = false
var _wiggle_cooldown: float = 0.0
var _base_y: float = 0.0

var phrases: Array[String] = [
	"Я ОГУРЧИК РИК!",
	"I'M PICKLE RICK!",
	"МОРТИ, СМОТРИ НА МЕНЯ!",
	"СОЛЁНЫЙ И НЕПОБЕДИМЫЙ!"
]
var _phrase_idx: int = 0

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("pickle_rick")
	
	if anim_pivot:
		_base_y = anim_pivot.position.y
	
	_load_textures()
	
	var area = find_child("ProximityArea", true, false) as Area3D
	if area:
		area.body_entered.connect(_on_proximity_entered)
	
	if label_3d:
		label_3d.visible = false
		label_3d.modulate.a = 0.0

func _process(delta: float) -> void:
	if _wiggle_cooldown > 0.0:
		_wiggle_cooldown -= delta

func _load_textures() -> void:
	var path_tex = "res://assets/textures/tex_pickle_rick.png"
	# globalize_path replaced
	var global_p_loaded = load(path_tex)
	var img = global_p_loaded if (global_p_loaded != null) else load(global_p_loaded)
	if img:
		if img is Image:
			img.generate_mipmaps()
		var tex = (img if img is Texture2D else (ImageTexture.create_from_image(img) if img != null else null))
		
		# 1. Front face material
		var mat_face = StandardMaterial3D.new()
		mat_face.albedo_texture = tex
		mat_face.roughness = 0.45
		mat_face.metallic = 0.05
		mat_face.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		mat_face.cull_mode = BaseMaterial3D.CULL_DISABLED
		if face_decal:
			face_decal.set_surface_override_material(0, mat_face)
			
		# 2. Body skin material
		if body_mesh:
			var mat_skin = StandardMaterial3D.new()
			mat_skin.albedo_color = Color(0.22, 0.48, 0.16, 1.0)
			mat_skin.roughness = 0.55
			mat_skin.metallic = 0.05
			body_mesh.set_surface_override_material(0, mat_skin)

func _on_proximity_entered(body: Node3D) -> void:
	if not (body.is_in_group("player") or body.is_in_group("robots")):
		return
	if _wiggle_cooldown <= 0.0 and not _is_animating:
		_wiggle_cooldown = 4.0
		_play_wobble_reaction()

func interact(_actor: Node3D = null) -> void:
	if not _is_animating:
		_play_excited_jump()

func _play_wobble_reaction() -> void:
	if not anim_pivot:
		return
	_is_animating = true
	_show_quote(phrases[_phrase_idx % phrases.size()])
	_phrase_idx += 1
	
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(anim_pivot, "rotation:z", deg_to_rad(14.0), 0.12)
	tw.tween_property(anim_pivot, "rotation:z", deg_to_rad(-14.0), 0.14)
	tw.tween_property(anim_pivot, "rotation:z", deg_to_rad(8.0), 0.12)
	tw.tween_property(anim_pivot, "rotation:z", deg_to_rad(-6.0), 0.10)
	tw.tween_property(anim_pivot, "rotation:z", 0.0, 0.12)
	tw.parallel().tween_property(anim_pivot, "position:y", _base_y + 0.08, 0.15)
	tw.tween_property(anim_pivot, "position:y", _base_y, 0.15)
	tw.finished.connect(func(): _is_animating = false)

func _play_excited_jump() -> void:
	if not anim_pivot:
		return
	_is_animating = true
	_show_quote("I'M PICKLE RICK!!! 🥒⚡")
	
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(anim_pivot, "position:y", _base_y + 0.35, 0.22)
	tw.parallel().tween_property(anim_pivot, "rotation:y", anim_pivot.rotation.y + deg_to_rad(360.0), 0.45)
	tw.parallel().tween_property(anim_pivot, "scale", Vector3(1.15, 0.85, 1.15), 0.22)
	tw.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(anim_pivot, "position:y", _base_y, 0.25)
	tw.parallel().tween_property(anim_pivot, "scale", Vector3(1.0, 1.0, 1.0), 0.25)
	tw.finished.connect(func(): _is_animating = false)

func _show_quote(text: String) -> void:
	if not label_3d:
		return
	label_3d.text = text
	label_3d.visible = true
	label_3d.modulate.a = 0.0
	label_3d.position.y = 0.55
	
	var tw = create_tween()
	tw.tween_property(label_3d, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(label_3d, "position:y", 0.65, 0.2)
	tw.tween_interval(2.0)
	tw.tween_property(label_3d, "modulate:a", 0.0, 0.4)
	tw.finished.connect(func(): label_3d.visible = false)
