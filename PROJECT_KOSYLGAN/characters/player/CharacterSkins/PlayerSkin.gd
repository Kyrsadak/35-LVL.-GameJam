class_name PlayerSkin
extends Node3D

@export var rotation_speed := 14.0

var _last_strong_direction := Vector3(0, 0, -1)
var anim_player: AnimationPlayer = null
var current_anim: String = ""

func _ready() -> void:
	anim_player = find_child("AnimationPlayer", true, false)
	if anim_player and anim_player.has_animation("Idle"):
		anim_player.play("Idle")
		current_anim = "Idle"

func set_skin_material(mat: Material) -> void:
	pass

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
		if anim_player.has_animation("Dead"):
			anim_player.play("Dead", 0.2)
		current_anim = "Dead"

func reset_animations() -> void:
	if anim_player and anim_player.has_animation("Idle"):
		anim_player.play("Idle", 0.1)
		current_anim = "Idle"

func orient_model_to_direction(direction: Vector3, delta: float) -> void:
	if direction.length() > 0.15:
		_last_strong_direction = direction

	var target_angle = atan2(-_last_strong_direction.x, -_last_strong_direction.z)
	global_rotation.y = lerp_angle(global_rotation.y, target_angle, delta * rotation_speed)
