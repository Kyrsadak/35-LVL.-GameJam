class_name HUD
extends CanvasLayer

@onready var atlas_battery_display = %AtlasBatteryDisplay
@onready var cipher_battery_display = %CipherBatteryDisplay

@onready var level_title: Label = %LevelTitle
@onready var controls_hints: Label = %ControlsHints
@onready var corner_hints_panel: PanelContainer = %CornerHintsPanel
@onready var cat_avatar_button: Button = get_node_or_null("%CatAvatarButton")
@onready var dialogue_container: Control = %DialogueContainer
@onready var dialogue_portrait: Control = %DialoguePortrait
@onready var message_banner: Label = %MessageBanner
@onready var enter_badge: PanelContainer = %EnterBadge
@onready var interact_prompt: Label = %InteractPrompt

var active_typing_tween: Tween = null
var pulse_badge_tween: Tween = null
var default_dialogue_offset_top: float = -170.0

var is_dialogue_open: bool = false
var is_typing_active: bool = false
var current_total_chars: int = 0

func _ready() -> void:
	if atlas_battery_display:
		atlas_battery_display.robot_name = "DAU"
		atlas_battery_display.theme_color = Color(0.91, 0.44, 0.36) # Soft Warm Coral
		atlas_battery_display.set_active(true)
		
	if cipher_battery_display:
		cipher_battery_display.robot_name = "JAM"
		cipher_battery_display.theme_color = Color(0.24, 0.72, 0.47) # Calm Mint Sage
		cipher_battery_display.set_active(false)

	if cat_avatar_button:
		cat_avatar_button.pressed.connect(_on_cat_avatar_pressed)
		cat_avatar_button.mouse_entered.connect(_on_cat_avatar_hover)

	if RobotManager:
		RobotManager.robot_switched.connect(_on_robot_switched)
		RobotManager.hud_message_requested.connect(show_banner_message)
		RobotManager.dialogue_sequence_requested.connect(show_dialogue_sequence)
		RobotManager.clue_revealed.connect(_on_clue_revealed)
		if RobotManager.atlas and RobotManager.atlas.has_signal("interact_target_changed"):
			RobotManager.atlas.interact_target_changed.connect(_on_interact_target_changed)
		if RobotManager.cipher and RobotManager.cipher.has_signal("interact_target_changed"):
			RobotManager.cipher.interact_target_changed.connect(_on_interact_target_changed)

	interact_prompt.visible = false
	if dialogue_container:
		dialogue_container.visible = false
		dialogue_container.modulate.a = 0.0
		default_dialogue_offset_top = dialogue_container.offset_top
		dialogue_container.gui_input.connect(_on_dialogue_gui_input)
	if enter_badge:
		enter_badge.modulate.a = 0.0

var dialogue_queue: Array = []
var current_dialogue_callback: Callable = Callable()

func _on_dialogue_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_handle_dialogue_advance()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_H:
			_on_cat_avatar_pressed()
			get_viewport().set_input_as_handled()
			return

	if not is_dialogue_open or not dialogue_container or not dialogue_container.visible:
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			get_viewport().set_input_as_handled()
			_handle_dialogue_advance()

func _handle_dialogue_advance() -> void:
	if is_typing_active:
		# Skip typing instantly
		if active_typing_tween and active_typing_tween.is_valid():
			active_typing_tween.kill()
		message_banner.visible_characters = current_total_chars
		is_typing_active = false
		if dialogue_portrait:
			dialogue_portrait.set_talking(false)
		_start_badge_pulse()
		if SoundManager and SoundManager.has_method("play_ui_hover"):
			SoundManager.play_ui_hover()
	else:
		# Advance to next dialogue item or close
		if dialogue_queue.size() > 0:
			var next_item = dialogue_queue.pop_front()
			_display_dialogue_item(next_item)
		else:
			_dismiss_dialogue()

func show_dialogue_sequence(sequence: Array, on_completed: Callable = Callable()) -> void:
	if sequence.is_empty():
		if on_completed.is_valid():
			on_completed.call()
		return

	dialogue_queue = sequence.duplicate()
	current_dialogue_callback = on_completed
	var first_item = dialogue_queue.pop_front()
	_display_dialogue_item(first_item)

func show_banner_message(text: String, _duration: float = 0.0) -> void:
	dialogue_queue.clear()
	current_dialogue_callback = Callable()
	_display_dialogue_item({"text": text})

