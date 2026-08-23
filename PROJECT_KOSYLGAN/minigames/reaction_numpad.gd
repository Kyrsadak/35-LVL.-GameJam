class_name ReactionNumpadMinigame
extends CanvasLayer

signal completed(success: bool)

@export var sequence_length: int = 9
@export var time_limit_per_digit: float = 1.00
@export var clue_id: String = "guide_khiva_spawn"

var terminal_ref: Node = null
var target_sequence: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9]
var current_step_index: int = 0
var current_target_num: int = 1
var remaining_time: float = 1.00
var is_active: bool = false
var is_solved: bool = false
var is_locked: bool = false

@onready var main_panel: PanelContainer = %MainPanel
@onready var hint_label: Label = %HintLabel
@onready var status_label: Label = %StatusLabel
@onready var time_bar: ProgressBar = %TimeBar
@onready var step_indicators_container: HBoxContainer = %StepIndicators
@onready var grid_container: GridContainer = %GridContainer
@onready var close_btn: Button = %CloseBtn

var num_buttons: Dictionary = {} # int -> Button
var indicator_labels: Array[Label] = []

func setup(p_terminal: Node, p_clue_id: String = "", p_time_limit: float = 1.00) -> void:
	terminal_ref = p_terminal
	if not p_clue_id.is_empty():
		clue_id = p_clue_id
	if p_time_limit > 0.0:
		time_limit_per_digit = p_time_limit

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if RobotManager:
		RobotManager.level_failed.connect(_on_level_failed)
		if RobotManager.is_game_over:
			queue_free()
			return

	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)

	_build_ui()
	_start_game()

func _on_level_failed(_reason: String = "") -> void:
	is_active = false
	is_locked = true
	queue_free()

func _build_ui() -> void:
	# Clue / Blueprint Hint display
	if hint_label:
		if RobotManager and RobotManager.discovered_clues.has(clue_id):
			hint_label.text = "📋 СХЕМА DAU: " + RobotManager.discovered_clues[clue_id]
			hint_label.modulate = Color(0.3, 0.95, 0.5)
		else:
			hint_label.text = "⚠️ НЕТ СХЕМЫ! (Изучите планшет силовым роботом DAU)"
			hint_label.modulate = Color(1.0, 0.75, 0.3)

	# Build 9 Progress Indicators
	if step_indicators_container:
		for child in step_indicators_container.get_children():
			child.queue_free()
		indicator_labels.clear()

		for i in range(sequence_length):
			var slot = Label.new()
			slot.text = str(i + 1)
			slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			slot.custom_minimum_size = Vector2(36, 36)
			
			var sb = StyleBoxFlat.new()
			sb.bg_color = Color(0.12, 0.16, 0.22, 0.9)
			sb.border_width_left = 2
			sb.border_width_top = 2
			sb.border_width_right = 2
			sb.border_width_bottom = 2
			sb.border_color = Color(0.3, 0.4, 0.55, 0.8)
			sb.corner_radius_top_left = 6
			sb.corner_radius_top_right = 6
			sb.corner_radius_bottom_right = 6
			sb.corner_radius_bottom_left = 6
			slot.add_theme_stylebox_override("normal", sb)
			slot.add_theme_font_size_override("font_size", 14)
			slot.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))

			step_indicators_container.add_child(slot)
			indicator_labels.append(slot)

	# Build 3x3 Grid Buttons (1 to 9)
	if grid_container:
		for child in grid_container.get_children():
			child.queue_free()
		num_buttons.clear()

		for num in range(1, 10):
			var btn = Button.new()
			btn.text = str(num)
			btn.custom_minimum_size = Vector2(80, 80)
			btn.add_theme_font_size_override("font_size", 28)
			btn.focus_mode = Control.FOCUS_NONE
			
			_apply_button_style(btn, false)
			btn.pressed.connect(_on_digit_pressed.bind(num))

			grid_container.add_child(btn)
			num_buttons[num] = btn

