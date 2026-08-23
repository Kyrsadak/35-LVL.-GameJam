class_name RobotBase
extends CharacterBody3D

signal battery_changed(current: float, max_value: float)
signal discharged()
signal charging_state_changed(is_charging: bool)
signal interact_target_changed(target: Node)

@export var robot_id: String = "base"
@export var robot_display_name: String = "ROBOT"
@export var robot_color: Color = Color.WHITE

@export var move_speed: float = 3.33
@export var acceleration: float = 13.0
@export var friction: float = 14.5
@export var gravity: float = 25.0

@export var max_battery: float = 100.0
@export var discharge_rate: float = 2.8 # ~35 sec
@export var charge_rate: float = 4.2    # 1.5x discharge rate (balanced charging)

var battery: float = 100.0
var is_active: bool = false
var is_on_charging_station: bool = false:
	set(value):
		if is_on_charging_station != value:
			is_on_charging_station = value
			charging_state_changed.emit(is_on_charging_station)
var is_discharged: bool = false
var current_interactable: Node = null
var current_charging_station: Node3D = null

@onready var skin = $Skin
@onready var interaction_area: Area3D = find_child("InteractionArea", true, false) as Area3D
@onready var carry_pivot: Marker3D = find_child("CarryPivot", true, false) as Marker3D
@onready var push_ray: RayCast3D = find_child("PushRay", true, false) as RayCast3D

var carried_object: Node3D = null
var _step_timer: float = 0.0

func _ready() -> void:
	battery = max_battery
	charge_rate = discharge_rate * 1.5
	if interaction_area:
		interaction_area.area_entered.connect(_on_interaction_area_entered)
		interaction_area.area_exited.connect(_on_interaction_area_exited)
		interaction_area.body_entered.connect(_on_interaction_body_entered)
		interaction_area.body_exited.connect(_on_interaction_body_exited)

func set_active(active: bool) -> void:
	is_active = active
	if not is_active:
		velocity.x = 0
		velocity.z = 0
		if skin:
			skin.update_move_animation(0.0, 0.0)
			if skin.has_method("set_sleeping"):
				skin.set_sleeping(true)
	else:
		if skin:
			if skin.has_method("set_sleeping"):
				skin.set_sleeping(false)

func get_facing_direction() -> Vector3:
	if skin:
		return skin.global_transform.basis.z.normalized()
	return global_transform.basis.z.normalized()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# Keep carry pivot aligned with the direction the robot is facing (resting cleanly on top of forklift tines)
	if skin and carry_pivot:
		carry_pivot.global_position = global_position + Vector3(0, 0.40, 0) + get_facing_direction() * 1.05
		carry_pivot.global_rotation.y = skin.global_rotation.y

	if is_discharged:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)
		move_and_slide()
		return

	# Dynamic Battery Drain & Charge Logic
	var is_dialogue_open: bool = RobotManager != null and RobotManager.is_dialogue_active

	if RobotManager and "infinite_energy_active" in RobotManager and RobotManager.infinite_energy_active:
		battery = max_battery
		battery_changed.emit(battery, max_battery)
	elif is_on_charging_station:
		# Strictly charge only: zero drain while docked
		velocity = Vector3.ZERO
		if battery < max_battery:
			battery = min(max_battery, battery + charge_rate * delta)
			battery_changed.emit(battery, max_battery)
		if is_active:
			_handle_input()
		if skin and skin.has_method("update_move_animation"):
			skin.update_move_animation(0.0, delta)
		return # Prevent physics engine from ever pushing robot upwards onto roof
	elif is_dialogue_open:
		# Battery drain is completely PAUSED while reading dialogues!
		pass
	elif is_active:
		var current_drain = discharge_rate
		# Increase drain when moving
		if velocity.length_squared() > 0.1:
			current_drain *= 1.4
		# Extra drain for Atlas when carrying heavy objects
		if carried_object != null:
			current_drain *= 1.5
			
		battery = max(0.0, battery - current_drain * delta)
		battery_changed.emit(battery, max_battery)
		if battery <= 0.0:
			on_battery_depleted()
	else:
		# Passive low standby drain for inactive robot
		battery = max(0.0, battery - (discharge_rate * 0.15) * delta)
		battery_changed.emit(battery, max_battery)
		if battery <= 0.0:
			on_battery_depleted()

	if is_active and not is_discharged:
		_handle_movement(delta)
		_handle_input()
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)
		if skin and skin.has_method("update_move_animation"):
			skin.update_move_animation(0.0, delta)

	move_and_slide()

