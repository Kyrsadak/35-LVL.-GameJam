class_name WireCuttingMinigame
extends CanvasLayer

signal completed(success: bool)

@export var wires_count: int = 3
@export var solution_wire_indices: Array[int] = [0] # indices of correct wires in order or set
@export var require_exact_order: bool = false
@export var clue_id: String = ""

var terminal_ref: Node = null
var current_cut_step: int = 0
var cut_wires: Array[int] = []

# Among Us authentic color palette
var wire_palette = [
	{"name": "КРАСНЫЙ", "color": Color(0.95, 0.22, 0.22), "dark": Color(0.65, 0.12, 0.12)},
	{"name": "СИНИЙ", "color": Color(0.20, 0.55, 0.98), "dark": Color(0.12, 0.35, 0.68)},
	{"name": "ЖЁЛТЫЙ", "color": Color(0.98, 0.85, 0.15), "dark": Color(0.68, 0.58, 0.08)},
	{"name": "РОЗОВЫЙ", "color": Color(0.95, 0.35, 0.75), "dark": Color(0.65, 0.18, 0.48)},
	{"name": "ЗЕЛЁНЫЙ", "color": Color(0.22, 0.88, 0.38), "dark": Color(0.12, 0.58, 0.22)},
	{"name": "ОРАНЖЕВЫЙ", "color": Color(0.98, 0.55, 0.15), "dark": Color(0.68, 0.35, 0.08)}
]

@onready var wires_container: VBoxContainer = %WiresContainer
@onready var status_label: Label = %StatusLabel
@onready var hint_label: Label = %HintLabel
@onready var close_btn: Button = %CloseBtn
@onready var panel_led: ColorRect = %PanelLED
@onready var panel_led_label: Label = %PanelLEDLabel

func setup(p_terminal: Node, count: int, solution: Array[int], p_clue_id: String = "", order_required: bool = false) -> void:
	terminal_ref = p_terminal
	wires_count = clamp(count, 3, 6)
	solution_wire_indices = solution
	clue_id = p_clue_id
	require_exact_order = order_required

func _ready() -> void:
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
	_build_ui()

func _build_ui() -> void:
	cut_wires.clear()
	current_cut_step = 0
	
	if panel_led:
		panel_led.color = Color(0.9, 0.2, 0.2)
	if panel_led_label:
		panel_led_label.text = "⚡ ПИТАНИЕ АКТИВНО"

	for child in wires_container.get_children():
		child.queue_free()

	# Display hint if discovered
	if RobotManager and RobotManager.discovered_clues.has(clue_id):
		hint_label.text = "📋 ТЕХ. СХЕМА: " + RobotManager.discovered_clues[clue_id]
		hint_label.modulate = Color(0.3, 0.95, 0.5)
	else:
		hint_label.text = "⚠️ СХЕМА НЕ НАЙДЕНА! (Найдите планшет роботом ATLAS)"
		hint_label.modulate = Color(1.0, 0.75, 0.3)

	status_label.text = "НАЖМИТЕ НА ПРОВОД ИЛИ КНОПКУ, ЧТОБЫ ПЕРЕРЕЗАТЬ ЕГО"
	status_label.modulate = Color(0.85, 0.85, 0.9)

	for i in range(wires_count):
		var p_info = wire_palette[i % wire_palette.size()]
		var row = _create_among_us_wire_row(i, p_info)
		wires_container.add_child(row)

