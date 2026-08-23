class_name ChargingStation
extends Area3D

## High-Tech Sci-Fi Cryo-Charging Capsule based on user reference concept art.
## Features stepped docking pedestal, 3D glowing energy conduits, dynamic stencil digit display,
## clean titanium base plate (no yellow hazard stripes), full solid physical perimeter collision,
## and [E] key only docking and undocking.

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
@onready var station_collider: StaticBody3D = $StationCollider
@onready var clamp_leds: Array[MeshInstance3D] = []
@onready var conduit_meshes: Array[MeshInstance3D] = []

var docked_robot: Node3D = null
var nearby_robots: Array[Node3D] = []
var is_docked: bool = false
var anim_tween: Tween = null
var scan_time: float = 0.0
var _current_displayed_pct: int = -999

var glass_material: StandardMaterial3D
var plasma_material: StandardMaterial3D
var led_material: StandardMaterial3D
var yellow_trim_material: StandardMaterial3D
var dark_metal_material: StandardMaterial3D
var conduit_material: StandardMaterial3D
var decal_material: StandardMaterial3D

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
	
	# 2. Yellow Trim (Caps & Clamps)
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
	glass_material.albedo_color = Color(0.65, 0.90, 1.0, 0.20)
	glass_material.metallic = 0.15
	glass_material.roughness = 0.05
	glass_material.rim_enabled = true
	glass_material.rim = 0.8
	glass_material.rim_tint = 0.5
	glass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if glass_mesh:
		glass_mesh.set_surface_override_material(0, glass_material)
	
	# 4. Glass Decal Dynamic Number Display Texture
	decal_material = StandardMaterial3D.new()
	decal_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	decal_material.emission_enabled = true
	decal_material.emission_energy_multiplier = 1.2
	decal_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	decal_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_update_decal_texture("00")
	if glass_decal_mesh:
		glass_decal_mesh.set_surface_override_material(0, decal_material)
	
	# 5. Outer Base Sleek Titanium Plate Texture (No yellow stripes)
	var base_tex = _generate_sleek_base_texture()
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_texture = base_tex
	base_mat.metallic = 0.75
	base_mat.roughness = 0.35
	base_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if outer_hazard_mesh:
		outer_hazard_mesh.set_surface_override_material(0, base_mat)
	
	# 6. 3D Energy Conduits / Cables Material
	conduit_material = StandardMaterial3D.new()
	conduit_material.albedo_color = Color(0.0, 0.85, 1.0)
	conduit_material.metallic = 0.4
	conduit_material.roughness = 0.3
	conduit_material.emission_enabled = true
	conduit_material.emission = Color(0.0, 0.85, 1.0)
	conduit_material.emission_energy_multiplier = 1.6
	
	var conduits_root = get_node_or_null("BasePlatform/BaseConduits")
	if conduits_root:
		for conduit in conduits_root.get_children():
			if conduit is MeshInstance3D:
				conduit_meshes.append(conduit)
				conduit.set_surface_override_material(0, conduit_material)
	
	# 7. Plasma Energy Rings Material
	plasma_material = StandardMaterial3D.new()
	plasma_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	plasma_material.albedo_color = Color(0.0, 0.9, 1.0, 0.75)
	plasma_material.emission_enabled = true
	plasma_material.emission = Color(0.0, 0.9, 1.0)
	plasma_material.emission_energy_multiplier = 2.0
	if plasma_ring_1: plasma_ring_1.set_surface_override_material(0, plasma_material)
	if plasma_ring_2: plasma_ring_2.set_surface_override_material(0, plasma_material)
	
	# 8. Clamp Status LEDs
	led_material = StandardMaterial3D.new()
	led_material.albedo_color = Color(0.0, 0.95, 1.0)
	led_material.emission_enabled = true
	led_material.emission = Color(0.0, 0.95, 1.0)
	led_material.emission_energy_multiplier = 2.5
	
	var clamps_root = get_node_or_null("BasePlatform/HydraulicClamps")
	if clamps_root:
		for clamp_node in clamps_root.get_children():
			var led = clamp_node.get_node_or_null("ClampLED")
			if led and led is MeshInstance3D:
				clamp_leds.append(led)
				led.set_surface_override_material(0, led_material)

