class_name BatteryDisplay
extends Control

## High-Tech Sci-Fi Electric HUD Battery Display based on modern Cyberpunk/Mecha UI.
## Features an Avatar portrait casing, 12 segmented electric plasma cells, animated lightning sparks,
## status LED diodes, and themed palettes for ATLAS and CIPHER.

@export var robot_name: String = "ATLAS"
@export var robot_role: String = "HEAVY MECH"
@export var theme_color: Color = Color(0.0, 0.90, 1.0) # Vibrant Cyan-Blue by default
@export var current_battery: float = 100.0
@export var max_battery: float = 100.0
@export var is_active: bool = true
@export var is_charging: bool = false

var anim_timer: float = 0.0
var _spark_offsets: Array[float] = []

func _ready() -> void:
	custom_minimum_size = Vector2(330, 74)
	for i in range(12):
		_spark_offsets.append(randf() * TAU)

func _process(delta: float) -> void:
	anim_timer += delta
	queue_redraw()

func set_battery(current: float, max_val: float) -> void:
	current_battery = clamp(current, 0.0, max_val)
	max_battery = max_val
	queue_redraw()

func set_active(active: bool) -> void:
	is_active = active
	queue_redraw()

func set_charging(charging: bool) -> void:
	is_charging = charging
	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	var pct = clamp(current_battery / max_battery, 0.0, 1.0)
	var pct_int = int(round(pct * 100.0))
	
	# Determine base status energy color
	var energy_col: Color
	if pct_int > 50:
		energy_col = theme_color
	elif pct_int > 25:
		energy_col = Color(1.0, 0.65, 0.10) # Electric Amber
	else:
		# Critical low battery warning flash
		var flash = 0.65 + 0.35 * sin(anim_timer * 9.0)
		energy_col = Color(1.0, 0.15, 0.20, flash) # Crimson Warning
	
	var active_alpha = 1.0 if is_active else 0.48
	
	# ==========================================
	# 1. RIGHT SIDE: CYBER WING CASING & BEVEL
	# ==========================================
	var wing_bg = Color(0.12, 0.14, 0.20, 0.95 * active_alpha)
	var wing_border = Color(0.24, 0.28, 0.38, 0.80 * active_alpha)
	if is_active:
		wing_border = theme_color * Color(1, 1, 1, 0.5 + 0.2 * sin(anim_timer * 3.0))
	
	var wing_points = PackedVector2Array([
		Vector2(68, 8),
		Vector2(w - 28, 8),
		Vector2(w - 4, 16),
		Vector2(w - 4, 46),
		Vector2(w - 22, 68),
		Vector2(68, 68)
	])
	
	draw_colored_polygon(wing_points, wing_bg)
	draw_polyline(wing_points, wing_border, 1.5, true)
	
	# Top Glowing Neon Rail
	var rail_pts = PackedVector2Array([
		Vector2(70, 6),
		Vector2(w - 55, 6),
		Vector2(w - 62, 11),
		Vector2(70, 11)
	])
	var rail_col = theme_color if is_active else Color(0.35, 0.40, 0.50, 0.4)
	if is_active:
		rail_col.a = 0.85 + 0.15 * sin(anim_timer * 4.0)
	draw_colored_polygon(rail_pts, rail_col)
	
	# Mini LED Status Diodes on Top-Right Bevel
	var led1_pos = Vector2(w - 44, 10)
	var led2_pos = Vector2(w - 32, 10)
	var led_active_col = Color(0.2, 1.0, 0.4, 0.9) if is_active else Color(0.3, 0.4, 0.3, 0.5)
	if is_charging:
		led_active_col = Color(0.3, 0.9, 1.0, 0.7 + 0.3 * sin(anim_timer * 12.0))
	draw_circle(led1_pos, 2.5, led_active_col)
	draw_circle(led2_pos, 2.5, led_active_col if pct_int > 25 else Color(1.0, 0.2, 0.2, 0.8))
	
	# ==========================================
	# 2. LEFT SIDE: AVATAR MODULE BOX & BRACKETS
	# ==========================================
	var av_rect = Rect2(6, 6, 60, 60)
	var av_bg = Color(0.08, 0.10, 0.14, 0.98)
	var av_border = theme_color if is_active else Color(0.25, 0.28, 0.36, 0.6)
	if is_active:
		av_border.a = 0.85 + 0.15 * sin(anim_timer * 3.5)
	
	# Dark Avatar Box Background
	draw_rect(av_rect, av_bg, true)
	draw_rect(av_rect, av_border, false, 2.0)
	
	# Left neon bracket grip (as in reference mockup)
	var grip_rect = Rect2(1, 16, 5, 40)
	draw_rect(grip_rect, theme_color * Color(1, 1, 1, active_alpha), true)
	draw_rect(grip_rect, Color(1, 1, 1, 0.4 * active_alpha), false, 1.0)
	
	# ------------------------------------------
	# Custom High-Tech Procedural Robot Avatar
	# ------------------------------------------
	_draw_robot_avatar(Rect2(12, 12, 48, 48), active_alpha)
	
	# Circular Bottom-Corner Level / Power Badge
	var badge_center = Vector2(62, 60)
	draw_circle(badge_center, 10.5, Color(0.08, 0.10, 0.14, 1.0))
	draw_arc(badge_center, 10.5, 0, TAU, 24, theme_color * Color(1, 1, 1, active_alpha), 2.0, true)
	
	var font = ThemeDB.fallback_font
	var badge_text = "⚡" if is_charging else ("1" if robot_name == "ATLAS" else "2")
	draw_string(font, badge_center + Vector2(-4, 4), badge_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color.WHITE * Color(1, 1, 1, active_alpha))
	
	# ==========================================
	# 3. LABELS & TELEMETRY
	# ==========================================
	# "⚡ BATTERY // ATLAS"
	var title_text = "⚡ " + robot_name + " // " + ("CHARGING" if is_charging else "BATTERY")
	var title_col = Color.WHITE if is_active else Color(0.70, 0.75, 0.85, 0.6)
	draw_string(font, Vector2(74, 25), title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, title_col)
	
	# Percentage Text
	var pct_str = str(pct_int) + "%"
	draw_string(font, Vector2(w - 74, 25), pct_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 13, energy_col)
	
	# ==========================================
	# 4. 12 SEGMENTED ELECTRIC POWER CELLS
	# ==========================================
	var cell_start_x = 74.0
	var cell_y = 31.0
	var cell_w = 15.0
	var cell_h = 17.0
	var cell_gap = 3.5
	var total_cells = 12
	
	for i in range(total_cells):
		var cx = cell_start_x + float(i) * (cell_w + cell_gap)
		var cell_rect = Rect2(cx, cell_y, cell_w, cell_h)
		var cell_fill_threshold = float(i + 1) / float(total_cells)
		var is_cell_filled = pct >= (float(i) / float(total_cells))
		
		# Slot background (empty cell)
		draw_rect(cell_rect, Color(0.06, 0.08, 0.12, 0.95), true)
		draw_rect(cell_rect, Color(0.18, 0.22, 0.30, 0.5 * active_alpha), false, 1.0)
		
		if is_cell_filled:
			var fill_ratio = clamp((pct - float(i) / float(total_cells)) * float(total_cells), 0.0, 1.0)
			var filled_rect = Rect2(cx, cell_y, cell_w * fill_ratio, cell_h)
			
			# Dynamic electric shimmer wave travelling across active cells
			var wave = 0.5 + 0.5 * sin(anim_timer * 11.0 - float(i) * 0.75)
			var cell_col = energy_col
			cell_col.a = clamp(0.78 + 0.22 * wave, 0.0, 1.0) * active_alpha
			
			# Solid Cell Glow Fill
			draw_rect(filled_rect, cell_col, true)
			
			# Glass reflection / Highlight on upper half of cell
			var gloss_rect = Rect2(cx, cell_y, cell_w * fill_ratio, cell_h * 0.40)
			draw_rect(gloss_rect, Color(1.0, 1.0, 1.0, 0.35 * active_alpha), true)
			
			# Outer electric glow border
			draw_rect(filled_rect, Color(1.0, 1.0, 1.0, 0.5 * active_alpha), false, 1.0)
			
			# Micro-lightning spark arc on active cells
			if is_active and randf() < 0.12:
				var spark_y = cell_y + randf() * cell_h
				draw_line(Vector2(cx, spark_y), Vector2(cx + cell_w * fill_ratio, spark_y + (randf() - 0.5) * 4.0), Color(1, 1, 1, 0.9), 1.5)
	
	# High-voltage charging cascade wave
	if is_charging:
		var wave_pos = cell_start_x + fmod(anim_timer * 220.0, float(total_cells) * (cell_w + cell_gap))
		draw_line(Vector2(wave_pos, cell_y - 2), Vector2(wave_pos, cell_y + cell_h + 2), Color(1.0, 1.0, 1.0, 0.9), 3.0)
		draw_circle(Vector2(wave_pos, cell_y + cell_h * 0.5), 4.0, Color(0.4, 0.9, 1.0, 0.75))
	
	# ==========================================
	# 5. SUB-BAR: VOLTAGE TELEMETRY GAUGE
	# ==========================================
	var sub_x = cell_start_x
	var sub_y = 53.0
	var sub_w = float(total_cells) * (cell_w + cell_gap) - cell_gap
	var sub_h = 4.0
	
	# Sub-bar background slot
	draw_rect(Rect2(sub_x, sub_y, sub_w, sub_h), Color(0.06, 0.08, 0.12, 0.95), true)
	
	# Sub-bar fill
	var sub_fill_w = sub_w * pct
	if sub_fill_w > 0:
		var sub_col = Color(1.0, 0.55, 0.10) if robot_name == "CIPHER" else Color(0.2, 0.8, 1.0)
		draw_rect(Rect2(sub_x, sub_y, sub_fill_w, sub_h), sub_col * Color(1, 1, 1, active_alpha), true)
		draw_line(Vector2(sub_x + sub_fill_w, sub_y), Vector2(sub_x + sub_fill_w, sub_y + sub_h), Color.WHITE, 1.5)
	
	# Sub-text: Voltage readout
	var volt_str = str(snapped(pct * 24.0, 0.1)) + "V OUTPUT" if is_active else "STANDBY"
	draw_string(font, Vector2(sub_x, sub_y + 11), volt_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.50, 0.55, 0.65, 0.7 * active_alpha))

