class_name BatteryDisplay
extends Control

## Soft Creamy Retro Mecha Battery HUD Display
## Features enlarged soft warm ivory plates, character-tailored pastel borders, cute CRT robot avatars,
## and large prominent segmented battery power cells.

@export var robot_name: String = "ATLAS"
@export var robot_role: String = "HEAVY MECH"
@export var theme_color: Color = Color(0.91, 0.44, 0.36) # Soft Coral
@export var current_battery: float = 100.0
@export var max_battery: float = 100.0
@export var is_active: bool = true
@export var is_charging: bool = false

var anim_timer: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(430, 96)

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
	var pct = clamp(current_battery / max_battery, 0.0, 1.0)
	var pct_int = int(round(pct * 100.0))
	
	# Determine status energy color (calm warm palette)
	var energy_col: Color
	if pct_int > 50:
		energy_col = theme_color
	elif pct_int > 25:
		energy_col = Color(0.92, 0.62, 0.20) # Soft Honey Amber
	else:
		var flash = 0.70 + 0.30 * sin(anim_timer * 8.0)
		energy_col = Color(0.92, 0.30, 0.28, flash) # Soft Coral Red Warning
	
	var active_alpha = 1.0 if is_active else 0.65
	
	# ==========================================
	# 1. MAIN WING PLATE (Soft Warm Cream / Ivory)
	# ==========================================
	var wing_bg = Color(0.97, 0.95, 0.92, 0.96 * active_alpha) # Soft Cream
	var wing_border = Color(0.86, 0.80, 0.74, 0.85 * active_alpha)
	if is_active:
		wing_border = theme_color * Color(1, 1, 1, 0.90)
	
	# Chamfered wing polygon
	var wing_points = PackedVector2Array([
		Vector2(90, 8),
		Vector2(w - 32, 8),
		Vector2(w - 4, 20),
		Vector2(w - 4, 62),
		Vector2(w - 26, 88),
		Vector2(90, 88)
	])
	
	# Soft drop shadow behind wing
	var shadow_offset = Vector2(0, 4)
	var shadow_pts = PackedVector2Array()
	for pt in wing_points:
		shadow_pts.append(pt + shadow_offset)
	draw_colored_polygon(shadow_pts, Color(0.25, 0.20, 0.15, 0.14 * active_alpha))
	
	draw_colored_polygon(wing_points, wing_bg)
	draw_polyline(wing_points, wing_border, 2.5, true)
	
	# Top Warm Accent Rail
	var rail_pts = PackedVector2Array([
		Vector2(92, 7),
		Vector2(w - 65, 7),
		Vector2(w - 74, 12),
		Vector2(92, 12)
	])
	var rail_col = theme_color if is_active else Color(0.82, 0.76, 0.70, 0.5)
	if is_active:
		rail_col.a = 0.95
	draw_colored_polygon(rail_pts, rail_col)
	
	# Mini LED Status Diodes on Top-Right Bevel
	var led1_pos = Vector2(w - 52, 13)
	var led2_pos = Vector2(w - 38, 13)
	var led_active_col = Color(0.25, 0.80, 0.45, 0.95) if is_active else Color(0.70, 0.75, 0.70, 0.6)
	if is_charging:
		led_active_col = Color(0.3, 0.85, 0.95, 0.7 + 0.3 * sin(anim_timer * 10.0))
	draw_circle(led1_pos, 3.5, led_active_col)
	draw_circle(led2_pos, 3.5, led_active_col if pct_int > 25 else Color(0.92, 0.30, 0.28, 0.95))
	
	# ==========================================
	# 2. LEFT SIDE: AVATAR MODULE BOX (Soft Creamy TV)
	# ==========================================
	var av_rect = Rect2(8, 8, 80, 80)
	var av_bg = Color(0.97, 0.95, 0.92, 0.98 * active_alpha)
	var av_border = theme_color if is_active else Color(0.84, 0.78, 0.72, 0.7)
	
	# Drop shadow behind avatar box
	draw_rect(Rect2(8, 11, 80, 80), Color(0.25, 0.20, 0.15, 0.16 * active_alpha), true)
	
	# StyleBox for rounded avatar casing
	var style_av = StyleBoxFlat.new()
	style_av.bg_color = av_bg
	style_av.border_color = av_border
	style_av.set_border_width_all(2)
	style_av.set_corner_radius_all(14)
	style_av.draw(get_canvas_item(), av_rect)
	
	# Left accent bracket grip
	var grip_rect = Rect2(3, 22, 5, 52)
	draw_rect(grip_rect, theme_color * Color(1, 1, 1, active_alpha), true)
	
	# ------------------------------------------
	# Cute Retro CRT Robot Avatar
	# ------------------------------------------
	_draw_robot_avatar(Rect2(16, 16, 64, 64), active_alpha)
	
	# Circular Bottom-Corner Badge (Soft Latte Pill)
	var badge_center = Vector2(82, 80)
	draw_circle(badge_center, 13.5, Color(0.92, 0.86, 0.80, 1.0))
	draw_arc(badge_center, 13.5, 0, TAU, 24, theme_color * Color(1, 1, 1, active_alpha), 2.5, true)
	
	var font = ThemeDB.fallback_font
	var badge_text = "⚡" if is_charging else ("1" if robot_name == "DAU" or robot_name == "ATLAS" else "2")
	draw_string(font, badge_center + Vector2(-5, 5), badge_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.28, 0.24, 0.20, active_alpha))
	
	# ==========================================
	# 3. LABELS & TELEMETRY (Warm Espresso)
	# ==========================================
	var title_text = "⚡ " + robot_name + " // " + ("CHARGING" if is_charging else "BATTERY")
	var title_col = Color(0.18, 0.17, 0.20, 1.0) if is_active else Color(0.50, 0.47, 0.43, 0.8)
	draw_string(font, Vector2(98, 29), title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, title_col)
	
	# Percentage Text
	var pct_str = str(pct_int) + "%"
	draw_string(font, Vector2(w - 85, 29), pct_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 17, energy_col)
	
	# ==========================================
	# 4. 12 SEGMENTED BATTERY POWER CELLS
	# ==========================================
	var cell_start_x = 98.0
	var cell_y = 36.0
	var cell_w = 20.0
	var cell_h = 23.0
	var cell_gap = 4.5
	var total_cells = 12
	
	for i in range(total_cells):
		var cx = cell_start_x + float(i) * (cell_w + cell_gap)
		var cell_rect = Rect2(cx, cell_y, cell_w, cell_h)
		var is_cell_filled = pct >= (float(i) / float(total_cells))
		
		# Slot background (empty calm warm beige cell)
		draw_rect(cell_rect, Color(0.90, 0.87, 0.82, 0.95), true)
		draw_rect(cell_rect, Color(0.80, 0.75, 0.70, 0.7 * active_alpha), false, 1.0)
		
		if is_cell_filled:
			var fill_ratio = clamp((pct - float(i) / float(total_cells)) * float(total_cells), 0.0, 1.0)
			var filled_rect = Rect2(cx, cell_y, cell_w * fill_ratio, cell_h)
			
			# Subtle calm pulse
			var wave = 0.90 + 0.10 * sin(anim_timer * 6.0 - float(i) * 0.5)
			var cell_col = energy_col
			cell_col.a = clamp(wave, 0.0, 1.0) * active_alpha
			
			# Solid Cell Fill
			draw_rect(filled_rect, cell_col, true)
			
			# Soft gloss reflection on upper half of cell
			var gloss_rect = Rect2(cx, cell_y, cell_w * fill_ratio, cell_h * 0.40)
			draw_rect(gloss_rect, Color(1.0, 1.0, 1.0, 0.35 * active_alpha), true)
			
			# Outline
			draw_rect(filled_rect, Color(1.0, 1.0, 1.0, 0.45 * active_alpha), false, 1.0)
	
	# High-voltage charging cascade shimmer
	if is_charging:
		var wave_pos = cell_start_x + fmod(anim_timer * 220.0, float(total_cells) * (cell_w + cell_gap))
		draw_line(Vector2(wave_pos, cell_y - 2), Vector2(wave_pos, cell_y + cell_h + 2), Color(1.0, 1.0, 1.0, 0.9), 3.0)
	
	# ==========================================
	# 5. SUB-BAR: VOLTAGE TELEMETRY GAUGE
	# ==========================================
	var sub_x = cell_start_x
	var sub_y = 66.0
	var sub_w = float(total_cells) * (cell_w + cell_gap) - cell_gap
	var sub_h = 5.0
	
	# Sub-bar slot
	draw_rect(Rect2(sub_x, sub_y, sub_w, sub_h), Color(0.88, 0.84, 0.78, 0.95), true)
	
	# Sub-bar fill
	var sub_fill_w = sub_w * pct
	if sub_fill_w > 0:
		var sub_col = theme_color
		draw_rect(Rect2(sub_x, sub_y, sub_fill_w, sub_h), sub_col * Color(1, 1, 1, active_alpha), true)
	
	# Sub-text: Voltage readout (Soft Mocha / Taupe)
	var volt_str = str(snapped(pct * 24.0, 0.1)) + "V OUTPUT" if is_active else "STANDBY"
	draw_string(font, Vector2(sub_x, sub_y + 14), volt_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.52, 0.47, 0.42, 0.9 * active_alpha))

