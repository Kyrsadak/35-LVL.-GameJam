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
		atlas_battery_display.theme_color = Color(0.0, 0.90, 1.0) # Electric Neon Cyan
		atlas_battery_display.set_active(true)
		
	if cipher_battery_display:
		cipher_battery_display.robot_name = "CIPHER"
		cipher_battery_display.theme_color = Color(1.0, 0.60, 0.05) # Electric Cyber Amber
		cipher_battery_display.set_active(false)

	if RobotManager:
		RobotManager.robot_switched.connect(_on_robot_switched)
		RobotManager.hud_message_requested.connect(show_banner_message)
		RobotManager.clue_revealed.connect(_on_clue_revealed)
		if RobotManager.atlas and RobotManager.atlas.has_signal("interact_target_changed"):
			RobotManager.atlas.interact_target_changed.connect(_on_interact_target_changed)
		if RobotManager.cipher and RobotManager.cipher.has_signal("interact_target_changed"):
			RobotManager.cipher.interact_target_changed.connect(_on_interact_target_changed)

	clue_panel.visible = false
	interact_prompt.visible = false
	if dialogue_container:
		dialogue_container.visible = false
		dialogue_container.modulate.a = 0.0
		default_dialogue_offset_top = dialogue_container.offset_top

func _process(_delta: float) -> void:
	# Real-time frame-by-frame polling to guarantee 100% sync with active/inactive robot battery & charging
	if not RobotManager:
		return

	if RobotManager.atlas and atlas_battery_display:
		if "battery" in RobotManager.atlas and "max_battery" in RobotManager.atlas:
			atlas_battery_display.set_battery(RobotManager.atlas.battery, RobotManager.atlas.max_battery)
		if "is_on_charging_station" in RobotManager.atlas:
			atlas_battery_display.set_charging(RobotManager.atlas.is_on_charging_station)

	if RobotManager.cipher and cipher_battery_display:
		if "battery" in RobotManager.cipher and "max_battery" in RobotManager.cipher:
			cipher_battery_display.set_battery(RobotManager.cipher.battery, RobotManager.cipher.max_battery)
		if "is_on_charging_station" in RobotManager.cipher:
			cipher_battery_display.set_charging(RobotManager.cipher.is_on_charging_station)

func set_level_info(level_num: int, title: String, mode_desc: String) -> void:
	level_title.text = "УРОВЕНЬ " + str(level_num) + ": " + title.to_upper() + "\n" + mode_desc

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
	message_banner.visible_characters = 0
	
	var total_chars = text.length()
	var char_speed = 0.046 # Left-to-right steady typing cadence
	var type_duration = max(0.60, total_chars * char_speed)
	var is_catgirl = "Weo" in text or "(=^" in text or "CRT-CAT" in text

	# 1. Silky Smooth Panel Fade & Slide Up Entrance
	dialogue_container.modulate.a = 0.0
	dialogue_container.offset_top = default_dialogue_offset_top + 14.0
	dialogue_container.offset_bottom = default_dialogue_offset_top + 14.0 + 68.0
	
	var slide_tween = create_tween().set_parallel(true)
	slide_tween.tween_property(dialogue_container, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	slide_tween.tween_property(dialogue_container, "offset_top", default_dialogue_offset_top, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	slide_tween.tween_property(dialogue_container, "offset_bottom", default_dialogue_offset_top + 68.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 2. Strict Left-to-Right Typewriter Reveal (visible_characters)
	active_typing_tween = create_tween()
	var last_blip_idx = -1
	active_typing_tween.tween_method(func(val: int):
		message_banner.visible_characters = val
		if val > 0 and val <= total_chars and val != last_blip_idx:
			last_blip_idx = val
			if val % 2 == 0: # Play speech blip every 2 characters
				var ch = text[val - 1]
				if ch != " " and SoundManager and SoundManager.has_method("play_dialogue_blip"):
					SoundManager.play_dialogue_blip(is_catgirl)
	, 0, total_chars, type_duration).set_trans(Tween.TRANS_LINEAR)

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
		if target.is_in_group("charging_station"):
			if "docked_robot" in target and target.docked_robot != null:
				if RobotManager and RobotManager.active_robot == target.docked_robot:
					interact_prompt.text = "[E] ВЫЙТИ ИЗ КАПСУЛЫ"
				else:
					var occ_name = target.docked_robot.robot_display_name if "robot_display_name" in target.docked_robot else "ЗАНЯТО"
					interact_prompt.text = "🔒 КАПСУЛА ЗАНЯТА (" + occ_name + ")"
			else:
				interact_prompt.text = "[E] СТЫКОВКА / ЗАРЯДКА"
		elif target.is_in_group("guide_tablet"):
			interact_prompt.text = "[E] ИЗУЧИТЬ СХЕМУ"
		elif target.is_in_group("terminal"):
			interact_prompt.text = "[E] ВЗЛОМАТЬ ТЕРМИНАЛ"
		elif target.is_in_group("key_module") or target.is_in_group("pushable_box") or target.is_in_group("boxes"):
			interact_prompt.text = "[E] ПОДНЯТЬ ПРЕДМЕТ"
		else:
			interact_prompt.text = "[E] ВЗАИМОДЕЙСТВИЕ"
		interact_prompt.visible = true
	else:
		interact_prompt.visible = false