func _display_dialogue_item(item: Variant) -> void:
	if not dialogue_container or not message_banner:
		return
		
	var text = ""
	var forced_speaker = ""
	if item is Dictionary:
		text = item.get("text", "")
		forced_speaker = item.get("speaker", "").to_lower()
	elif item is String:
		text = item

	# Cancel previous active animations
	if active_typing_tween and active_typing_tween.is_valid():
		active_typing_tween.kill()
	if pulse_badge_tween and pulse_badge_tween.is_valid():
		pulse_badge_tween.kill()

	is_dialogue_open = true
	is_typing_active = true
	if RobotManager:
		RobotManager.set_dialogue_active(true)
	dialogue_container.visible = true
	message_banner.text = text
	message_banner.visible_characters = 0
	
	current_total_chars = text.length()
	var char_speed = 0.042 # Crisp readable typing cadence
	var type_duration = max(0.50, current_total_chars * char_speed)
	var is_catgirl = forced_speaker == "catgirl" or "Weo" in text or "(=^" in text or "CRT-CAT" in text or "кошк" in text.to_lower()

	# Set speaker portrait
	var speaker = "catgirl"
	if not forced_speaker.is_empty():
		if forced_speaker in ["dau", "atlas"]:
			speaker = "atlas"
		elif forced_speaker in ["jam", "cipher"]:
			speaker = "cipher"
		else:
			speaker = "catgirl"
	elif is_catgirl:
		speaker = "catgirl"
	elif text.begins_with("[DAU]") or text.begins_with("DAU:") or text.begins_with("[ATLAS]") or text.begins_with("ATLAS:"):
		speaker = "atlas"
	elif text.begins_with("[JAM]") or text.begins_with("JAM:") or text.begins_with("[CIPHER]") or text.begins_with("CIPHER:"):
		speaker = "cipher"
	elif RobotManager and RobotManager.active_robot:
		var r_id = RobotManager.active_robot.robot_id if "robot_id" in RobotManager.active_robot else "atlas"
		speaker = r_id
		
	if dialogue_portrait:
		dialogue_portrait.set_speaker(speaker)
		dialogue_portrait.set_talking(true)

	# 1. Silky Smooth Panel Fade & Slide Up Entrance (if opening fresh)
	if dialogue_container.modulate.a < 0.5:
		dialogue_container.modulate.a = 0.0
		dialogue_container.offset_top = default_dialogue_offset_top + 14.0
		dialogue_container.offset_bottom = default_dialogue_offset_top + 14.0 + 108.0
		if enter_badge:
			enter_badge.modulate.a = 0.0
		
		var slide_tween = create_tween().set_parallel(true)
		slide_tween.tween_property(dialogue_container, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		slide_tween.tween_property(dialogue_container, "offset_top", default_dialogue_offset_top, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		slide_tween.tween_property(dialogue_container, "offset_bottom", default_dialogue_offset_top + 108.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 2. Strict Left-to-Right Typewriter Reveal (visible_characters)
	active_typing_tween = create_tween()
	var last_blip_idx = -1
	active_typing_tween.tween_method(func(val: int):
		message_banner.visible_characters = val
		if val > 0 and val <= current_total_chars and val != last_blip_idx:
			last_blip_idx = val
			if val % 2 == 0: # Play speech blip every 2 characters
				var ch = text[val - 1]
				if ch != " " and SoundManager and SoundManager.has_method("play_dialogue_blip"):
					SoundManager.play_dialogue_blip(is_catgirl)
	, 0, current_total_chars, type_duration).set_trans(Tween.TRANS_LINEAR)

	# When typing finishes, activate the pulsing Enter Badge (NO auto-close!)
	active_typing_tween.tween_callback(func():
		is_typing_active = false
		if dialogue_portrait:
			dialogue_portrait.set_talking(false)
		_start_badge_pulse()
	)

func _start_badge_pulse() -> void:
	if not enter_badge:
		return
	if pulse_badge_tween and pulse_badge_tween.is_valid():
		pulse_badge_tween.kill()
		
	enter_badge.modulate.a = 1.0
	pulse_badge_tween = create_tween().set_loops()
	pulse_badge_tween.tween_property(enter_badge, "scale", Vector2(1.12, 1.12), 0.45).set_trans(Tween.TRANS_SINE)
	pulse_badge_tween.tween_property(enter_badge, "scale", Vector2(1.0, 1.0), 0.45).set_trans(Tween.TRANS_SINE)

func _dismiss_dialogue() -> void:
	if not is_dialogue_open:
		return
	is_dialogue_open = false
	is_typing_active = false
	if RobotManager:
		RobotManager.set_dialogue_active(false)
	if dialogue_portrait:
		dialogue_portrait.set_talking(false)
	
	if SoundManager and SoundManager.has_method("play_ui_click"):
		SoundManager.play_ui_click()
		
	if pulse_badge_tween and pulse_badge_tween.is_valid():
		pulse_badge_tween.kill()

	var exit_tween = create_tween().set_parallel(true)
	exit_tween.tween_property(dialogue_container, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	exit_tween.tween_property(dialogue_container, "offset_top", default_dialogue_offset_top + 8.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	exit_tween.chain().tween_callback(func():
		dialogue_container.visible = false
		if current_dialogue_callback.is_valid():
			var cb = current_dialogue_callback
			current_dialogue_callback = Callable()
			cb.call()
	)

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

	if RobotManager.active_robot and RobotManager.active_robot.has_method("get_best_interactable"):
		var target = RobotManager.active_robot.get_best_interactable()
		_on_interact_target_changed(target)

func set_level_info(level_num: int, title: String, mode_desc: String = "") -> void:
	if level_title:
		level_title.text = "📍 УРОВЕНЬ " + str(level_num) + ": " + title.to_upper()
	if controls_hints and not mode_desc.is_empty():
		controls_hints.text = mode_desc

func _on_robot_switched(active_robot: Node) -> void:
	if not active_robot:
		return
	var r_id = active_robot.robot_id if "robot_id" in active_robot else "atlas"
	if atlas_battery_display:
		atlas_battery_display.set_active(r_id == "atlas")
	if cipher_battery_display:
		cipher_battery_display.set_active(r_id == "cipher")

func _on_clue_revealed(_text: String) -> void:
	pass

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
		elif target.is_in_group("socket_terminal"):
			if "current_state" in target and target.current_state == 1: # BATTERY_INSERTED
				if RobotManager and RobotManager.active_robot == RobotManager.cipher:
					interact_prompt.text = "[E] ЗАПУСТИТЬ ГЕНЕРАТОР"
				else:
					interact_prompt.text = "🔒 НУЖЕН JAM (ЗЕЛЁНЫЙ)"
			elif "current_state" in target and target.current_state == 2: # ACTIVATED
				interact_prompt.text = "⚡ ГЕНЕРАТОР РАБОТАЕТ"
			else:
				if RobotManager and RobotManager.active_robot == RobotManager.atlas and RobotManager.atlas.carried_object != null:
					interact_prompt.text = "[E] ВСТАВИТЬ БАТАРЕЮ"
				else:
					interact_prompt.text = "🔒 ПРИЁМНИК (Нужна батарея)"
		elif target.is_in_group("robocat") or target is PropRoboCatGirl:
			interact_prompt.text = "[E] ПОГОВОРИТЬ С CRT-CAT"
		elif target.is_in_group("key_module") or target.is_in_group("pushable_box") or target.is_in_group("boxes"):
			interact_prompt.text = "[E] ПОДНЯТЬ ПРЕДМЕТ"
		else:
			interact_prompt.text = "[E] ВЗАИМОДЕЙСТВИЕ"
		interact_prompt.visible = true
	else:
		interact_prompt.visible = false

func _on_cat_avatar_hover() -> void:
	if SoundManager and SoundManager.has_method("play_ui_hover"):
		SoundManager.play_ui_hover()

func _on_cat_avatar_pressed() -> void:
	if SoundManager and SoundManager.has_method("play_ui_click"):
		SoundManager.play_ui_click()

	var lvl = RobotManager.current_level_index if RobotManager else 0
	var hint_text = ""
	if lvl == 0 or lvl == 1 and GameManager and GameManager.current_level_index == 0:
		hint_text = "(=^･ω･^=) Мяу! Управляйте роботами на [WASD], переключайтесь на [TAB], а на [Shift] включайте спринт без потери заряда! DAU поднимает тяжести, JAM взламывает код!"
	elif lvl == 1 or lvl == 2:
		hint_text = "(=^･ω･^=) В Бухаре взломайте стартовый терминал через JAM [TAB], заберите батарею в восточном крыле роботом DAU и вставьте в сокет эвакуации на севере!"
	elif lvl == 2 or lvl == 3:
		hint_text = "(=^･ω･^=) В Хиве робот DAU должен расчистить проход от ящиков на восточный склад, достать батарею, а затем поставить один тяжелый ящик на нажимную плиту в ангаре, чтобы запитать терминал выхода для JAM!"
	elif lvl == 3 or lvl == 4:
		hint_text = "(=^･ω･^=) В Самарканде нужно запитать 5-рубильниковый терминал (код 3-1-4-2-5) ящиком на плите у спавна. Затем в западном хранилище заберите батарею и второй ящик, и поставьте его на плиту эвакуации!"
	elif lvl == 4 or lvl == 5:
		hint_text = "(=^･ω･^=) ФИНАЛ В ТАШКЕНТЕ! Запустите Центральный Генератор двумя ядрами: JAM взламывает западное крыло за Зеленым ядром, а DAU расчищает восточный завал за Оранжевым ядром! Запуск Генератора даст вечную энергию!"
	else:
		hint_text = "(=^･ω･^=) Действуйте сообща! DAU поднимает тяжести и сканирует чертежи, а JAM взламывает терминалы и переключает реле!"

	show_banner_message(hint_text, 0.0)
