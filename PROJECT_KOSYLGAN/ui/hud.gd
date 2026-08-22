class_name HUD
extends CanvasLayer

@onready var atlas_battery_display = %AtlasBatteryDisplay
@onready var cipher_battery_display = %CipherBatteryDisplay

@onready var level_title: Label = %LevelTitle
@onready var message_banner: Label = %MessageBanner
@onready var clue_panel: PanelContainer = %CluePanel
@onready var clue_text: Label = %ClueText
@onready var interact_prompt: Label = %InteractPrompt

var message_timer: SceneTreeTimer = null

func _ready() -> void:
	if atlas_battery_display:
		atlas_battery_display.robot_name = "ATLAS"
		atlas_battery_display.robot_role = "HEAVY LOADER // SHIELD"
		atlas_battery_display.theme_color = Color(0.20, 0.65, 0.95) # Vibrant Cyan-Blue
		atlas_battery_display.set_active(true)
		
	if cipher_battery_display:
		cipher_battery_display.robot_name = "CIPHER"
		cipher_battery_display.robot_role = "INFILTRATOR // HACKER"
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
	message_banner.visible = false

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

func show_banner_message(text: String, duration: float = 2.0) -> void:
	message_banner.text = text
	message_banner.visible = true
	if message_timer:
		message_timer.timeout.disconnect(_hide_banner)
	message_timer = get_tree().create_timer(duration)
	message_timer.timeout.connect(_hide_banner)

func _hide_banner() -> void:
	message_banner.visible = false

func _on_clue_revealed(text: String) -> void:
	clue_text.text = text
	clue_panel.visible = true

func _on_interact_target_changed(target: Node) -> void:
	if target:
		interact_prompt.text = "[E] ВЗАИМОДЕЙСТВИЕ"
		interact_prompt.visible = true
	else:
		interact_prompt.visible = false
