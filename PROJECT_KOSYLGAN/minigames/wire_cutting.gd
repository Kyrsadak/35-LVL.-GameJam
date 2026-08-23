class_name WireCuttingMinigame
extends CanvasLayer

signal completed(success: bool)

@export var wires_count: int = 3
@export var solution_wire_indices: Array[int] = [0]
@export var require_exact_order: bool = false
@export var clue_id: String = ""

var terminal_ref: Node = null
var current_cut_step: int = 0
var cut_wires: Array[int] = []

# Wire palette matching the clue guidelines 100%
var wire_palette = [
	{"name": "КРАСНЫЙ", "color": Color(0.92, 0.22, 0.22), "highlight": Color(1.0, 0.60, 0.60), "dark": Color(0.55, 0.10, 0.10), "symbol": "✖"},
	{"name": "СИНИЙ", "color": Color(0.18, 0.52, 0.95), "highlight": Color(0.55, 0.78, 1.0), "dark": Color(0.08, 0.28, 0.60), "symbol": "■"},
	{"name": "ЗЕЛЁНЫЙ", "color": Color(0.20, 0.82, 0.40), "highlight": Color(0.60, 0.96, 0.70), "dark": Color(0.08, 0.48, 0.20), "symbol": "●"},
	{"name": "ЖЁЛТЫЙ", "color": Color(0.96, 0.82, 0.15), "highlight": Color(1.0, 0.95, 0.60), "dark": Color(0.60, 0.50, 0.08), "symbol": "▲"},
	{"name": "ОРАНЖЕВЫЙ", "color": Color(0.96, 0.55, 0.15), "highlight": Color(1.0, 0.78, 0.50), "dark": Color(0.60, 0.30, 0.08), "symbol": "★"},
	{"name": "БЕЛЫЙ", "color": Color(0.92, 0.94, 0.96), "highlight": Color(1.0, 1.0, 1.0), "dark": Color(0.50, 0.52, 0.56), "symbol": "◆"}
]

# Spark particle struct for visual juice
var sparks: Array[Dictionary] = []

# Hovered wire index
var hovered_wire: int = -1

@onready var wire_canvas: Control = %WireCanvas
@onready var status_label: Label = %StatusLabel
@onready var hint_label: Label = %HintLabel
@onready var screen_text: Label = %ScreenText
@onready var close_btn: Button = %CloseBtn

func setup(p_terminal: Node, count: int, solution: Array[int], p_clue_id: String = "", order_required: bool = false) -> void:
	terminal_ref = p_terminal
	wires_count = clamp(count, 3, 6)
	solution_wire_indices = solution
	clue_id = p_clue_id
	require_exact_order = order_required

func _ready() -> void:
	if RobotManager:
		RobotManager.level_failed.connect(_on_level_failed)
		if RobotManager.is_game_over:
			queue_free()
			return

	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
	
	if wire_canvas:
		wire_canvas.draw.connect(_on_canvas_draw)
		wire_canvas.gui_input.connect(_on_canvas_input)
		wire_canvas.mouse_exited.connect(_on_canvas_mouse_exited)

	_build_ui()

func _on_level_failed(_reason: String = "") -> void:
	queue_free()

func _process(delta: float) -> void:
	if sparks.size() > 0:
		var updated_sparks: Array[Dictionary] = []
		for s in sparks:
			s["life"] -= delta * 2.5
			s["pos"] += s["vel"] * delta
			if s["life"] > 0:
				updated_sparks.append(s)
		sparks = updated_sparks
		if wire_canvas:
			wire_canvas.queue_redraw()

