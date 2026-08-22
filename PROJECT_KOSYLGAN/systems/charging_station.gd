class_name ChargingStation
extends Area3D

## High-Tech Sci-Fi Cryo-Charging Capsule based on user reference concept art.
## Features stepped docking pedestal, heavy hydraulic clamps, transparent glass chamber
## with "20" stencil decal, top generator roof cap, volumetric energy lighting,
## single-robot capacity limit, and [E] key docking/undocking mechanic.

signal robot_docked(robot: Node3D)
signal robot_undocked(robot: Node3D)

@onready var light_omni: OmniLight3D = $OmniLight3D
@onready var light_spot: SpotLight3D = $SpotLight3D
@onready var charger_arm: Node3D = $TopCap/ChargerArm
@onready var laser_ring: MeshInstance3D = $TopCap/ChargerArm/LaserRing
@onready var glass_mesh: MeshInstance3D = $GlassCylinder
@onready var glass_decal_mesh: MeshInstance3D = $GlassDecalMesh
@onready var energy_field: Node3D = $EnergyField
@onready var plasma_ring_1: MeshInstance3D = $EnergyField/PlasmaRing1
@onready var plasma_ring_2: MeshInstance3D = $EnergyField/PlasmaRing2
@onready var floor_dock_pad: MeshInstance3D = $BasePlatform/FloorDockPad
@onready var outer_hazard_mesh: MeshInstance3D = $BasePlatform/OuterHazardMesh
@onready var clamp_leds: Array[MeshInstance3D] = []

var docked_robot: Node3D = null
var nearby_robots: Array[Node3D] = []
var is_docked: bool = false
var anim_tween: Tween = null
var scan_time: float = 0.0

var glass_material: StandardMaterial3D
var plasma_material: StandardMaterial3D
var led_material: StandardMaterial3D
var yellow_trim_material: StandardMaterial3D
var dark_metal_material: StandardMaterial3D

func _ready() -> void:
	add_to_group("charging_station")
	add_to_group("interactable")
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_setup_materials_and_textures()
	_update_visuals(false)

func _setup_materials_and_textures() -> void:
	# 1. Dark Steel Metal
	dark_metal_material = StandardMaterial3D.new()
	dark_metal_material.albedo_color = Color(0.18, 0.21, 0.28)
	dark_metal_material.metallic = 0.85
	dark_metal_material.roughness = 0.32
	
	# 2. Hazard Yellow Trim
	yellow_trim_material = StandardMaterial3D.new()
	yellow_trim_material.albedo_color = Color(1.0, 0.78, 0.08)
	yellow_trim_material.metallic = 0.5
	yellow_trim_material.roughness = 0.4
	yellow_trim_material.emission_enabled = true
	yellow_trim_material.emission = Color(1.0, 0.78, 0.08)
	yellow_trim_material.emission_energy_multiplier = 0.6
	
	# 3. Transparent Cryo Glass
	glass_material = StandardMaterial3D.new()
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.albedo_color = Color(0.65, 0.90, 1.0, 0.22)
	glass_material.metallic = 0.15
	glass_material.roughness = 0.05
	glass_material.rim_enabled = true
	glass_material.rim = 0.8
	glass_material.rim_tint = 0.5
	glass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if glass_mesh:
		glass_mesh.set_surface_override_material(0, glass_material)
	
	# 4. Glass Decal "20" Texture
	var decal_tex = _generate_decal_texture()
	var decal_mat = StandardMaterial3D.new()
	decal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	decal_mat.albedo_texture = decal_tex
	decal_mat.emission_enabled = true
	decal_mat.emission_texture = decal_tex
	decal_mat.emission_energy_multiplier = 0.8
	decal_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if glass_decal_mesh:
		glass_decal_mesh.set_surface_override_material(0, decal_mat)
	
	# 5. Outer Base Hazard Stripes Texture
	var hazard_tex = _generate_hazard_stripes_texture()
	var hazard_mat = StandardMaterial3D.new()
	hazard_mat.albedo_texture = hazard_tex
	hazard_mat.metallic = 0.6
	hazard_mat.roughness = 0.45
	if outer_hazard_mesh:
		outer_hazard_mesh.set_surface_override_material(0, hazard_mat)
	
	# 6. Plasma Energy Rings Material
	plasma_material = StandardMaterial3D.new()
	plasma_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	plasma_material.albedo_color = Color(0.0, 0.9, 1.0, 0.75)
	plasma_material.emission_enabled = true
	plasma_material.emission = Color(0.0, 0.9, 1.0)
	plasma_material.emission_energy_multiplier = 2.0
	if plasma_ring_1: plasma_ring_1.set_surface_override_material(0, plasma_material)
	if plasma_ring_2: plasma_ring_2.set_surface_override_material(0, plasma_material)
	
	# 7. Clamp Status LEDs
	led_material = StandardMaterial3D.new()
	led_material.albedo_color = Color(0.0, 0.95, 1.0)
	led_material.emission_enabled = true
	led_material.emission = Color(0.0, 0.95, 1.0)
	led_material.emission_energy_multiplier = 2.5
	
	# Collect clamp LED mesh nodes
	var clamps_root = get_node_or_null("BasePlatform/HydraulicClamps")
	if clamps_root:
		for clamp in clamps_root.get_children():
			var led = clamp.get_node_or_null("ClampLED")
			if led and led is MeshInstance3D:
				clamp_leds.append(led)
				led.set_surface_override_material(0, led_material)

