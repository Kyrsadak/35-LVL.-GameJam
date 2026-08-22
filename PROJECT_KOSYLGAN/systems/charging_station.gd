class_name ChargingStation
extends Area3D

@onready var light: OmniLight3D = $OmniLight3D
@onready var floor_pad: MeshInstance3D = $FloorPad
@onready var back_wall: MeshInstance3D = $BackWall
@onready var holo_screen: MeshInstance3D = $HoloScreen
@onready var charger_arm: Node3D = $ChargerArm
@onready var laser_ring: MeshInstance3D = $ChargerArm/LaserRing
@onready var tube_left: MeshInstance3D = $PillarLeft/EnergyTube
@onready var tube_right: MeshInstance3D = $PillarRight/EnergyTube

var robots_on_station: Array = []
var is_docked: bool = false
var anim_tween: Tween
var scan_time: float = 0.0

var tube_material: StandardMaterial3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_load_textures()
	_update_visuals(false)

func _load_textures() -> void:
	# 1. Floor pad texture
	_apply_tex(floor_pad, "res://assets/textures/tex_charging_capsule_floor.png", true, 0.4)
	
	# 2. Back wall texture
	_apply_tex(back_wall, "res://assets/textures/tex_charging_capsule_wall.png", true, 0.4)
	
	# 3. Holographic Screen texture
	_apply_tex(holo_screen, "res://assets/textures/tex_charging_capsule_screen.png", true, 0.8)
	
	# Tube glowing material
	tube_material = StandardMaterial3D.new()
	tube_material.albedo_color = Color(0.0, 0.9, 1.0, 0.8)
	tube_material.emission_enabled = true
	tube_material.emission = Color(0.0, 0.9, 1.0)
	tube_material.emission_energy_multiplier = 1.0
	if tube_left: tube_left.set_surface_override_material(0, tube_material)
	if tube_right: tube_right.set_surface_override_material(0, tube_material)

func _apply_tex(mesh_node: MeshInstance3D, path: String, is_emissive: bool, emissive_energy: float) -> void:
	if not mesh_node: return
	var global_p = ProjectSettings.globalize_path(path)
	var img = Image.load_from_file(global_p)
	if img:
		var tex = ImageTexture.create_from_image(img)
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.metallic = 0.3
		mat.roughness = 0.5
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		if is_emissive:
			mat.emission_enabled = true
			mat.emission_texture = tex
			mat.emission_energy_multiplier = emissive_energy
		mesh_node.set_surface_override_material(0, mat)

func _process(delta: float) -> void:
	if is_docked:
		scan_time += delta * 4.0
		# Pulsing light & energy
		if light:
			light.light_energy = 2.8 + sin(scan_time * 2.0) * 0.6
		if tube_material:
			tube_material.emission_energy_multiplier = 2.0 + sin(scan_time * 3.0) * 0.8
		if laser_ring:
			laser_ring.position.y = -0.15 + sin(scan_time) * 0.12
	else:
		if light:
			light.light_energy = 1.2
		if tube_material:
			tube_material.emission_energy_multiplier = 0.8

func _on_body_entered(body: Node3D) -> void:
	if "is_on_charging_station" in body:
		if not robots_on_station.has(body):
			robots_on_station.append(body)
			body.is_on_charging_station = true
			
			if robots_on_station.size() == 1:
				_play_dock_animation(true)

func _on_body_exited(body: Node3D) -> void:
	if "is_on_charging_station" in body:
		if robots_on_station.has(body):
			robots_on_station.erase(body)
			body.is_on_charging_station = false
			
			if robots_on_station.size() == 0:
				_play_dock_animation(false)

func _play_dock_animation(dock: bool) -> void:
	is_docked = dock
	
	if anim_tween and anim_tween.is_valid():
		anim_tween.kill()
	
	anim_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if dock:
		# Lower overhead charging clamp down over robot
		if charger_arm:
			anim_tween.tween_property(charger_arm, "position:y", 1.40, 0.45)
		# Light turns to active green power surge
		if light:
			anim_tween.tween_property(light, "light_color", Color(0.2, 1.0, 0.45), 0.3)
		if tube_material:
			tube_material.emission = Color(0.2, 1.0, 0.45)
			tube_material.albedo_color = Color(0.2, 1.0, 0.45, 0.9)
		if laser_ring:
			laser_ring.visible = true
	else:
		# Retract overhead charging clamp up into canopy
		if charger_arm:
			anim_tween.tween_property(charger_arm, "position:y", 2.15, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Light returns to standby calm cyan
		if light:
			anim_tween.tween_property(light, "light_color", Color(0.0, 0.85, 1.0), 0.3)
		if tube_material:
			tube_material.emission = Color(0.0, 0.85, 1.0)
			tube_material.albedo_color = Color(0.0, 0.85, 1.0, 0.8)
		if laser_ring:
			laser_ring.visible = false

func _update_visuals(dock: bool) -> void:
	if charger_arm:
		charger_arm.position.y = 1.40 if dock else 2.15
	if light:
		light.light_color = Color(0.2, 1.0, 0.45) if dock else Color(0.0, 0.85, 1.0)
		light.light_energy = 2.8 if dock else 1.2
	if laser_ring:
		laser_ring.visible = dock
