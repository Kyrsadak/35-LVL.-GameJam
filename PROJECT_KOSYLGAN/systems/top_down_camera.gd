class_name TopDownCamera
extends Node3D

## High-performance, intuitive 360° orbit and smooth zoom camera system.
## Automatically binds to and follows RobotManager.active_robot with smooth damping.
## Features smart obstacle / wall collision avoidance so characters are NEVER hidden.

@export_group("Tracking")
@export var follow_speed: float = 8.0
@export var target_height_offset: float = 0.85

@export_group("Zoom / Scaling")
@export var min_zoom: float = 4.5
@export var max_zoom: float = 13.0
@export var default_zoom: float = 9.0
@export var zoom_step: float = 0.85
@export var zoom_speed: float = 9.0

@export_group("Orbit / Rotation")
@export var orbit_sensitivity: float = 0.0045
@export var key_orbit_speed: float = 2.4
@export var min_pitch_deg: float = -65.0
@export var max_pitch_deg: float = -28.0
@export var default_pitch_deg: float = -45.0
@export var default_yaw_deg: float = 12.0
@export var rotation_smoothing: float = 14.0

@export_group("Collision Avoidance")
@export var enable_wall_clipping_avoidance: bool = true
@export var wall_collision_mask: int = 2 # Layer 2: World / Walls

@onready var camera_3d: Camera3D = $Camera3D

var current_yaw: float = deg_to_rad(12.0)
var target_yaw: float = deg_to_rad(12.0)

var current_pitch: float = deg_to_rad(-45.0)
var target_pitch: float = deg_to_rad(-45.0)

var current_zoom: float = 9.0
var target_zoom: float = 9.0

var pan_offset: Vector3 = Vector3.ZERO
var target_pan_offset: Vector3 = Vector3.ZERO

var is_orbiting: bool = false
var is_panning: bool = false
var _last_target_node: Node = null

var is_flying_transition: bool = false
var flight_tween: Tween = null

func _ready() -> void:
	target_yaw = deg_to_rad(default_yaw_deg)
	current_yaw = target_yaw
	target_pitch = deg_to_rad(default_pitch_deg)
	current_pitch = target_pitch
	target_zoom = default_zoom
	current_zoom = target_zoom

	if camera_3d:
		camera_3d.fov = 44.0
		_update_camera_transform()

	# Connect to robot switching signal for silky flying camera transition
	if RobotManager:
		RobotManager.robot_switched.connect(_on_robot_switched)
		if RobotManager.active_robot:
			_last_target_node = RobotManager.active_robot
			global_position = _last_target_node.global_position + Vector3(0, target_height_offset, 0)

func _on_robot_switched(active_robot: Node) -> void:
	if not active_robot or not active_robot is Node3D:
		return
	if _last_target_node == null:
		_last_target_node = active_robot
		global_position = (active_robot as Node3D).global_position + Vector3(0, target_height_offset, 0)
		return
	if active_robot != _last_target_node:
		_last_target_node = active_robot
		fly_to_robot(active_robot as Node3D, 0.95)