func _create_among_us_wire_row(idx: int, p_info: Dictionary) -> Control:
	var row = PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 68)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.16, 0.20, 0.9)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.24, 0.28, 0.35, 0.7)
	style.content_margin_left = 12
	style.content_margin_right = 12
	row.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.theme_override_constants.separation = 16
	row.add_child(hbox)

	# 1. Left Contact Port (Among Us pin)
	var left_pin = Panel.new()
	left_pin.custom_minimum_size = Vector2(28, 42)
	var left_pin_style = StyleBoxFlat.new()
	left_pin_style.bg_color = p_info["color"]
	left_pin_style.border_width_left = 3
	left_pin_style.border_width_top = 3
	left_pin_style.border_width_bottom = 3
	left_pin_style.border_width_right = 1
	left_pin_style.border_color = Color(0.9, 0.9, 0.9, 0.9)
	left_pin_style.corner_radius_top_left = 4
	left_pin_style.corner_radius_bottom_left = 4
	left_pin.add_theme_stylebox_override("panel", left_pin_style)
	hbox.add_child(left_pin)

	# 2. Wire Label
	var label = Label.new()
	label.text = "#" + str(idx + 1) + " " + p_info["name"]
	label.custom_minimum_size = Vector2(160, 0)
	label.add_theme_color_override("font_color", p_info["color"])
	label.add_theme_font_size_override("font_size", 17)
	hbox.add_child(label)

	# 3. Among Us Wire Graphic (Left half + Spark gap + Right half)
	var wire_visual = HBoxContainer.new()
	wire_visual.custom_minimum_size = Vector2(240, 24)
	wire_visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wire_visual.alignment = BoxContainer.ALIGNMENT_CENTER

	var wire_left = ColorRect.new()
	wire_left.name = "WireLeft"
	wire_left.custom_minimum_size = Vector2(110, 16)
	wire_left.color = p_info["color"]
	wire_left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wire_visual.add_child(wire_left)

	var spark_icon = Label.new()
	spark_icon.name = "SparkIcon"
	spark_icon.text = ""
	spark_icon.custom_minimum_size = Vector2(24, 0)
	spark_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spark_icon.add_theme_font_size_override("font_size", 16)
	wire_visual.add_child(spark_icon)

	var wire_right = ColorRect.new()
	wire_right.name = "WireRight"
	wire_right.custom_minimum_size = Vector2(110, 16)
	wire_right.color = p_info["color"]
	wire_right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wire_visual.add_child(wire_right)

	hbox.add_child(wire_visual)

	# 4. Cut Button with Scissors
	var cut_btn = Button.new()
	cut_btn.text = "✂️ РЕЗАТЬ"
	cut_btn.custom_minimum_size = Vector2(130, 42)
	cut_btn.theme_override_font_sizes.font_size = 15
	hbox.add_child(cut_btn)

	# 5. Right Contact Port + LED Light
	var right_box = HBoxContainer.new()
	right_box.alignment = BoxContainer.ALIGNMENT_CENTER
	right_box.theme_override_constants.separation = 8

	var led = ColorRect.new()
	led.name = "Led"
	led.custom_minimum_size = Vector2(14, 14)
	led.color = Color(1.0, 0.25, 0.25) # Red by default (active)
	led.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right_box.add_child(led)

	var right_pin = Panel.new()
	right_pin.custom_minimum_size = Vector2(28, 42)
	var right_pin_style = StyleBoxFlat.new()
	right_pin_style.bg_color = p_info["color"]
	right_pin_style.border_width_right = 3
	right_pin_style.border_width_top = 3
	right_pin_style.border_width_bottom = 3
	right_pin_style.border_width_left = 1
	right_pin_style.border_color = Color(0.9, 0.9, 0.9, 0.9)
	right_pin_style.corner_radius_top_right = 4
	right_pin_style.corner_radius_bottom_right = 4
	right_pin.add_theme_stylebox_override("panel", right_pin_style)
	right_box.add_child(right_pin)

	hbox.add_child(right_box)

	cut_btn.pressed.connect(_on_wire_cut.bind(idx, wire_left, wire_right, spark_icon, led, cut_btn))
	return row

func _on_wire_cut(index: int, wire_left: ColorRect, wire_right: ColorRect, spark: Label, led: ColorRect, cut_btn: Button) -> void:
	if cut_wires.has(index):
		return
	
	cut_wires.append(index)
	cut_btn.disabled = true
	cut_btn.text = "⚡ ПЕРЕРЕЗАН"

	# Visual cut in Among Us style: wire disconnects and leaves a severed gap
	wire_left.custom_minimum_size.x = 45
	wire_right.custom_minimum_size.x = 45
	wire_left.color = Color(0.4, 0.4, 0.4, 0.6)
	wire_right.color = Color(0.4, 0.4, 0.4, 0.6)
	spark.text = "✂️"

	# Verify validity
	var is_correct = false
	if require_exact_order:
		if current_cut_step < solution_wire_indices.size() and solution_wire_indices[current_cut_step] == index:
			is_correct = true
			current_cut_step += 1
	else:
		if solution_wire_indices.has(index):
			is_correct = true

	if is_correct:
		led.color = Color(0.2, 1.0, 0.4) # Turn green
		status_label.text = "⚡ ПРОВОД #" + str(index + 1) + " УСПЕШНО ОБЕСТОЧЕН!"
		status_label.modulate = Color(0.25, 1.0, 0.45)

		# Check if all required wires cut
		var all_done = true
		for req in solution_wire_indices:
			if not cut_wires.has(req):
				all_done = false
				break
		
		if all_done:
			_on_success()
	else:
		led.color = Color(1.0, 0.0, 0.0) # Flash bright red
		spark.text = "💥"
		_on_failure()

func _on_success() -> void:
	if panel_led:
		panel_led.color = Color(0.2, 1.0, 0.4)
	if panel_led_label:
		panel_led_label.text = "🟢 ЦЕПЬ ОБЕСТОЧЕНА! БАРЬЕР ОТКЛЮЧЕН"
	
	status_label.text = "✅ ДОСТУП РАЗРЕШЁН! ЛАЗЕРНЫЙ БАРЬЕР ДЕАКТИВИРОВАН!"
	status_label.modulate = Color(0.2, 1.0, 0.4)
	
	for child in wires_container.get_children():
		var btn = child.find_child("Button", true, false)
		if btn:
			btn.disabled = true

	get_tree().create_timer(1.2).timeout.connect(func():
		completed.emit(true)
		queue_free()
	)

func _on_failure() -> void:
	status_label.text = "❌ ОШИБКА! КОРОТКОЕ ЗАМЫКАНИЕ! (-20% БАТАРЕИ)"
	status_label.modulate = Color(1.0, 0.2, 0.2)

	# Deduct penalty from Cipher
	if RobotManager and RobotManager.cipher:
		RobotManager.cipher.battery = max(0.0, RobotManager.cipher.battery - 20.0)
		RobotManager.cipher.battery_changed.emit(RobotManager.cipher.battery, RobotManager.cipher.max_battery)

	# Reset after delay
	get_tree().create_timer(1.4).timeout.connect(_build_ui)

func _on_close_pressed() -> void:
	completed.emit(false)
	queue_free()