func _process(delta: float) -> void:
	scan_time += delta * 3.5
	
	# Live animated glow on 3D energy conduit cables
	if conduit_material:
		var energy_flow = 1.3 + 0.7 * sin(scan_time * 2.8)
		conduit_material.emission_energy_multiplier = energy_flow
		if is_docked:
			conduit_material.emission = Color(0.15, 1.0, 0.50)
			conduit_material.albedo_color = Color(0.15, 1.0, 0.50)
		else:
			conduit_material.emission = Color(0.0, 0.85, 1.0)
			conduit_material.albedo_color = Color(0.0, 0.85, 1.0)
	
	# Synchronize glass stencil number with docked robot battery in real time
	if docked_robot and "battery" in docked_robot and "max_battery" in docked_robot:
		var pct = int(round((docked_robot.battery / docked_robot.max_battery) * 100.0))
		if pct != _current_displayed_pct:
			_current_displayed_pct = pct
			_update_decal_texture(str(pct))
	else:
		if _current_displayed_pct != 0:
			_current_displayed_pct = 0
			_update_decal_texture("00")
	
	if is_docked:
		# Pulsing volumetric energy light
		if light_omni:
			light_omni.light_energy = 3.0 + sin(scan_time * 2.5) * 0.6
		if light_spot:
			light_spot.light_energy = 3.8 + sin(scan_time * 2.5) * 0.7
		if plasma_material:
			plasma_material.emission_energy_multiplier = 2.5 + sin(scan_time * 4.0) * 1.0
		
		# Vertical floating plasma rings
		if plasma_ring_1:
			plasma_ring_1.position.y = 0.70 + sin(scan_time * 1.8) * 0.4
			plasma_ring_1.rotation.y += delta * 1.2
		if plasma_ring_2:
			plasma_ring_2.position.y = 1.45 - sin(scan_time * 1.8) * 0.4
			plasma_ring_2.rotation.y -= delta * 1.5
		if laser_ring:
			laser_ring.position.y = -0.12 + sin(scan_time * 2.0) * 0.06
			
		# Hold docked robot firmly on the floor dock pad inside capsule
		if docked_robot:
			docked_robot.global_position = global_position + Vector3(0, 0.23, 0)
			if docked_robot is CharacterBody3D:
				docked_robot.velocity = Vector3.ZERO
	else:
		if light_omni:
			light_omni.light_energy = 1.3 + sin(scan_time * 0.8) * 0.2
		if light_spot:
			light_spot.light_energy = 1.6 + sin(scan_time * 0.8) * 0.3
		if plasma_material:
			plasma_material.emission_energy_multiplier = 0.9 + sin(scan_time * 1.2) * 0.3
		if plasma_ring_1:
			plasma_ring_1.position.y = 1.05 + sin(scan_time * 0.8) * 0.12
			plasma_ring_1.rotation.y += delta * 0.4
		if plasma_ring_2:
			plasma_ring_2.position.y = 1.55 - sin(scan_time * 0.8) * 0.12
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
	if "current_charging_station" in robot:
		robot.current_charging_station = self
	
	# Disable solid station collider so physics engine NEVER pops robot up onto roof
	if station_collider:
		var col = station_collider.get_node_or_null("CollisionShape3D")
		if col:
			col.set_deferred("disabled", true)
	
	# Instantly and firmly place robot on floor dock pad inside capsule
	var target_dock_pos = global_position + Vector3(0, 0.23, 0)
	robot.global_position = target_dock_pos
	if robot is CharacterBody3D:
		robot.velocity = Vector3.ZERO
	
	# Play high-tech docking animation
	_play_dock_animation(true)
	if SoundManager and SoundManager.has_method("play_pickup"):
		SoundManager.play_pickup()
		
	robot_docked.emit(robot)