func _build_ui() -> void:
	cut_wires.clear()
	current_cut_step = 0
	sparks.clear()
	hovered_wire = -1

	# Clue / Blueprint Hint display
	if RobotManager and RobotManager.discovered_clues.has(clue_id):
		hint_label.text = "📋 СХЕМА DAU: " + RobotManager.discovered_clues[clue_id]
		hint_label.modulate = Color(0.3, 0.95, 0.5)
	else:
		hint_label.text = "⚠️ НЕТ СХЕМЫ! (Найдите планшет роботом DAU)"
		hint_label.modulate = Color(1.0, 0.75, 0.3)

	if screen_text:
		screen_text.text = "ВЫБЕРИТЕ И ПЕРЕРЕЖЬТЕ НУЖНЫЙ ПРОВОД"
		screen_text.modulate = Color(0.3, 0.9, 1.0)

	status_label.text = "КЛИКНИТЕ ПО ПРОВОДУ ДЛЯ ПЕРЕРЕЗАНИЯ"
	status_label.modulate = Color(0.85, 0.85, 0.9)

	if wire_canvas:
		wire_canvas.queue_redraw()

func _get_wire_endpoints(idx: int, total: int, canvas_size: Vector2) -> Dictionary:
	var pad_y = 60.0
	var available_h = canvas_size.y - (pad_y * 2.0)
	var step_y = available_h / float(max(1, total - 1))
	var y1 = pad_y + (idx * step_y)
	
	# Scramble target sockets slightly for fun realism
	var target_idx = (idx + (1 if idx % 2 == 0 else -1)) % total
	if total <= 3:
		target_idx = idx
	var y2 = pad_y + (target_idx * step_y)

	var p1 = Vector2(40.0, y1)
	var p2 = Vector2(canvas_size.x - 40.0, y2)
	
	# Control points for realistic sagging cable curve
	var sag = 50.0 + (idx * 15.0)
	var cp1 = Vector2(p1.x + (canvas_size.x * 0.3), p1.y + sag)
	var cp2 = Vector2(p1.x + (canvas_size.x * 0.7), p2.y + sag)

	return {"p1": p1, "p2": p2, "cp1": cp1, "cp2": cp2, "target_idx": target_idx}

func _sample_bezier(p1: Vector2, cp1: Vector2, cp2: Vector2, p2: Vector2, t: float) -> Vector2:
	var q0 = p1.lerp(cp1, t)
	var q1 = cp1.lerp(cp2, t)
	var q2 = cp2.lerp(p2, t)
	var r0 = q0.lerp(q1, t)
	var r1 = q1.lerp(q2, t)
	return r0.lerp(r1, t)