## Procedurally draws stylish retro mecha robot portraits inside the avatar container
func _draw_robot_avatar(rect: Rect2, alpha: float) -> void:
	var cx = rect.position.x + rect.size.x * 0.5
	var cy = rect.position.y + rect.size.y * 0.5
	
	if robot_name == "DAU" or robot_name == "ATLAS":
		# --- DAU: Coral Retro CRT Mecha ---
		# TV Monitor Casing
		var crt_rect = Rect2(cx - 20, cy - 16, 40, 32)
		var style_casing = StyleBoxFlat.new()
		style_casing.bg_color = Color(0.91, 0.47, 0.39, alpha) # Coral orange
		style_casing.set_corner_radius_all(8)
		style_casing.draw(get_canvas_item(), crt_rect)
		
		# Side dial knobs
		draw_circle(Vector2(cx - 21, cy), 4.0, Color(0.35, 0.38, 0.42, alpha))
		draw_circle(Vector2(cx + 21, cy), 4.0, Color(0.35, 0.38, 0.42, alpha))
		
		# Screen
		var screen_rect = Rect2(cx - 16, cy - 12, 32, 24)
		var style_screen = StyleBoxFlat.new()
		style_screen.bg_color = Color(0.77, 0.88, 0.85, alpha) # Pale mint cyan
		style_screen.set_corner_radius_all(5)
		style_screen.draw(get_canvas_item(), screen_rect)
		
		# Eyes (Cute dots • •)
		var blink = 1.0 if not is_active else (0.85 + 0.15 * sin(anim_timer * 3.5))
		draw_circle(Vector2(cx - 8, cy - 1), 3.2, Color(0.12, 0.14, 0.18, alpha * blink))
		draw_circle(Vector2(cx - 9.0, cy - 2.0), 1.2, Color(1, 1, 1, 0.9 * alpha * blink))
		draw_circle(Vector2(cx + 8, cy - 1), 3.2, Color(0.12, 0.14, 0.18, alpha * blink))
		draw_circle(Vector2(cx + 7.0, cy - 2.0), 1.2, Color(1, 1, 1, 0.9 * alpha * blink))
		
		# Soft coral blush
		draw_circle(Vector2(cx - 8, cy + 6), 2.6, Color(0.92, 0.45, 0.40, 0.6 * alpha))
		draw_circle(Vector2(cx + 8, cy + 6), 2.6, Color(0.92, 0.45, 0.40, 0.6 * alpha))
		
	else:
		# --- JAM: Mint Retro CRT Mecha ---
		# TV Monitor Casing
		var crt_rect = Rect2(cx - 20, cy - 16, 40, 32)
		var style_casing = StyleBoxFlat.new()
		style_casing.bg_color = Color(0.24, 0.76, 0.48, alpha) # Mint green
		style_casing.set_corner_radius_all(8)
		style_casing.draw(get_canvas_item(), crt_rect)
		
		# Side dial knobs
		draw_circle(Vector2(cx - 21, cy), 4.0, Color(0.35, 0.38, 0.42, alpha))
		draw_circle(Vector2(cx + 21, cy), 4.0, Color(0.35, 0.38, 0.42, alpha))
		
		# Screen
		var screen_rect = Rect2(cx - 16, cy - 12, 32, 24)
		var style_screen = StyleBoxFlat.new()
		style_screen.bg_color = Color(0.77, 0.88, 0.85, alpha) # Pale mint cyan
		style_screen.set_corner_radius_all(5)
		style_screen.draw(get_canvas_item(), screen_rect)
		
		# Eyes (Cute dots • •)
		var blink = 1.0 if not is_active else (0.85 + 0.15 * sin(anim_timer * 3.5))
		draw_circle(Vector2(cx - 8, cy - 1), 3.2, Color(0.12, 0.14, 0.18, alpha * blink))
		draw_circle(Vector2(cx - 9.0, cy - 2.0), 1.2, Color(1, 1, 1, 0.9 * alpha * blink))
		draw_circle(Vector2(cx + 8, cy - 1), 3.2, Color(0.12, 0.14, 0.18, alpha * blink))
		draw_circle(Vector2(cx + 7.0, cy - 2.0), 1.2, Color(1, 1, 1, 0.9 * alpha * blink))
		
		# Soft mint blush
		draw_circle(Vector2(cx - 8, cy + 6), 2.6, Color(0.20, 0.85, 0.50, 0.6 * alpha))
		draw_circle(Vector2(cx + 8, cy + 6), 2.6, Color(0.20, 0.85, 0.50, 0.6 * alpha))