func _process(delta: float) -> void:
	scan_time += delta * 3.5
	
	if is_docked:
		# Pulsing volumetric energy light
		if light_omni:
			light_omni.light_energy = 3.2 + sin(scan_time * 2.5) * 0.7
		if light_spot:
			light_spot.light_energy = 4.0 + sin(scan_time * 2.5) * 0.8
		if plasma_material:
			plasma_material.emission_energy_multiplier = 2.5 + sin(scan_time * 4.0) * 1.0
		
		# Vertical floating plasma rings
		if plasma_ring_1:
			plasma_ring_1.position.y = 0.8 + sin(scan_time * 1.8) * 0.5
			plasma_ring_1.rotation.y += delta * 1.2
		if plasma_ring_2:
			plasma_ring_2.position.y = 1.6 - sin(scan_time * 1.8) * 0.5
			plasma_ring_2.rotation.y -= delta * 1.5
		if laser_ring:
			laser_ring.position.y = -0.15 + sin(scan_time * 2.0) * 0.08
		
		# Check if docked robot tries to walk away -> auto undock
		if docked_robot and "velocity" in docked_robot:
			var vel = (docked_robot as CharacterBody3D).velocity
			var horiz_speed = Vector2(vel.x, vel.z).length()
			if horiz_speed > 1.2:
				undock_robot(docked_robot)
	else:
		if light_omni:
			light_omni.light_energy = 1.4 + sin(scan_time * 0.8) * 0.2
		if light_spot:
			light_spot.light_energy = 1.8 + sin(scan_time * 0.8) * 0.3
		if plasma_material:
			plasma_material.emission_energy_multiplier = 0.9 + sin(scan_time * 1.2) * 0.3
		if plasma_ring_1:
			plasma_ring_1.position.y = 1.2 + sin(scan_time * 0.8) * 0.15
			plasma_ring_1.rotation.y += delta * 0.4
		if plasma_ring_2:
			plasma_ring_2.position.y = 1.8 - sin(scan_time * 0.8) * 0.15
			plasma_ring_2.rotation.y -= delta * 0.5

## Called when robot presses interaction key [E]
func interact(caller: Node = null) -> void:
	var robot = caller if (caller and caller is Node3D) else _get_closest_nearby_robot()
	if not robot:
		return
		
	if docked_robot == null:
		dock_robot(robot)
	elif docked_robot == robot:
		undock_robot(robot)
	else:
		# Capsule is occupied by the other robot!
		var occ_name = docked_robot.robot_display_name if "robot_display_name" in docked_robot else "ДРУГИМ РОБОТОМ"
		if RobotManager:
			RobotManager.show_message("⚠️ КАПСУЛА ЗАНЯТА (" + occ_name + ")!")