func _on_canvas_draw() -> void:
	if not wire_canvas:
		return
	
	var c_size = wire_canvas.size
	
	# 1. Draw Background shadow conduits (inactive grey wires in background)
	for bg_i in range(wires_count + 1):
		var bg_x = 70.0 + (bg_i * 80.0)
		var bg_points = PackedVector2Array()
		for t in 20:
			var ft = float(t) / 19.0
			var bx = bg_x + sin(ft * PI * 2.0) * 15.0
			var by = ft * c_size.y
			bg_points.append(Vector2(bx, by))
		wire_canvas.draw_polyline(bg_points, Color(0.12, 0.14, 0.18, 0.8), 8.0, true)

	# 2. Draw Main Interactive Wires
	for i in range(wires_count):
		var p_info = wire_palette[i % wire_palette.size()]
		var curve = _get_wire_endpoints(i, wires_count, c_size)
		var is_cut = cut_wires.has(i)
		var is_hovered = (hovered_wire == i and not is_cut)

		# Draw wire segments
		if not is_cut:
			# Intact continuous wire
			var points = PackedVector2Array()
			var steps = 30
			for s in range(steps + 1):
				var t = float(s) / float(steps)
				points.append(_sample_bezier(curve["p1"], curve["cp1"], curve["cp2"], curve["p2"], t))

			# Hover outline
			if is_hovered:
				wire_canvas.draw_polyline(points, Color(1.0, 0.9, 0.3, 0.9), 20.0, true)

			# Drop shadow / dark outline
			wire_canvas.draw_polyline(points, p_info["dark"], 14.0, true)
			# Main wire body
			wire_canvas.draw_polyline(points, p_info["color"], 10.0, true)
			# Top specular highlight
			var hl_points = PackedVector2Array()
			for pt in points:
				hl_points.append(pt - Vector2(0, 2))
			wire_canvas.draw_polyline(hl_points, p_info["highlight"], 3.0, true)

		else:
			# Severed wire (two halves drooping down with severed ends)
			# Left severed segment
			var left_points = PackedVector2Array()
			for s in range(16):
				var t = (float(s) / 15.0) * 0.44
				var pt = _sample_bezier(curve["p1"], curve["cp1"], curve["cp2"], curve["p2"], t)
				if s > 10:
					pt.y += (s - 10) * 4.0 # Droop
				left_points.append(pt)

			wire_canvas.draw_polyline(left_points, p_info["dark"], 14.0, true)
			wire_canvas.draw_polyline(left_points, p_info["color"], 10.0, true)
			# Copper cut tip
			var left_tip = left_points[left_points.size() - 1]
			wire_canvas.draw_circle(left_tip, 5.0, Color(0.9, 0.5, 0.1))

			# Right severed segment
			var right_points = PackedVector2Array()
			for s in range(16):
				var t = 0.56 + (float(s) / 15.0) * 0.44
				var pt = _sample_bezier(curve["p1"], curve["cp1"], curve["cp2"], curve["p2"], t)
				if s < 5:
					pt.y += (5 - s) * 4.0 # Droop
				right_points.append(pt)

			wire_canvas.draw_polyline(right_points, p_info["dark"], 14.0, true)
			wire_canvas.draw_polyline(right_points, p_info["color"], 10.0, true)
			# Copper cut tip
			var right_tip = right_points[0]
			wire_canvas.draw_circle(right_tip, 5.0, Color(0.9, 0.5, 0.1))

		# 3. Draw Left Terminal Cylinders
		var p1 = curve["p1"]
		wire_canvas.draw_rect(Rect2(p1.x - 30, p1.y - 14, 24, 28), Color(0.35, 0.40, 0.48))
		wire_canvas.draw_rect(Rect2(p1.x - 26, p1.y - 12, 16, 24), p_info["color"])
		wire_canvas.draw_rect(Rect2(p1.x - 10, p1.y - 10, 10, 20), Color(0.7, 0.75, 0.85))

		# 4. Draw Right Sockets + Status LEDs + Symbols
		var p2 = curve["p2"]
		var is_solved = cut_wires.has(i) and solution_wire_indices.has(i)
		var led_col = Color(0.2, 1.0, 0.4) if is_solved else (Color(1.0, 0.2, 0.2) if is_cut else Color(0.3, 0.35, 0.4))

		# Socket bracket
		wire_canvas.draw_rect(Rect2(p2.x + 6, p2.y - 16, 32, 32), Color(0.28, 0.32, 0.40))
		wire_canvas.draw_rect(Rect2(p2.x + 10, p2.y - 12, 24, 24), Color(0.16, 0.18, 0.22))
		# Symbol indicator
		wire_canvas.draw_string(ThemeDB.fallback_font, Vector2(p2.x + 16, p2.y + 5), p_info["symbol"], HORIZONTAL_ALIGNMENT_CENTER, -1, 14, p_info["color"])
		# Status LED
		wire_canvas.draw_circle(Vector2(p2.x + 46, p2.y), 5.0, led_col)

	# 5. Draw Electrical Sparks
	for s in sparks:
		var col = Color(1.0, 0.9, 0.2, s["life"])
		wire_canvas.draw_circle(s["pos"], randf_range(2.0, 4.5), col)

