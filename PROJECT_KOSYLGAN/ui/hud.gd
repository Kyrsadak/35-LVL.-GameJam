class_name HUD
extends CanvasLayer

@onready var atlas_battery_display = %AtlasBatteryDisplay
@onready var cipher_battery_display = %CipherBatteryDisplay

@onready var level_title: Label = %LevelTitle
@onready var dialogue_container: PanelContainer = %DialogueContainer
@onready var message_banner: Label = %MessageBanner
@onready var clue_panel: PanelContainer = %CluePanel
@onready var clue_text: Label = %ClueText
@onready var interact_prompt: Label = %InteractPrompt

var active_typing_tween: Tween = null
var default_dialogue_offset_top: float = -140.0

func _ready() -> void:
	if atlas_battery_display:
		atlas_battery_display.robot_name = "ATLAS"
		atlas_battery_display.theme_color = Color(0.20, 0.65, 0.95) # Vibrant Cyan-Blue
		atlas_battery_display.set_active(true)
		
	if cipher_battery_display:
		cipher_battery_display.robot_name = "CIPHER"
		cipher_battery_display.theme_color = Color(0.98, 0.56, 0.16) # Vibrant Amber-Orange
		cipher_battery_display.set_active(false)

	if RobotManager:
		RobotManager.robot_switched.connect(_on_robot_switched)
		RobotManager.hud_message_requested.connect(show_banner_message)
		RobotManager.clue_revealed.connect(_on_clue_revealed)
		
		if RobotManager.atlas:
			if RobotManager.atlas.has_signal("battery_changed"):
				RobotManager.atlas.battery_changed.connect(_on_atlas_battery_changed)
			if RobotManager.atlas.has_signal("charging_state_changed"):
				RobotManager.atlas.charging_state_changed.connect(func(c): if atlas_battery_display: atlas_battery_display.set_charging(c))
			if RobotManager.atlas.has_signal("interact_target_changed"):
				RobotManager.atlas.interact_target_changed.connect(_on_interact_target_changed)
		if RobotManager.cipher:
			if RobotManager.cipher.has_signal("battery_changed"):
				RobotManager.cipher.battery_changed.connect(_on_cipher_battery_changed)
			if RobotManager.cipher.has_signal("charging_state_changed"):
				RobotManager.cipher.charging_state_changed.connect(func(c): if cipher_battery_display: cipher_battery_display.set_charging(c))
			if RobotManager.cipher.has_signal("interact_target_changed"):
				RobotManager.cipher.interact_target_changed.connect(_on_interact_target_changed)
			
	clue_panel.visible = false
	interact_prompt.visible = false
	if dialogue_container:
		dialogue_container.visible = false
		dialogue_container.modulate.a = 0.0
		default_dialogue_offset_top = dialogue_container.offset_top

func set_level_info(level_num: int, title: String, mode_desc: String) -> void:
	level_title.text = "УРОВЕНЬ " + str(level_num) + ": " + title.to_upper() + "\n" + mode_desc

func _on_atlas_battery_changed(current: float, max_val: float) -> void:
	if atlas_battery_display:
		atlas_battery_display.set_battery(current, max_val)

func _on_cipher_battery_changed(current: float, max_val: float) -> void:
	if cipher_battery_display:
		cipher_battery_display.set_battery(current, max_val)

func _on_robot_switched(active_robot: Node) -> void:
	if not active_robot:
		return
	var r_id = active_robot.robot_id if "robot_id" in active_robot else "atlas"
	if atlas_battery_display:
		atlas_battery_display.set_active(r_id == "atlas")
	if cipher_battery_display:
		cipher_battery_display.set_active(r_id == "cipher")

func show_banner_message(text: String, duration: float = 2.8) -> void:
	if not dialogue_container or not message_banner:
		return
		
	# Cancel previous active animations
	if active_typing_tween and active_typing_tween.is_valid():
		active_typing_tween.kill()

	dialogue_container.visible = true
	message_banner.text = text
	message_banner.visible_ratio = 0.0
	
	var total_chars = text.length()
	var char_speed = 0.045
	var type_duration = max(0.65, total_chars * char_speed)
	var is_catgirl = "Weo" in text or "(=^" in text or "CRT-CAT" in text

	# 1. Silky Smooth Panel Fade & Slide Up Entrance
	dialogue_container.modulate.a = 0.0
	dialogue_container.offset_top = default_dialogue_offset_top + 14.0
	dialogue_container.offset_bottom = default_dialogue_offset_top + 14.0 + 68.0
	
	var slide_tween = create_tween().set_parallel(true)
	slide_tween.tween_property(dialogue_container, "modulate:a", 1.0, 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	slide_tween.tween_property(dialogue_container, "offset_top", default_dialogue_offset_top, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	slide_tween.tween_property(dialogue_container, "offset_bottom", default_dialogue_offset_top + 68.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 2. Smooth Typewriter Text Reveal with Gentle Cadence
	active_typing_tween = create_tween()
	var last_blip_char = -1
	active_typing_tween.tween_method(func(ratio: float):
		message_banner.visible_ratio = ratio
		var curr_char_idx = int(ratio * float(total_chars))
		if curr_char_idx != last_blip_char and curr_char_idx % 3 == 0 and curr_char_idx < total_chars:
			last_blip_char = curr_char_idx
			var ch = text[curr_char_idx]
			if ch != " " and SoundManager and SoundManager.has_method("play_dialogue_blip"):
				SoundManager.play_dialogue_blip(is_catgirl)
	, 0.0, 1.0, type_duration).set_trans(Tween.TRANS_LINEAR)

	# 3. Rest on screen, then silky smooth fade & drift exit
	active_typing_tween.tween_interval(duration)
	active_typing_tween.tween_property(dialogue_container, "modulate:a", 0.0, 0.40).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	active_typing_tween.tween_property(dialogue_container, "offset_top", default_dialogue_offset_top + 8.0, 0.40).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	active_typing_tween.tween_callback(func():
		dialogue_container.visible = false
	)

func _on_clue_revealed(text: String) -> void:
	clue_text.text = text
	clue_panel.visible = true

func _on_interact_target_changed(target: Node) -> void:
	if target:
		interact_prompt.text = "[E] ВЗАИМОДЕЙСТВИЕ"
		interact_prompt.visible = true
	else:
		interact_prompt.visible = false
