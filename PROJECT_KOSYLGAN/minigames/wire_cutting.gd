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

# Wire color definitions: Name, Color
var wire_palette = [
	{"name": "КРАСНЫЙ", "color": Color(1.0, 0.2, 0.2)},
	{"name": "СИНИЙ", "color": Color(0.2, 0.5, 1.0)},
	{"name": "ЗЕЛЁНЫЙ", "color": Color(0.2, 0.9, 0.3)},
	{"name": "ЖЁЛТЫЙ", "color": Color(1.0, 0.85, 0.1)},
	{"name": "ОРАНЖЕВЫЙ", "color": Color(1.0, 0.5, 0.1)},
	{"name": "ФИОЛЕТОВЫЙ", "color": Color(0.8, 0.2, 1.0)}
]

@onready var wires_container: VBoxContainer = %WiresContainer
@onready var status_label: Label = %StatusLabel
@onready var hint_label: Label = %HintLabel
@onready var close_btn: Button = %CloseBtn

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
	
	for child in wires_container.get_children():
		child.queue_free()

	# Display hint if discovered
	if RobotManager and RobotManager.discovered_clues.has(clue_id):
		hint_label.text = "📋 СХЕМА: " + RobotManager.discovered_clues[clue_id]
		hint_label.modulate = Color(0.2, 1.0, 0.4)
	else:
		hint_label.text = "⚠️ НЕТ СХЕМЫ! (Найдите планшет ATLAS'ом)"
		hint_label.modulate = Color(1.0, 0.4, 0.3)

	status_label.text = "ВЫБЕРИТЕ ПРОВОД ДЛЯ ПЕРЕРЕЗАНИЯ"
	status_label.modulate = Color.WHITE

	for i in range(wires_count):
		var palette_info = wire_palette[i % wire_palette.size()]
		var wire_row = HBoxContainer.new()
		wire_row.custom_minimum_size = Vector2(0, 50)
		wire_row.alignment = BoxContainer.ALIGNMENT_CENTER

		var wire_label = Label.new()
		wire_label.text = "ПРОВОД " + str(i + 1) + " [" + palette_info["name"] + "]"
		wire_label.custom_minimum_size = Vector2(250, 0)
		wire_label.add_theme_color_override("font_color", palette_info["color"])
		wire_label.add_theme_font_size_override("font_size", 20)
		wire_row.add_child(wire_label)

		# Wire line graphic / colored bar
		var wire_bar = ColorRect.new()
		wire_bar.custom_minimum_size = Vector2(200, 12)
		wire_bar.color = palette_info["color"]
		wire_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		wire_row.add_child(wire_bar)

		# Spacer
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(30, 0)
		wire_row.add_child(spacer)

		# Cut button
		var cut_btn = Button.new()
		cut_btn.text = " ✂️ ПЕРЕРЕЗАТЬ "
		cut_btn.custom_minimum_size = Vector2(160, 40)
		cut_btn.pressed.connect(_on_wire_cut.bind(i, wire_bar, cut_btn))
		wire_row.add_child(cut_btn)

		wires_container.add_child(wire_row)

func _on_wire_cut(index: int, wire_bar: ColorRect, cut_btn: Button) -> void:
	if cut_wires.has(index):
		return
	
	cut_wires.append(index)
	cut_btn.disabled = true
	cut_btn.text = "❌ ПЕРЕРЕЗАН"
	wire_bar.color = Color(0.3, 0.3, 0.3, 0.5)

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
		status_label.text = "⚡ ПРОВОД " + str(index + 1) + " ПРАВИЛЬНО ОБЕСТОЧЕН!"
		status_label.modulate = Color(0.2, 1.0, 0.4)

		# Check if all required wires cut
		var all_done = true
		for req in solution_wire_indices:
			if not cut_wires.has(req):
				all_done = false
				break
		
		if all_done:
			_on_success()
	else:
		_on_failure()

func _on_success() -> void:
	status_label.text = "✅ ДОСТУП РАЗРЕШЁН! ЛАЗЕРНЫЙ БАРЬЕР ОТКЛЮЧЕН!"
	status_label.modulate = Color(0.1, 1.0, 0.3)
	
	for child in wires_container.get_children():
		for sub in child.get_children():
			if sub is Button:
				sub.disabled = true

	get_tree().create_timer(1.2).timeout.connect(func():
		completed.emit(true)
		queue_free()
	)

func _on_failure() -> void:
	status_label.text = "❌ ОШИБКА! ЗАМЫКАНИЕ ЦЕПИ! (-20% БАТАРЕИ)"
	status_label.modulate = Color(1.0, 0.1, 0.1)

	# Deduct penalty from Cipher
	if RobotManager and RobotManager.cipher:
		RobotManager.cipher.battery = max(0.0, RobotManager.cipher.battery - 20.0)
		RobotManager.cipher.battery_changed.emit(RobotManager.cipher.battery, RobotManager.cipher.max_battery)

	# Reset after delay
	get_tree().create_timer(1.5).timeout.connect(_build_ui)

func _on_close_pressed() -> void:
	completed.emit(false)
	queue_free()