func _on_canvas_input(event: InputEvent) -> void:
	if not (event is InputEventMouse):
		return
	
	var mouse_pos = (event as InputEventMouse).position
	var found_hover = -1
	var c_size = wire_canvas.size

	for i in range(wires_count):
		if cut_wires.has(i):
			continue
		var curve = _get_wire_endpoints(i, wires_count, c_size)
		# Check distance from mouse to bezier curve
		for s in 25:
			var t = float(s) / 24.0
			var pt = _sample_bezier(curve["p1"], curve["cp1"], curve["cp2"], curve["p2"], t)
			if mouse_pos.distance_to(pt) < 22.0:
				found_hover = i
				break
		if found_hover != -1:
			break
	
	if hovered_wire != found_hover:
		hovered_wire = found_hover
		wire_canvas.queue_redraw()

	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and (event as InputEventMouseButton).pressed:
		if hovered_wire != -1:
			_cut_wire(hovered_wire, mouse_pos)

func _on_canvas_mouse_exited() -> void:
	hovered_wire = -1
	if wire_canvas:
		wire_canvas.queue_redraw()

func _cut_wire(index: int, cut_pos: Vector2) -> void:
	if cut_wires.has(index):
		return
	
	cut_wires.append(index)
	hovered_wire = -1

	# Spawn spark explosion at cut point
	for sp in 18:
		var vel = Vector2(randf_range(-120, 120), randf_range(-120, 120))
		sparks.append({"pos": cut_pos, "vel": vel, "life": 1.0})

	# Verify correctness
	var is_correct = false
	if require_exact_order:
		if current_cut_step < solution_wire_indices.size() and solution_wire_indices[current_cut_step] == index:
			is_correct = true
			current_cut_step += 1
	else:
		if solution_wire_indices.has(index):
			is_correct = true

	if is_correct:
		if SoundManager:
			SoundManager.play_cut()
		
		if screen_text:
			screen_text.text = "⚡ ПРОВОД #" + str(index + 1) + " ОБЕСТОЧЕН УСПЕШНО!"
			screen_text.modulate = Color(0.2, 1.0, 0.4)
		status_label.text = "ЛИНИЯ #" + str(index + 1) + " БЕЗОПАСНО РАЗОРВАНА"
		status_label.modulate = Color(0.25, 1.0, 0.45)

		var all_done = true
		for req in solution_wire_indices:
			if not cut_wires.has(req):
				all_done = false
				break
		
		if all_done:
			_on_success()
	else:
		if SoundManager:
			SoundManager.play_spark_error()
		if screen_text:
			screen_text.text = "❌ КОРОТКОЕ ЗАМЫКАНИЕ! ОШИБКА!"
			screen_text.modulate = Color(1.0, 0.2, 0.2)
		_on_failure()

	if wire_canvas:
		wire_canvas.queue_redraw()

func _on_success() -> void:
	if SoundManager:
		SoundManager.play_success()
	if screen_text:
		screen_text.text = "🟢 ВСЕ ЦЕПИ ОБЕСТОЧЕНЫ! ЛАЗЕРЫ ВЫКЛЮЧЕНЫ!"
		screen_text.modulate = Color(0.2, 1.0, 0.4)
	
	status_label.text = "✅ ДОСТУП РАЗРЕШЁН! ЛАЗЕРНЫЙ БАРЬЕР ДЕАКТИВИРОВАН"
	status_label.modulate = Color(0.2, 1.0, 0.4)

	get_tree().create_timer(1.2).timeout.connect(func():
		completed.emit(true)
		queue_free()
	)

func _on_failure() -> void:
	status_label.text = "❌ КОРОТКОЕ ЗАМЫКАНИЕ! (-30% БАТАРЕИ)"
	status_label.modulate = Color(1.0, 0.2, 0.2)

	if RobotManager and RobotManager.cipher:
		RobotManager.cipher.battery = max(0.0, RobotManager.cipher.battery - 30.0)
		RobotManager.cipher.battery_changed.emit(RobotManager.cipher.battery, RobotManager.cipher.max_battery)
		if RobotManager.cipher.battery <= 0.0:
			completed.emit(false)
			queue_free()
			RobotManager.cipher.on_battery_depleted()
			return

	get_tree().create_timer(1.4).timeout.connect(_build_ui)

func _on_close_pressed() -> void:
	completed.emit(false)
	queue_free()
