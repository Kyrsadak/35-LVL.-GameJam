class_name SwitchPuzzleMinigame
extends CanvasLayer

signal completed(success: bool)

@export var required_sequence: Array[int] = [3, 1, 4, 2, 5]
@export var clue_id: String = "guide_samarkand_1"

var terminal_ref: Node = null
var current_input_index: int = 0
var entered_sequence: Array[int] = []
var is_solved: bool = false
var is_locked: bool = false

@onready var main_panel: PanelContainer = %MainPanel
@onready var hint_label: Label = %HintLabel
@onready var status_label: Label = %StatusLabel
@onready var sequence_display: HBoxContainer = %SequenceDisplay
@onready var switches_container: HBoxContainer = %SwitchesContainer
@onready var close_btn: Button = %CloseBtn

var switch_buttons: Array[Button] = []
var sequence_slots: Array[Label] = []

func setup(p_terminal: Node, seq: Array[int], p_clue_id: String = "") -> void:
	terminal_ref = p_terminal
	if seq.size() > 0:
		required_sequence = seq
	if not p_clue_id.is_empty():
		clue_id = p_clue_id

func _ready() -> void:
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)

	_build_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_on_close_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_5 and not is_locked and not is_solved:
			var switch_num = event.keycode - KEY_0
			_on_switch_clicked(switch_num)
			get_viewport().set_input_as_handled()

func _build_ui() -> void:
	current_input_index = 0
	entered_sequence.clear()
	is_solved = false
	is_locked = false

	# Clue / Blueprint Hint display
	if RobotManager and RobotManager.discovered_clues.has(clue_id):
		hint_label.text = "📋 СХЕМА АТЛАСА: " + RobotManager.discovered_clues[clue_id]
		hint_label.modulate = Color(0.3, 0.95, 0.5)
	else:
		hint_label.text = "⚠️ НЕТ СХЕМЫ! (Изучите планшет силовым роботом DAU)"
		hint_label.modulate = Color(1.0, 0.75, 0.3)

	status_label.text = "ПЕРЕКЛЮЧИТЕ 5 РЕЛЕ В ПРАВИЛЬНОМ ПОРЯДКЕ (КЛИК ИЛИ КЛАВИШИ 1-5)"
	status_label.modulate = Color(0.85, 0.85, 0.9)

	# Build Sequence Slots
	for child in sequence_display.get_children():
		child.queue_free()
	sequence_slots.clear()

	for i in range(required_sequence.size()):
		var slot_panel = PanelContainer.new()
		var slot_style = StyleBoxFlat.new()
		slot_style.bg_color = Color(0.12, 0.15, 0.18, 0.9)
		slot_style.set_corner_radius_all(6)
		slot_style.set_border_width_all(2)
		slot_style.border_color = Color(0.3, 0.4, 0.5, 0.8)
		slot_panel.add_theme_stylebox_override("panel", slot_style)
		slot_panel.custom_minimum_size = Vector2(48, 48)

		var lbl = Label.new()
		lbl.text = "•"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.modulate = Color(0.5, 0.6, 0.7)
		slot_panel.add_child(lbl)

		sequence_display.add_child(slot_panel)
		sequence_slots.append(lbl)

	# Build 5 Switches
	for child in switches_container.get_children():
		child.queue_free()
	switch_buttons.clear()

	for i in range(1, 6):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(90, 130)
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.text = "⚡ РЕЛЕ " + str(i) + "\n\n[ ВЫКЛ ]\n\n[" + str(i) + "]"
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER

		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.15, 0.18, 0.22, 0.95)
		normal_style.set_corner_radius_all(10)
		normal_style.set_border_width_all(2)
		normal_style.border_color = Color(0.35, 0.45, 0.55)
		btn.add_theme_stylebox_override("normal", normal_style)

		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.20, 0.26, 0.32, 0.98)
		hover_style.set_corner_radius_all(10)
		hover_style.set_border_width_all(3)
		hover_style.border_color = Color(0.2, 0.85, 1.0)
		btn.add_theme_stylebox_override("hover", hover_style)

		btn.pressed.connect(_on_switch_clicked.bind(i))
		btn.mouse_entered.connect(_on_switch_hover)
		switches_container.add_child(btn)
		switch_buttons.append(btn)

func _on_switch_hover() -> void:
	if not is_locked and SoundManager and SoundManager.has_method("play_ui_hover"):
		SoundManager.play_ui_hover()