func undock_robot(robot: Node3D) -> void:
	if docked_robot != robot:
		return
		
	if "is_on_charging_station" in robot:
		robot.is_on_charging_station = false
	if "current_charging_station" in robot:
		robot.current_charging_station = null
		
	var r = docked_robot
	docked_robot = null
	is_docked = false
	
	# Smoothly step robot OUT in front of the capsule respecting its rotation
	var exit_pos = to_global(Vector3(0, 0.05, 1.45))
	if r is CharacterBody3D:
		r.velocity = Vector3.ZERO
	r.rotation.y = global_rotation.y
	var exit_tween = create_tween()
	exit_tween.tween_property(r, "global_position", exit_pos, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	exit_tween.tween_callback(func():
		if station_collider:
			var col = station_collider.get_node_or_null("CollisionShape3D")
			if col:
				col.set_deferred("disabled", false)
	)
	
	_play_dock_animation(false)
	if SoundManager and SoundManager.has_method("play_drop"):
		SoundManager.play_drop()
		
	robot_undocked.emit(r)

func _play_dock_animation(dock: bool) -> void:
	if anim_tween and anim_tween.is_valid():
		anim_tween.kill()
		
	anim_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if dock:
		# Lower overhead charging contact arm down into capsule
		if charger_arm:
			anim_tween.tween_property(charger_arm, "position:y", 1.80, 0.45)
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
			anim_tween.tween_property(charger_arm, "position:y", 2.45, 0.40).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
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
		charger_arm.position.y = 1.80 if dock else 2.45
	if light_omni:
		light_omni.light_color = Color(0.15, 1.0, 0.50) if dock else Color(0.0, 0.85, 1.0)
		light_omni.light_energy = 3.0 if dock else 1.3
	if light_spot:
		light_spot.light_color = Color(0.20, 1.0, 0.55) if dock else Color(0.0, 0.90, 1.0)
		light_spot.light_energy = 3.8 if dock else 1.6
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

## Updates the decal texture with dynamic digital text
func _update_decal_texture(text_val: String) -> void:
	var w = 512
	var h = 512
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0)) # Transparent base
	
	var col_white = Color(1.0, 1.0, 1.0, 0.96)
	var col_yellow = Color(1.0, 0.78, 0.08, 0.96)
	var col_yellow_fill = Color(1.0, 0.78, 0.08, 0.40)
	
	# Draw dynamic stencil digits
	if text_val.length() == 3: # E.g. "100"
		_draw_stencil_digit(img, text_val[0], 50, 70, 100, 280, 24, col_white)
		_draw_stencil_digit(img, text_val[1], 175, 70, 130, 280, 26, col_white)
		_draw_stencil_digit(img, text_val[2], 330, 70, 130, 280, 26, col_white)
	elif text_val.length() == 2: # E.g. "85"
		_draw_stencil_digit(img, text_val[0], 70, 70, 160, 280, 30, col_white)
		_draw_stencil_digit(img, text_val[1], 280, 70, 160, 280, 30, col_white)
	else:
		_draw_stencil_digit(img, "0", 70, 70, 160, 280, 30, col_white)
		_draw_stencil_digit(img, text_val[0], 280, 70, 160, 280, 30, col_white)
	
	# --- Lower Hazard Frame Bracket [ % ] ---
	_draw_img_rect(img, 50, 390, 410, 14, col_yellow)   # bracket bottom rail
	_draw_img_rect(img, 50, 340, 14, 50, col_yellow)    # left corner hook
	_draw_img_rect(img, 446, 340, 14, 50, col_yellow)   # right corner hook
	_draw_img_rect(img, 90, 420, 330, 44, col_yellow_fill) # lower caution fill plate
	_draw_img_rect(img, 90, 420, 330, 8, col_yellow)    # plate accent line
	
	img.generate_mipmaps()
	var tex = ImageTexture.create_from_image(img)
	if decal_material:
		decal_material.albedo_texture = tex
		decal_material.emission_texture = tex

