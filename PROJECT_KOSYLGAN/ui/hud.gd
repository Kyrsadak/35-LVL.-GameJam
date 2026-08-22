class_name HUD
extends CanvasLayer

@onready var atlas_battery_display: BatteryDisplay = %AtlasBatteryDisplay
@onready var cipher_battery_display: BatteryDisplay = %CipherBatteryDisplay

@onready var level_title: Label = %LevelTitle
@onready var message_banner: Label = %MessageBanner
@onready var clue_panel: PanelContainer = %CluePanel
@onready var clue_text: Label = %ClueText
@onready var interact_prompt: Label = %InteractPrompt

var message_timer: SceneTreeTimer = null

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

	clue_panel.visible = false
	interact_prompt.visible = false
	message_banner.visible = false

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