## Procedurally draws stylish vector robot portraits inside the avatar container
func _draw_robot_avatar(rect: Rect2, alpha: float) -> void:
	var cx = rect.position.x + rect.size.x * 0.5
	var cy = rect.position.y + rect.size.y * 0.5
	
	if robot_name == "ATLAS":
		# --- ATLAS: Heavy Armored Titan Mech ---
		# Head Chassis
		var head_rect = Rect2(cx - 16, cy - 14, 32, 28)
		draw_rect(head_rect, Color(0.18, 0.22, 0.30, alpha), true)
		draw_rect(head_rect, Color(0.40, 0.65, 0.85, alpha), false, 1.5)
		
		# Neck & Shoulder armor
		draw_rect(Rect2(cx - 20, cy + 12, 40, 8), Color(0.12, 0.15, 0.22, alpha), true)
		draw_rect(Rect2(cx - 20, cy + 12, 40, 8), Color(0.30, 0.50, 0.70, alpha), false, 1.0)
		
		# Heavy Ear Horns / Antennas
		draw_rect(Rect2(cx - 19, cy - 16, 4, 8), Color(0.35, 0.40, 0.50, alpha), true)
		draw_rect(Rect2(cx + 15, cy - 16, 4, 8), Color(0.35, 0.40, 0.50, alpha), true)
		
		# Glowing Cyan Dual Optic Visor [ • • ]
		var eye_col = Color(0.0, 0.95, 1.0, alpha)
		var blink = 1.0 if not is_active else (0.8 + 0.2 * sin(anim_timer * 4.0))
		draw_circle(Vector2(cx - 7, cy), 3.5, eye_col * Color(1, 1, 1, blink))
		draw_circle(Vector2(cx + 7, cy), 3.5, eye_col * Color(1, 1, 1, blink))
		draw_circle(Vector2(cx - 7, cy), 1.5, Color.WHITE * Color(1, 1, 1, blink))
		draw_circle(Vector2(cx + 7, cy), 1.5, Color.WHITE * Color(1, 1, 1, blink))
		
	else:
		# --- CIPHER: Sleek CRT Hacker Mech ---
		# Rounded CRT Screen Frame
		var crt_rect = Rect2(cx - 15, cy - 12, 30, 24)
		draw_rect(crt_rect, Color(0.14, 0.12, 0.10, alpha), true)
		draw_rect(crt_rect, Color(0.95, 0.60, 0.15, alpha), false, 1.5)
		
		# Mecha Sensor Ears / Antennas
		draw_polygon(PackedVector2Array([Vector2(cx - 12, cy - 12), Vector2(cx - 16, cy - 20), Vector2(cx - 8, cy - 12)]), [Color(0.85, 0.45, 0.10, alpha)])
		draw_polygon(PackedVector2Array([Vector2(cx + 12, cy - 12), Vector2(cx + 16, cy - 20), Vector2(cx + 8, cy - 12)]), [Color(0.85, 0.45, 0.10, alpha)])
		
		# Neck collar
		draw_rect(Rect2(cx - 12, cy + 12, 24, 6), Color(0.20, 0.16, 0.12, alpha), true)
		
		# Glowing Amber Hacker Eyes ( • • ) with CRT scanline
		var eye_col = Color(1.0, 0.70, 0.0, alpha)
		var blink = 1.0 if not is_active else (0.85 + 0.15 * sin(anim_timer * 5.0))
		draw_rect(Rect2(cx - 10, cy - 3, 7, 5), eye_col * Color(1, 1, 1, blink), true)
		draw_rect(Rect2(cx + 3, cy - 3, 7, 5), eye_col * Color(1, 1, 1, blink), true)
		draw_rect(Rect2(cx - 8, cy - 1, 3, 2), Color.WHITE * Color(1, 1, 1, blink), true)
		draw_rect(Rect2(cx + 5, cy - 1, 3, 2), Color.WHITE * Color(1, 1, 1, blink), true)
