class_name PlayerSkin
extends Node3D

@export var rotation_speed := 12.0

var _last_strong_direction := Vector3.FORWARD
var anim_player: AnimationPlayer = null
var current_anim: String = ""

func _ready() -> void:
	anim_player = find_child("AnimationPlayer", true, false)
	if anim_player:
		anim_player.play("Idle")
		current_anim = "Idle"

func set_skin_material(mat: Material) -> void:
	var body_mesh = find_child("body", true, false)
	if not body_mesh:
		body_mesh = find_child("icy", true, false)
	if not body_mesh:
		body_mesh = find_child("MeshInstance3D", true, false)
	if body_mesh and body_mesh is MeshInstance3D:
		body_mesh.material_override = mat

func update_move_animation(velocity_ratio: float, delta: float) -> void:
	if not anim_player:
		return
	if velocity_ratio > 0.1:
		if current_anim != "Run":
			if anim_player.has_animation("Run"):
				anim_player.play("Run", 0.15)
				current_anim = "Run"
	else:
		if current_anim != "Idle":
			if anim_player.has_animation("Idle"):
				anim_player.play("Idle", 0.15)
				current_anim = "Idle"

func move_to_dead() -> void:
	if anim_player:
		if anim_player.has_animation("Falling"):
			anim_player.play("Falling", 0.2)
		elif anim_player.has_animation("Idle-break"):
			anim_player.play("Idle-break", 0.2)
		current_anim = "Dead"

func reset_animations() -> void:
	if anim_player and anim_player.has_animation("Idle"):
		anim_player.play("Idle", 0.1)
		current_anim = "Idle"

func orient_model_to_direction(direction: Vector3, delta: float) -> void:
	if direction.length() > 0.2:
		_last_strong_direction = direction

	global_rotation.y = lerp_angle(
		global_rotation.y,
		Vector2(_last_strong_direction.z, _last_strong_direction.x).angle(),
		delta * rotation_speed
	)