func _on_switch_clicked(switch_num: int) -> void:
	if is_locked or is_solved:
		return

	if SoundManager and SoundManager.has_method("play_ui_click"):
		SoundManager.play_ui_click()

	var expected = required_sequence[current_input_index]

	# Update switch visual state
	var btn = switch_buttons[switch_num - 1]
	btn.text = "⚡ РЕЛЕ " + str(switch_num) + "\n\n[ ВКЛ ]\n\n[" + str(switch_num) + "]"
	var active_style = StyleBoxFlat.new()
	active_style.bg_color = Color(0.12, 0.35, 0.22, 0.95)
	active_style.set_corner_radius_all(10)
	active_style.set_border_width_all(3)
	active_style.border_color = Color(0.25, 0.95, 0.45)
	btn.add_theme_stylebox_override("normal", active_style)

	if switch_num == expected:
		# Correct switch in sequence!
		entered_sequence.append(switch_num)
		if current_input_index < sequence_slots.size():
			sequence_slots[current_input_index].text = str(switch_num)
			sequence_slots[current_input_index].modulate = Color(0.2, 1.0, 0.4)

		current_input_index += 1

		if current_input_index >= required_sequence.size():
			# Solved!
			_handle_success()
	else:
		# Wrong switch -> Trigger error and reset sequence!
		_handle_error(switch_num)

func _handle_success() -> void:
	is_solved = true
	is_locked = true

	status_label.text = "✅ ЭНЕРГОМАТРИЦА СИНХРОНИЗИРОВАНА! ЛАЗЕРНЫЙ БАРЬЕР ОТКЛЮЧЕН."
	status_label.modulate = Color(0.2, 1.0, 0.45)

	if SoundManager and SoundManager.has_method("play_terminal_solved"):
		SoundManager.play_terminal_solved()

	var pulse_tween = create_tween()
	pulse_tween.tween_property(main_panel, "modulate", Color(1.2, 1.2, 1.2), 0.2)
	pulse_tween.tween_property(main_panel, "modulate", Color(1.0, 1.0, 1.0), 0.3)

	await get_tree().create_timer(1.2).timeout
	completed.emit(true)
	queue_free()

func _handle_error(wrong_num: int) -> void:
	is_locked = true
	status_label.text = "❌ ОШИБКА ПОСЛЕДОВАТЕЛЬНОСТИ (ВЫБРАНО " + str(wrong_num) + ")! СБРОС РЕЛЕ..."
	status_label.modulate = Color(1.0, 0.3, 0.3)

	if SoundManager and SoundManager.has_method("play_ui_error"):
		SoundManager.play_ui_error()

	# Shake animation
	var shake_tween = create_tween()
	var orig_pos = main_panel.position
	for i in range(3):
		shake_tween.tween_property(main_panel, "position", orig_pos + Vector2(10.0 if i % 2 == 0 else -10.0, 0), 0.06)
	shake_tween.tween_property(main_panel, "position", orig_pos, 0.06)

	await get_tree().create_timer(0.8).timeout
	_reset_switches()

func _reset_switches() -> void:
	current_input_index = 0
	entered_sequence.clear()
	is_locked = false

	status_label.text = "ПОВТОРИТЕ ВВОД: ПЕРЕКЛЮЧИТЕ 5 РЕЛЕ В ПРАВИЛЬНОМ ПОРЯДКЕ"
	status_label.modulate = Color(0.85, 0.85, 0.9)

	for i in range(sequence_slots.size()):
		sequence_slots[i].text = "•"
		sequence_slots[i].modulate = Color(0.5, 0.6, 0.7)

	for i in range(switch_buttons.size()):
		var btn = switch_buttons[i]
		btn.text = "⚡ РЕЛЕ " + str(i + 1) + "\n\n[ ВЫКЛ ]\n\n[" + str(i + 1) + "]"
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.15, 0.18, 0.22, 0.95)
		normal_style.set_corner_radius_all(10)
		normal_style.set_border_width_all(2)
		normal_style.border_color = Color(0.35, 0.45, 0.55)
		btn.add_theme_stylebox_override("normal", normal_style)

func _on_close_pressed() -> void:
	if SoundManager and SoundManager.has_method("play_ui_click"):
		SoundManager.play_ui_click()
	completed.emit(false)
	queue_free()
