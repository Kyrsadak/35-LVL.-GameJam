class_name SocketTerminal
extends Area3D

## Sci-Fi Power Receiver Dock (Приёмник Батареи)
## Two-Stage Cooperative Objective:
## 1. ATLAS carries and inserts the D-Cell Battery into the socket.
## 2. CIPHER approaches the console and activates the generator circuit.

enum TerminalState {
	AWAITING_BATTERY,
	BATTERY_INSERTED,
	ACTIVATED
}

var current_state: int = TerminalState.AWAITING_BATTERY

@onready var socket_marker: Node3D = $SocketMarker
@onready var light: OmniLight3D = $OmniLight3D
@onready var front_screen: MeshInstance3D = $FrontScreen
@onready var top_deck: MeshInstance3D = $TopDeck
@onready var glow_ring: MeshInstance3D = $GlowGuideRing
@onready var conduit_l: MeshInstance3D = $ConduitL
@onready var conduit_r: MeshInstance3D = $ConduitR
@onready var clamp_l: MeshInstance3D = $ClampLeft
@onready var clamp_r: MeshInstance3D = $ClampRight

var docked_battery: Node3D = null
var time_passed: float = 0.0

func _ready() -> void:
	add_to_group("socket_terminal")
	add_to_group("interactable")

	# 1. Apply Front Screen Texture
	if front_screen:
		var path_f = "res://assets/textures/tex_receiver_front.png"
		var global_f = ProjectSettings.globalize_path(path_f)
		var img_f = Image.load_from_file(global_f)
		if img_f:
			img_f.generate_mipmaps()
			var tex_f = ImageTexture.create_from_image(img_f)
			var mat_f = StandardMaterial3D.new()
			mat_f.albedo_texture = tex_f
			mat_f.emission_enabled = true
			mat_f.emission_texture = tex_f
			mat_f.emission_energy_multiplier = 0.6
			mat_f.metallic = 0.4
			mat_f.roughness = 0.35
			mat_f.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			front_screen.set_surface_override_material(0, mat_f)

	# 2. Apply Top Deck Texture
	if top_deck:
		var path_t = "res://assets/textures/tex_receiver_top.png"
		var global_t = ProjectSettings.globalize_path(path_t)
		var img_t = Image.load_from_file(global_t)
		if img_t:
			img_t.generate_mipmaps()
			var tex_t = ImageTexture.create_from_image(img_t)
			var mat_t = StandardMaterial3D.new()
			mat_t.albedo_texture = tex_t
			mat_t.metallic = 0.6
			mat_t.roughness = 0.4
			mat_t.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			top_deck.set_surface_override_material(0, mat_t)

func _process(delta: float) -> void:
	time_passed += delta
	match current_state:
		TerminalState.AWAITING_BATTERY:
			# Pulsing orange beacon
			var pulse = 0.6 + sin(time_passed * 3.5) * 0.4
			if light:
				light.light_color = Color(1.0, 0.72, 0.2)
				light.light_energy = pulse * 1.2
		TerminalState.BATTERY_INSERTED:
			# Steady high-voltage cyan / blue glow awaiting activation
			var pulse = 0.85 + sin(time_passed * 5.0) * 0.25
			if light:
				light.light_color = Color(0.1, 0.75, 1.0)
				light.light_energy = pulse * 1.5
		TerminalState.ACTIVATED:
			# High-power emerald surge
			if light:
				light.light_color = Color(0.1, 1.0, 0.4)
				light.light_energy = 2.4

## Stage 1: ATLAS inserts the D-Cell Battery into the socket dock
func insert_module(battery: Node3D) -> void:
	if current_state != TerminalState.AWAITING_BATTERY or not battery:
		return

	current_state = TerminalState.BATTERY_INSERTED
	docked_battery = battery

	if "is_carried" in battery:
		battery.is_carried = false

	# Reparent battery cleanly into the receiver dock socket
	if battery.get_parent():
		battery.get_parent().remove_child(battery)
	socket_marker.add_child(battery)
	
	# Animate battery sliding securely down into the socket aperture
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(battery, "position", Vector3(0, -0.05, 0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(battery, "rotation", Vector3.ZERO, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Clamps lock in
	if clamp_l and clamp_r:
		tween.tween_property(clamp_l, "position:x", -0.36, 0.35)
		tween.tween_property(clamp_r, "position:x", 0.36, 0.35)

	if SoundManager:
		SoundManager.play_drop()

	# Guide the player to switch to Cipher and activate the generator
	if RobotManager:
		RobotManager.show_message("[РОБО-КОШКА]: (=^･ω･^=) Мяу! Батарея на месте! Но цепь обесточена — активировать генератор может только инженер CIPHER (Зелёный робот)!", 4.5)

## Stage 2: CIPHER approaches the console and activates the circuit
func activate_generator(cipher_robot: Node3D) -> void:
	if current_state == TerminalState.ACTIVATED:
		return

	if current_state == TerminalState.AWAITING_BATTERY:
		if RobotManager:
			RobotManager.show_message("[РОБО-КОШКА]: (=^･ω･^=) В приёмнике нет батареи! Сначала переключитесь на ATLAS и вставьте энергоблок.", 3.5)
		return

	# Perform activation!
	current_state = TerminalState.ACTIVATED

	if cipher_robot and cipher_robot.has_method("play_hack_animation"):
		cipher_robot.play_hack_animation()

	# Visual power surge on conduits and guide ring
	var tween = create_tween()
	if light:
		tween.tween_property(light, "light_energy", 3.2, 0.2).set_trans(Tween.TRANS_BOUNCE)
		tween.tween_property(light, "light_energy", 2.0, 0.5)

	if glow_ring:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.1, 1.0, 0.4)
		mat.emission_enabled = true
		mat.emission = Color(0.1, 1.0, 0.4)
		mat.emission_energy_multiplier = 2.0
		glow_ring.set_surface_override_material(0, mat)

	if conduit_l and conduit_r:
		var mat_c = StandardMaterial3D.new()
		mat_c.albedo_color = Color(0.1, 1.0, 0.5)
		mat_c.emission_enabled = true
		mat_c.emission = Color(0.1, 1.0, 0.5)
		mat_c.emission_energy_multiplier = 1.8
		conduit_l.set_surface_override_material(0, mat_c)
		conduit_r.set_surface_override_material(0, mat_c)

	if SoundManager:
		SoundManager.play_hack_success()

	if RobotManager:
		RobotManager.show_message("⚡ ГЕНЕРАТОР ЗАПУЩЕН! Питание базы полностью восстановлено!")
		# Small delay for player to appreciate the victory before transitioning
		var timer = get_tree().create_timer(1.2)
		timer.timeout.connect(func():
			RobotManager.complete_level()
		)
