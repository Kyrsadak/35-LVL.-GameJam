class_name PlayerSkin
extends Node3D

@export var rotation_speed := 16.0

var _last_strong_direction := Vector3(0, 0, -1)
var anim_player: AnimationPlayer = null
var current_anim: String = ""
var is_holding: bool = false
var is_lifting: bool = false

func _ready() -> void:
	anim_player = find_child("AnimationPlayer", true, false)
	if anim_player and anim_player.has_animation("Idle"):
		anim_player.play("Idle")
		current_anim = "Idle"

func set_skin_material(mat: Material) -> void:
	pass

func play_lift() -> void:
	if not anim_player:
		return
	is_lifting = true
	is_holding = true
	if anim_player.has_animation("Lift"):
		anim_player.play("Lift", 0.08)
		current_anim = "Lift"
		get_tree().create_timer(0.35).timeout.connect(func():
			is_lifting = false
		)
	else:
		is_lifting = false

func set_holding(holding: bool) -> void:
	is_holding = holding
	if not is_holding and current_anim in ["Lift", "Idle_Hold", "Run_Hold"]:
		if anim_player and anim_player.has_animation("Idle"):
			anim_player.play("Idle", 0.15)
			current_anim = "Idle"

func update_move_animation(velocity_ratio: float, delta: float) -> void:
	if not anim_player or is_lifting:
		return

	if is_holding:
		if velocity_ratio > 0.1:
			var target_run = "Run_Hold" if anim_player.has_animation("Run_Hold") else "Run"
			if current_anim != target_run:
				anim_player.play(target_run, 0.1)
				current_anim = target_run
			anim_player.speed_scale = clamp(velocity_ratio * 1.2, 0.7, 1.4)
		else:
			var target_idle = "Idle_Hold" if anim_player.has_animation("Idle_Hold") else "Idle"
			if current_anim != target_idle:
				anim_player.play(target_idle, 0.15)
				current_anim = target_idle
			anim_player.speed_scale = 1.0
	else:
		if velocity_ratio > 0.1:
			if current_anim != "Run":
				if anim_player.has_animation("Run"):
					anim_player.play("Run", 0.1)
					current_anim = "Run"
			anim_player.speed_scale = clamp(velocity_ratio * 1.2, 0.7, 1.4)
		else:
			if current_anim != "Idle":
				if anim_player.has_animation("Idle"):
					anim_player.play("Idle", 0.15)
					current_anim = "Idle"
			anim_player.speed_scale = 1.0

func move_to_dead() -> void:
	if anim_player:
		if anim_player.has_animation("Dead"):
			anim_player.play("Dead", 0.2)
		current_anim = "Dead"

func reset_animations() -> void:
	is_holding = false
	is_lifting = false
	if anim_player and anim_player.has_animation("Idle"):
		anim_player.play("Idle", 0.1)
		current_anim = "Idle"

func orient_model_to_direction(direction: Vector3, delta: float) -> void:
	if direction.length() > 0.15:
		_last_strong_direction = direction

	var target_angle = atan2(-_last_strong_direction.x, -_last_strong_direction.z)
	global_rotation.y = lerp_angle(global_rotation.y, target_angle, delta * rotation_speed)
