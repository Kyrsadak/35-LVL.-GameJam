class_name KeyModule
extends Area3D

@export var module_name: String = "Энергетическая Батарея D-Cell"
var collision_shape: CollisionShape3D = null
var visuals: Node3D = null
var battery_cylinder: MeshInstance3D = null

var is_carried: bool = false
var time_passed: float = 0.0

func _ready() -> void:
	collision_shape = find_child("CollisionShape3D", true, false) as CollisionShape3D
	visuals = find_child("Visuals", true, false) as Node3D
	battery_cylinder = find_child("BatteryCylinder", true, false) as MeshInstance3D
	add_to_group("key_module")
	add_to_group("battery_cell")
	add_to_group("interactable")

	# Apply Cylindrical Battery Wrap Texture (Copper/Orange Top with +, Charcoal Bottom with -)
	if battery_cylinder:
		var path = "res://assets/textures/tex_cylinder_battery.png"
		var global_p = ProjectSettings.globalize_path(path)
		var img = Image.load_from_file(global_p)
		if img:
			img.generate_mipmaps()
			var tex = ImageTexture.create_from_image(img)
			var mat = StandardMaterial3D.new()
			mat.albedo_texture = tex
			mat.metallic = 0.15
			mat.roughness = 0.35
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			battery_cylinder.set_surface_override_material(0, mat)

func _process(delta: float) -> void:
	if not is_carried:
		time_passed += delta
		var bob = sin(time_passed * 2.5) * 0.04
		if visuals:
			visuals.position.y = bob
			visuals.rotation.y += delta * 0.8

func pick_up(carrier: Marker3D) -> void:
	is_carried = true
	if collision_shape:
		collision_shape.disabled = true
	get_parent().remove_child(self)
	carrier.add_child(self)
	position = Vector3.ZERO
	rotation = Vector3.ZERO
	if visuals:
		visuals.position.y = 0.0
		visuals.rotation.y = 0.0

func drop(drop_pos: Vector3) -> void:
	is_carried = false
	if collision_shape:
		collision_shape.disabled = false
	var scene_root = get_tree().current_scene
	get_parent().remove_child(self)
	scene_root.add_child(self)
	global_position = drop_pos
	rotation = Vector3.ZERO