func dock_robot(robot: Node3D) -> void:
	if not robot or docked_robot != null:
		return
		
	docked_robot = robot
	is_docked = true
	
	if "is_on_charging_station" in robot:
		robot.is_on_charging_station = true
	
	# Smoothly align robot to the center of the charging pad
	var target_dock_pos = global_position + Vector3(0, 0.26, 0)
	var glide_tween = create_tween().set_parallel(true)
	glide_tween.tween_property(robot, "global_position:x", target_dock_pos.x, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	glide_tween.tween_property(robot, "global_position:z", target_dock_pos.z, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Play high-tech docking animation
	_play_dock_animation(true)
	if SoundManager and SoundManager.has_method("play_pickup"):
		SoundManager.play_pickup()
		
	if RobotManager:
		var r_name = robot.robot_display_name if "robot_display_name" in robot else "РОБОТ"
		RobotManager.show_message("⚡ " + r_name + " ПОДКЛЮЧЕН К ЗАРЯДКЕ!")
		
	robot_docked.emit(robot)

func undock_robot(robot: Node3D) -> void:
	if docked_robot != robot:
		return
		
	if "is_on_charging_station" in robot:
		robot.is_on_charging_station = false
		
	docked_robot = null
	is_docked = false
	
	_play_dock_animation(false)
	if SoundManager and SoundManager.has_method("play_drop"):
		SoundManager.play_drop()
		
	robot_undocked.emit(robot)

func _play_dock_animation(dock: bool) -> void:
	if anim_tween and anim_tween.is_valid():
		anim_tween.kill()
		
	anim_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if dock:
		# Lower overhead charging contact arm down into capsule
		if charger_arm:
			anim_tween.tween_property(charger_arm, "position:y", 1.95, 0.45)
		# Radiant Emerald Plasma Power Light
		if light_omni:
			anim_tween.tween_property(light_omni, "light_color", Color(0.15, 1.0, 0.50), 0.3)
		if light_spot:
			anim_tween.tween_property(light_spot, "light_color", Color(0.20, 1.0, 0.55), 0.3)
		if plasma_material:
			plasma_material.emission = Color(0.15, 1.0, 0.50)
			plasma_material.albedo_color = Color(0.15, 1.0, 0.50, 0.85)
		if led_material:
			led_material.emission = Color(0.15, 1.0, 0.50)
			led_material.albedo_color = Color(0.15, 1.0, 0.50)
		if laser_ring:
			laser_ring.visible = true
	else:
		# Retract overhead charging arm up into top generator cap
		if charger_arm:
			anim_tween.tween_property(charger_arm, "position:y", 2.65, 0.40).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Standby Calm Neon Cyan Light
		if light_omni:
			anim_tween.tween_property(light_omni, "light_color", Color(0.0, 0.85, 1.0), 0.3)
		if light_spot:
			anim_tween.tween_property(light_spot, "light_color", Color(0.0, 0.90, 1.0), 0.3)
		if plasma_material:
			plasma_material.emission = Color(0.0, 0.85, 1.0)
			plasma_material.albedo_color = Color(0.0, 0.85, 1.0, 0.75)
		if led_material:
			led_material.emission = Color(0.0, 0.95, 1.0)
			led_material.albedo_color = Color(0.0, 0.95, 1.0)
		if laser_ring:
			laser_ring.visible = false

func _update_visuals(dock: bool) -> void:
	if charger_arm:
		charger_arm.position.y = 1.95 if dock else 2.65
	if light_omni:
		light_omni.light_color = Color(0.15, 1.0, 0.50) if dock else Color(0.0, 0.85, 1.0)
		light_omni.light_energy = 3.2 if dock else 1.4
	if light_spot:
		light_spot.light_color = Color(0.20, 1.0, 0.55) if dock else Color(0.0, 0.90, 1.0)
		light_spot.light_energy = 4.0 if dock else 1.8
	if laser_ring:
		laser_ring.visible = dock

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or "is_on_charging_station" in body:
		if not nearby_robots.has(body):
			nearby_robots.append(body)
			
		if "current_interactable" in body:
			body.current_interactable = self
		if body.has_signal("interact_target_changed"):
			body.interact_target_changed.emit(self)

func _on_body_exited(body: Node3D) -> void:
	if nearby_robots.has(body):
		nearby_robots.erase(body)
		
	if "current_interactable" in body and body.current_interactable == self:
		body.current_interactable = null
		if body.has_signal("interact_target_changed"):
			body.interact_target_changed.emit(null)

func _get_closest_nearby_robot() -> Node3D:
	if nearby_robots.is_empty():
		return null
	var closest: Node3D = null
	var min_dist = INF
	for r in nearby_robots:
		var d = global_position.distance_squared_to(r.global_position)
		if d < min_dist:
			min_dist = d
			closest = r
	return closest

## Procedurally generates the "20" stencil decal texture for the glass capsule
func _generate_decal_texture() -> ImageTexture:
	var w = 256
	var h = 320
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0)) # Fully transparent base
	
	# Draw stencil Number "2"
	var col_white = Color(1.0, 1.0, 1.0, 0.92)
	var col_yellow = Color(1.0, 0.80, 0.08, 0.95)
	
	# Number "2"
	_draw_img_rect(img, 40, 40, 70, 16, col_white)  # top bar
	_draw_img_rect(img, 94, 56, 16, 50, col_white)  # top-right
	_draw_img_rect(img, 40, 106, 70, 16, col_white) # middle bar
	_draw_img_rect(img, 40, 122, 16, 50, col_white) # bot-left
	_draw_img_rect(img, 40, 172, 70, 16, col_white) # bot bar
	
	# Number "0"
	_draw_img_rect(img, 130, 40, 70, 16, col_white)  # top bar
	_draw_img_rect(img, 130, 56, 16, 116, col_white) # left bar
	_draw_img_rect(img, 184, 56, 16, 116, col_white) # right bar
	_draw_img_rect(img, 130, 172, 70, 16, col_white) # bot bar
	
	# Lower Yellow Hazard Stencil Bracket [ 20 ]
	_draw_img_rect(img, 30, 210, 180, 8, col_yellow)   # bracket bottom
	_draw_img_rect(img, 30, 180, 8, 30, col_yellow)    # left hook
	_draw_img_rect(img, 202, 180, 8, 30, col_yellow)   # right hook
	_draw_img_rect(img, 50, 226, 140, 32, Color(1.0, 0.80, 0.08, 0.45)) # filled accent
	
	return ImageTexture.create_from_image(img)

## Procedurally generates the outer circular hazard stripes texture
func _generate_hazard_stripes_texture() -> ImageTexture:
	var size = 256
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var col_dark = Color(0.14, 0.16, 0.22, 1.0)
	var col_steel = Color(0.24, 0.28, 0.36, 1.0)
	var col_yellow = Color(1.0, 0.80, 0.08, 1.0)
	var col_black = Color(0.08, 0.09, 0.12, 1.0)
	
	var center = Vector2(size * 0.5, size * 0.5)
	var radius_max = float(size) * 0.48
	var radius_inner = float(size) * 0.34
	
	for y in range(size):
		for x in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist <= radius_max and dist >= radius_inner:
				# Diagonal stripes angle
				var angle = (x + y) % 24
				if angle < 12:
					img.set_pixel(x, y, col_yellow)
				else:
					img.set_pixel(x, y, col_black)
			elif dist < radius_inner:
				img.set_pixel(x, y, col_steel)
			else:
				img.set_pixel(x, y, col_dark)
				
	return ImageTexture.create_from_image(img)

func _draw_img_rect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	for dy in range(h):
		for dx in range(w):
			var px = x + dx
			var py = y + dy
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(px, py, col)