func _apply_button_style(btn: Button, is_highlighted: bool, is_success: bool = false, is_error: bool = false) -> void:
	var sb = StyleBoxFlat.new()
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_right = 10
	sb.corner_radius_bottom_left = 10
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3

	if is_error:
		sb.bg_color = Color(0.6, 0.1, 0.1, 0.95)
		sb.border_color = Color(1.0, 0.2, 0.2, 1.0)
		btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.9))
	elif is_success:
		sb.bg_color = Color(0.1, 0.5, 0.2, 0.95)
		sb.border_color = Color(0.3, 1.0, 0.5, 1.0)
		btn.add_theme_color_override("font_color", Color(0.9, 1.0, 0.9))
	elif is_highlighted:
		sb.bg_color = Color(0.85, 0.55, 0.1, 0.95)
		sb.border_color = Color(1.0, 0.9, 0.2, 1.0)
		btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	else:
		sb.bg_color = Color(0.1, 0.14, 0.2, 0.9)
		sb.border_color = Color(0.2, 0.35, 0.5, 0.8)
		btn.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))

	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)

func _start_game() -> void:
	target_sequence = [1, 2, 3, 4, 5, 6, 7, 8, 9]
	target_sequence.shuffle()
	
	current_step_index = 0
	is_active = true
	is_solved = false
	is_locked = false

	_update_indicators()
	_activate_step(0)

func _activate_step(step_idx: int) -> void:
	if step_idx >= target_sequence.size():
		_handle_victory()
		return

	current_step_index = step_idx
	current_target_num = target_sequence[step_idx]
	remaining_time = time_limit_per_digit

	if status_label:
		status_label.text = "⚡ НАЖМИТЕ КОНТАКТ [%d]! (Осталось: %.2f сек)" % [current_target_num, remaining_time]
		status_label.modulate = Color(0.3, 0.9, 1.0)

	# Highlight only the target button
	for num in num_buttons.keys():
		var btn = num_buttons[num]
		_apply_button_style(btn, num == current_target_num)

	if SoundManager and SoundManager.has_method("play_ui_hover"):
		SoundManager.play_ui_hover()

func _process(delta: float) -> void:
	if not is_active or is_locked or is_solved:
		return

	if RobotManager and RobotManager.is_game_over:
		is_active = false
		is_locked = true
		queue_free()
		return

	remaining_time -= delta
	if time_bar:
		time_bar.max_value = time_limit_per_digit
		time_bar.value = max(0.0, remaining_time)

	if status_label:
		status_label.text = "⚡ НАЖМИТЕ КОНТАКТ [%d]! (%.2f сек)" % [current_target_num, max(0.0, remaining_time)]
		if remaining_time < 0.35:
			status_label.modulate = Color(1.0, 0.3, 0.3)
		else:
			status_label.modulate = Color(1.0, 0.85, 0.2)

	if remaining_time <= 0.0:
		_handle_timeout()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_on_close_pressed()
			get_viewport().set_input_as_handled()
			return

		# Check number keys 1-9 (top row or numpad)
		var pressed_digit = -1
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			pressed_digit = event.keycode - KEY_0
		elif event.keycode >= KEY_KP_1 and event.keycode <= KEY_KP_9:
			pressed_digit = event.keycode - KEY_KP_1 + 1

		if pressed_digit >= 1 and pressed_digit <= 9:
			get_viewport().set_input_as_handled()
			_on_digit_pressed(pressed_digit)

func _on_digit_pressed(digit: int) -> void:
	if not is_active or is_locked or is_solved or (RobotManager and RobotManager.is_game_over):
		return

	if digit == current_target_num:
		_handle_correct_hit(digit)
	else:
		_handle_wrong_hit(digit)

func _handle_correct_hit(digit: int) -> void:
	var btn = num_buttons.get(digit)
	if btn:
		_apply_button_style(btn, false, true, false)

	if SoundManager and SoundManager.has_method("play_button_click"):
		SoundManager.play_button_click()

	current_step_index += 1
	_update_indicators()

	if current_step_index >= target_sequence.size():
		_handle_victory()
	else:
		_activate_step(current_step_index)