func _draw_stencil_digit(img: Image, digit: String, x: int, y: int, w: int, h: int, thick: int, col: Color) -> void:
	var top = digit in ["0", "2", "3", "5", "6", "7", "8", "9"]
	var top_left = digit in ["0", "4", "5", "6", "8", "9"]
	var top_right = digit in ["0", "1", "2", "3", "4", "7", "8", "9"]
	var mid = digit in ["2", "3", "4", "5", "6", "8", "9"]
	var bot_left = digit in ["0", "2", "6", "8"]
	var bot_right = digit in ["0", "1", "3", "4", "5", "6", "7", "8", "9"]
	var bot = digit in ["0", "2", "3", "5", "6", "8", "9"]
	
	var half_h = int(h * 0.5)
	
	if top: _draw_img_rect(img, x, y, w, thick, col)
	if top_left: _draw_img_rect(img, x, y, thick, half_h, col)
	if top_right: _draw_img_rect(img, x + w - thick, y, thick, half_h, col)
	if mid: _draw_img_rect(img, x, y + half_h - int(thick * 0.5), w, thick, col)
	if bot_left: _draw_img_rect(img, x, y + half_h, thick, half_h, col)
	if bot_right: _draw_img_rect(img, x + w - thick, y + half_h, thick, half_h, col)
	if bot: _draw_img_rect(img, x, y + h - thick, w, thick, col)

## Procedurally generates sleek clean titanium base plate texture (No yellow stripes)
func _generate_sleek_base_texture() -> ImageTexture:
	var size = 512
	var img = Image.create(size, size, true, Image.FORMAT_RGBA8)
	var col_dark_outer = Color(0.12, 0.14, 0.19, 1.0)
	var col_steel_plate = Color(0.20, 0.24, 0.32, 1.0)
	var col_panel_groove = Color(0.08, 0.09, 0.12, 1.0)
	var col_cyan_glow = Color(0.0, 0.85, 1.0, 0.9)
	var _col_bolt = Color(0.35, 0.40, 0.50, 1.0)
	
	var center = Vector2(size * 0.5, size * 0.5)
	var radius_max = float(size) * 0.48
	var radius_groove_out = float(size) * 0.45
	var radius_plate = float(size) * 0.33
	var radius_pedestal = float(size) * 0.27
	
	for y in range(size):
		for x in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			if dist <= radius_max and dist > radius_groove_out:
				img.set_pixel(x, y, col_dark_outer)
			elif dist <= radius_groove_out and dist > radius_groove_out - 4.0:
				# Outer neon cyan telemetry ring
				img.set_pixel(x, y, col_cyan_glow)
			elif dist <= radius_groove_out - 4.0 and dist >= radius_plate:
				# Clean dark titanium panel plate
				var angle = atan2(pos.y - center.y, pos.x - center.x)
				# 8 radial panel seams
				var seam_phase = fmod(abs(angle) / (PI / 4.0), 1.0)
				if seam_phase < 0.04 or seam_phase > 0.96:
					img.set_pixel(x, y, col_panel_groove)
				else:
					img.set_pixel(x, y, col_steel_plate)
			elif dist < radius_plate and dist >= radius_pedestal:
				# Inner plate step
				if dist <= radius_plate and dist > radius_plate - 3.0:
					img.set_pixel(x, y, col_panel_groove)
				else:
					img.set_pixel(x, y, col_dark_outer)
			elif dist < radius_pedestal:
				img.set_pixel(x, y, col_dark_outer)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _draw_img_rect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	for dy in range(h):
		for dx in range(w):
			var px = x + dx
			var py = y + dy
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(px, py, col)
