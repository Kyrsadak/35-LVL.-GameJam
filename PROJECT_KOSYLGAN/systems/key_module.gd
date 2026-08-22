class_name KeyModule
extends Area3D

@export var module_name: String = "Ключевой Модуль"
var collision_shape: CollisionShape3D = null
var mesh_core: MeshInstance3D = null
var mesh_frame: MeshInstance3D = null

var is_carried: bool = false
var time_passed: float = 0.0

func _ready() -> void:
	collision_shape = find_child("CollisionShape3D", true, false) as CollisionShape3D
	mesh_core = find_child("Core", true, false) as MeshInstance3D
	if not mesh_core:
		mesh_core = find_child("CoreMesh", true, false) as MeshInstance3D
	mesh_frame = find_child("Frame", true, false) as MeshInstance3D
	add_to_group("key_module")
	add_to_group("interactable")

	if mesh_core:
		var path = "res://assets/textures/tex_key_module.png"
		var global_p = ProjectSettings.globalize_path(path)
		var img = Image.load_from_file(global_p)
		if img:
			var tex = ImageTexture.create_from_image(img)
			var mat = StandardMaterial3D.new()
			mat.albedo_texture = tex
			mat.emission_enabled = true
			mat.emission_texture = tex
			mat.emission_energy_multiplier = 0.9
			mat.metallic = 0.6
			mat.roughness = 0.3
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			mesh_core.set_surface_override_material(0, mat)

func _process(delta: float) -> void:
	if not is_carried:
		time_passed += delta
		var bob = sin(time_passed * 3.0) * 0.06
		if mesh_core:
			mesh_core.position.y = bob
			mesh_core.rotation.y += delta * 1.5
		if mesh_frame:
			mesh_frame.position.y = bob
			mesh_frame.rotation.y -= delta * 1.0

func pick_up(carrier: Marker3D) -> void:
	is_carried = true
	if collision_shape:
		collision_shape.disabled = true
	get_parent().remove_child(self)
	carrier.add_child(self)
	position = Vector3.ZERO
	rotation = Vector3.ZERO

func drop(drop_pos: Vector3) -> void:
	is_carried = false
	if collision_shape:
		collision_shape.disabled = false
	var scene_root = get_tree().current_scene
	get_parent().remove_child(self)
	scene_root.add_child(self)
	global_position = drop_pos