func _handle_movement(delta: float) -> void:
	var input_vec = Vector2.ZERO
	if Input.is_action_pressed("p1_move_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_vec.x -= 1.0
	if Input.is_action_pressed("p1_move_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_vec.x += 1.0
	if Input.is_action_pressed("p1_move_up") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_vec.y -= 1.0
	if Input.is_action_pressed("p1_move_down") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_vec.y += 1.0

	var is_sprinting = Input.is_action_pressed("p1_sprint") or Input.is_key_pressed(KEY_SHIFT)
	var current_move_speed = move_speed * 1.65 if is_sprinting else move_speed

	var move_dir = Vector3.ZERO
	if input_vec.length_squared() > 0.01:
		input_vec = input_vec.normalized()
		
		# Get active camera horizontal basis
		var cam = get_viewport().get_camera_3d()
		if cam:
			var cam_basis = cam.global_transform.basis
			var forward = -cam_basis.z
			var right = cam_basis.x
			forward.y = 0.0
			right.y = 0.0
			forward = forward.normalized()
			right = right.normalized()
			move_dir = (right * input_vec.x + forward * -input_vec.y).normalized()
		else:
			move_dir = Vector3(input_vec.x, 0, input_vec.y).normalized()

	if move_dir.length_squared() > 0.01:
		velocity.x = move_toward(velocity.x, move_dir.x * current_move_speed, acceleration * (1.3 if is_sprinting else 1.0) * delta)
		velocity.z = move_toward(velocity.z, move_dir.z * current_move_speed, acceleration * (1.3 if is_sprinting else 1.0) * delta)
		
		if skin:
			skin.orient_model_to_direction(move_dir, delta)
			skin.update_move_animation(velocity.length() / move_speed, delta)

		var current_speed_scale = 0.75 * (1.65 if is_sprinting else 1.0)
		if skin and "anim_player" in skin and skin.anim_player:
			current_speed_scale = skin.anim_player.speed_scale * (1.65 if is_sprinting else 1.0)
		var step_interval = 0.38 / max(0.1, current_speed_scale)

		_step_timer += delta
		if _step_timer >= step_interval:
			_step_timer = 0.0
			if SoundManager:
				SoundManager.play_footstep(-8.0)
	else:
		_step_timer = 0.20
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)
		if skin:
			skin.update_move_animation(velocity.length() / move_speed, delta)

func _handle_input() -> void:
	if Input.is_action_just_pressed("p1_interact"):
		interact()

func interact() -> void:
	# Overridden in Atlas / Cipher subclasses
	pass

func exit_charging_station() -> void:
	if current_charging_station and is_instance_valid(current_charging_station) and current_charging_station.has_method("undock_robot"):
		current_charging_station.undock_robot(self)
		return
	for cs in get_tree().get_nodes_in_group("charging_station"):
		if cs.get("docked_robot") == self:
			cs.undock_robot(self)
			return
	for cs in get_tree().get_nodes_in_group("charging_station"):
		if cs.has_method("undock_robot"):
			cs.undock_robot(self)
			if not is_on_charging_station:
				return

func on_battery_depleted() -> void:
	if is_discharged:
		return
	is_discharged = true
	velocity = Vector3.ZERO
	if skin:
		skin.move_to_dead()
	discharged.emit()

func restore_battery() -> void:
	battery = max_battery
	is_discharged = false
	if skin:
		skin.reset_animations()
	battery_changed.emit(battery, max_battery)

func _on_interaction_area_entered(area: Area3D) -> void:
	if area.is_in_group("interactable") or area.is_in_group("charging_station"):
		current_interactable = area
		interact_target_changed.emit(area)

func _on_interaction_area_exited(area: Area3D) -> void:
	if current_interactable == area:
		current_interactable = null
		interact_target_changed.emit(null)

func _on_interaction_body_entered(body: Node3D) -> void:
	if body.is_in_group("interactable") or body.is_in_group("charging_station"):
		current_interactable = body
		interact_target_changed.emit(body)

func _on_interaction_body_exited(body: Node3D) -> void:
	if current_interactable == body:
		current_interactable = null
		interact_target_changed.emit(null)

func get_best_interactable() -> Node:
	if current_interactable and is_instance_valid(current_interactable):
		return current_interactable
	if push_ray and push_ray.is_colliding():
		var col = push_ray.get_collider()
		if col:
			return col
	if interaction_area:
		for a in interaction_area.get_overlapping_areas():
			if a.is_in_group("socket_terminal") or a.is_in_group("terminal") or a.is_in_group("dual_generator") or a.is_in_group("guide_tablet") or a.is_in_group("interactable") or a.is_in_group("charging_station"):
				return a
		for b in interaction_area.get_overlapping_bodies():
			if b.is_in_group("socket_terminal") or b.is_in_group("terminal") or b.is_in_group("dual_generator") or b.is_in_group("key_module") or b.is_in_group("interactable"):
				return b
	return null