func _handle_wrong_hit(digit: int) -> void:
	is_locked = true
	var btn = num_buttons.get(digit)
	if btn:
		_apply_button_style(btn, false, false, true)

	if SoundManager and SoundManager.has_method("play_spark_error"):
		SoundManager.play_spark_error()

	if status_label:
		status_label.text = "❌ НЕВЕРНЫЙ КОНТАКТ! (Нужен был %d) Перезапуск..." % current_target_num
		status_label.modulate = Color(1.0, 0.2, 0.2)

	_shake_panel()
	get_tree().create_timer(0.6).timeout.connect(func():
		if is_instance_valid(self) and not is_solved and (not RobotManager or not RobotManager.is_game_over):
			_start_game()
	)

func _handle_timeout() -> void:
	is_locked = true
	var btn = num_buttons.get(current_target_num)
	if btn:
		_apply_button_style(btn, false, false, true)

	if SoundManager and SoundManager.has_method("play_spark_error"):
		SoundManager.play_spark_error()

	if status_label:
		status_label.text = "⏱️ ВРЕМЯ ВЫШЛО (> %.2f сек)! Перезапуск калибровки..." % time_limit_per_digit
		status_label.modulate = Color(1.0, 0.2, 0.2)

	_shake_panel()
	get_tree().create_timer(0.6).timeout.connect(func():
		if is_instance_valid(self) and not is_solved and (not RobotManager or not RobotManager.is_game_over):
			_start_game()
	)

func _update_indicators() -> void:
	for i in range(indicator_labels.size()):
		var slot = indicator_labels[i]
		var sb = slot.get_theme_stylebox("normal") as StyleBoxFlat
		if not sb:
			continue
		if i < current_step_index:
			# Completed step
			sb.bg_color = Color(0.15, 0.75, 0.35, 0.95)
			sb.border_color = Color(0.3, 1.0, 0.5, 1.0)
			slot.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		elif i == current_step_index:
			# Current active step
			sb.bg_color = Color(0.85, 0.55, 0.1, 0.95)
			sb.border_color = Color(1.0, 0.9, 0.2, 1.0)
			slot.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		else:
			# Pending step
			sb.bg_color = Color(0.12, 0.16, 0.22, 0.9)
			sb.border_color = Color(0.3, 0.4, 0.55, 0.8)
			slot.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))

func _handle_victory() -> void:
	is_solved = true
	is_active = false
	is_locked = true

	for num in num_buttons.keys():
		var btn = num_buttons[num]
		_apply_button_style(btn, false, true, false)

	if status_label:
		status_label.text = "🔓 9/9 КОНТАКТОВ СИНХРОНИЗИРОВАНО! ШЛЮЗ ХИВЫ ОТКРЫТ!"
		status_label.modulate = Color(0.3, 1.0, 0.5)

	if SoundManager and SoundManager.has_method("play_success"):
		SoundManager.play_success()

	get_tree().create_timer(1.2).timeout.connect(func():
		completed.emit(true)
		queue_free()
	)

func _shake_panel() -> void:
	if not main_panel:
		return
	var orig_x = main_panel.position.x
	var tween = create_tween()
	tween.tween_property(main_panel, "position:x", orig_x + 12.0, 0.05)
	tween.tween_property(main_panel, "position:x", orig_x - 12.0, 0.05)
	tween.tween_property(main_panel, "position:x", orig_x + 8.0, 0.05)
	tween.tween_property(main_panel, "position:x", orig_x - 8.0, 0.05)
	tween.tween_property(main_panel, "position:x", orig_x, 0.05)

func _on_close_pressed() -> void:
	if SoundManager and SoundManager.has_method("play_ui_click"):
		SoundManager.play_ui_click()
	completed.emit(false)
	queue_free()