func fly_to_robot(target: Node3D, duration: float = 0.95) -> void:
	if not target:
		return
	if flight_tween and flight_tween.is_valid():
		flight_tween.kill()
		
	is_flying_transition = true
	var start_pos = global_position
	
	flight_tween = create_tween()
	flight_tween.tween_method(func(t: float):
		if is_instance_valid(target):
			var current_target_pos = target.global_position + Vector3(0, target_height_offset, 0) + pan_offset
			# Cinematic flying trajectory with gentle vertical lift arc
			var lift_arc = sin(t * PI) * 0.55
			global_position = start_pos.lerp(current_target_pos, t) + Vector3(0, lift_arc, 0)
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	flight_tween.tween_callback(func():
		is_flying_transition = false
	)

func _unhandled_input(event: InputEvent) -> void:
	# Mouse button events
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				if mb.shift_pressed:
					is_panning = true
					is_orbiting = false
				else:
					is_orbiting = true
					is_panning = false
			else:
				is_orbiting = false
				is_panning = false
				target_pan_offset = Vector3.ZERO
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			target_zoom = clamp(target_zoom - zoom_step, min_zoom, max_zoom)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			target_zoom = clamp(target_zoom + zoom_step, min_zoom, max_zoom)

	# Mouse motion events
	elif event is InputEventMouseMotion:
		var mm = event as InputEventMouseMotion
		if is_orbiting:
			target_yaw -= mm.relative.x * orbit_sensitivity
			target_pitch = clamp(
				target_pitch - mm.relative.y * orbit_sensitivity,
				deg_to_rad(min_pitch_deg),
				deg_to_rad(max_pitch_deg)
			)
		elif is_panning:
			var rot_basis = Basis(Vector3.UP, current_yaw)
			var pan_delta = rot_basis * Vector3(-mm.relative.x * 0.025, 0, -mm.relative.y * 0.025)
			target_pan_offset = (target_pan_offset + pan_delta).limit_length(7.0)

	# Keyboard shortcuts for quick reset and zoom
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F or event.keycode == KEY_HOME:
			reset_camera()
		elif event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			target_zoom = clamp(target_zoom - zoom_step * 1.5, min_zoom, max_zoom)
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			target_zoom = clamp(target_zoom + zoom_step * 1.5, min_zoom, max_zoom)

func _process(delta: float) -> void:
	# Continuous keyboard rotation controls (Q / C or Arrow keys)
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_LEFT):
		target_yaw += key_orbit_speed * delta
	if Input.is_key_pressed(KEY_C) or Input.is_key_pressed(KEY_RIGHT):
		target_yaw -= key_orbit_speed * delta

	# Continuous keyboard zoom (PageUp / PageDown / Z / X)
	if Input.is_key_pressed(KEY_PAGEUP) or Input.is_key_pressed(KEY_Z):
		target_zoom = clamp(target_zoom - 6.0 * delta, min_zoom, max_zoom)
	if Input.is_key_pressed(KEY_PAGEDOWN) or Input.is_key_pressed(KEY_X):
		target_zoom = clamp(target_zoom + 6.0 * delta, min_zoom, max_zoom)

	# Smooth angle & distance interpolation
	current_yaw = lerp_angle(current_yaw, target_yaw, rotation_smoothing * delta)
	current_pitch = lerp(current_pitch, target_pitch, rotation_smoothing * delta)
	pan_offset = pan_offset.lerp(target_pan_offset, 10.0 * delta)

	var target: Node = null
	if RobotManager and RobotManager.active_robot:
		target = RobotManager.active_robot

	# Track target robot (when not in flying transition)
	if not is_flying_transition:
		if target and target is Node3D:
			var target_pos = (target as Node3D).global_position + Vector3(0, target_height_offset, 0) + pan_offset
			global_position = global_position.lerp(target_pos, follow_speed * delta)

	# Smart Wall Collision Avoidance (Spring-Arm raycast)
	var desired_zoom = target_zoom
	if enable_wall_clipping_avoidance and is_inside_tree():
		var space_state = get_world_3d().direct_space_state
		if space_state:
			var rot_basis = Basis(Vector3.UP, current_yaw) * Basis(Vector3.RIGHT, current_pitch)
			var cam_target_pos = global_position + rot_basis * Vector3(0, 0, target_zoom)
			
			var query = PhysicsRayQueryParameters3D.create(global_position, cam_target_pos, wall_collision_mask)
			if target and target is CollisionObject3D:
				query.exclude = [(target as CollisionObject3D).get_rid()]
			
			var hit = space_state.intersect_ray(query)
			if not hit.is_empty():
				var hit_dist = global_position.distance_to(hit.position)
				desired_zoom = max(2.5, hit_dist - 0.45)

	# Smoothly pull camera in quickly when a wall occludes, ease out smoothly when clear
	if desired_zoom < current_zoom:
		current_zoom = lerp(current_zoom, desired_zoom, 24.0 * delta)
	else:
		current_zoom = lerp(current_zoom, desired_zoom, zoom_speed * delta)

	_update_camera_transform()

func _update_camera_transform() -> void:
	if not camera_3d:
		return

	# When close to a wall, slightly increase pitch to look down cleanly over the obstacle
	var effective_pitch = current_pitch
	if current_zoom < 5.0:
		var t = clamp((5.0 - current_zoom) / 2.5, 0.0, 1.0)
		effective_pitch = lerp(current_pitch, deg_to_rad(-65.0), t * 0.7)

	var rot_basis = Basis(Vector3.UP, current_yaw) * Basis(Vector3.RIGHT, effective_pitch)
	camera_3d.transform.basis = rot_basis
	camera_3d.transform.origin = rot_basis * Vector3(0, 0, current_zoom)

## Smoothly resets the camera angle, zoom, and panning back to default isometric view.
func reset_camera() -> void:
	target_yaw = deg_to_rad(default_yaw_deg)
	target_pitch = deg_to_rad(default_pitch_deg)
	target_zoom = default_zoom
	target_pan_offset = Vector3.ZERO
