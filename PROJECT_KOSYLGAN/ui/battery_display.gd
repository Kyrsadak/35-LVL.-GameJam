class_name BatteryDisplay
extends Control

@export var robot_name: String = "CIPHER"
@export var robot_role: String = "INFILTRATOR // HACKER"
@export var theme_color: Color = Color(0.95, 0.55, 0.15) # Amber/Cyan
@export var current_battery: float = 100.0
@export var max_battery: float = 100.0
@export var is_active: bool = false
@export var is_charging: bool = false

var segments_count: int = 10
var anim_timer: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(280, 68)

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
	
	# 1. Background Glass Panel
	var bg_col = Color(0.12, 0.14, 0.18, 0.92) if is_active else Color(0.10, 0.11, 0.14, 0.75)
	var border_col = theme_color if is_active else Color(0.35, 0.38, 0.45, 0.4)
	if is_active:
		border_col.a = 0.85 + 0.15 * sin(anim_timer * 4.0)
	
	# Rounded Panel with border
	draw_rect(Rect2(0, 0, w, h), bg_col, true, -1.0)
	draw_rect(Rect2(0, 0, w, h), border_col, false, 2.0)
	
	# Active Top Indicator Stripe
	if is_active:
		draw_rect(Rect2(2, 2, w - 4, 3), theme_color, true)

	# 2. Header: Robot Icon + Name + Percentage
	var font = ThemeDB.fallback_font
	var icon_sym = "⚡ " if robot_name == "CIPHER" else "🛡️ "
	var title_str = icon_sym + robot_name
	draw_string(font, Vector2(12, 22), title_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 1) if is_active else Color(0.75, 0.75, 0.8))
	
	# Active / Standby Badge
	var status_text = "▶ ACTIVE" if is_active else "⏸ STANDBY"
	var status_col = Color(0.2, 1.0, 0.45) if is_active else Color(0.55, 0.58, 0.65)
	draw_string(font, Vector2(100, 21), status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, status_col)
	
	# Large Percentage + Voltage
	var pct = int(round((current_battery / max_battery) * 100.0))
	var pct_str = str(pct) + "%"
	var volt_str = str(snprintf_volt(current_battery)) + "V"
	
	# Voltage color alert
	var cell_col = theme_color
	if pct <= 25:
		cell_col = Color(1.0, 0.25, 0.2) # Critical Red
		if is_active:
			cell_col.a = 0.6 + 0.4 * sin(anim_timer * 8.0)
	elif pct <= 50:
		cell_col = Color(1.0, 0.80, 0.2) # Caution Gold
	
	draw_string(font, Vector2(w - 75, 22), pct_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 16, cell_col)
	draw_string(font, Vector2(w - 30, 21), volt_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 11, Color(0.65, 0.7, 0.78))

	# 3. Segmented 10-Cell Power Bar
	var bar_x = 12.0
	var bar_y = 32.0
	var bar_w = w - 24.0
	var bar_h = 24.0
	
	# Outer Battery Casing Frame
	draw_rect(Rect2(bar_x - 2, bar_y - 2, bar_w + 4, bar_h + 4), Color(0.06, 0.08, 0.10, 0.85), true)
	draw_rect(Rect2(bar_x - 2, bar_y - 2, bar_w + 4, bar_h + 4), Color(0.25, 0.28, 0.35, 0.7), false, 1.0)
	
	# Cell segments computation
	var active_segments = int(round((current_battery / max_battery) * float(segments_count)))
	var seg_gap = 3.0
	var seg_w = (bar_w - (seg_gap * float(segments_count - 1))) / float(segments_count)
	var slant = 4.0 # Angled sci-fi slant
	
	for i in range(segments_count):
		var sx = bar_x + (i * (seg_w + seg_gap))
		var is_lit = i < active_segments
		
		# Charging wave effect
		if is_charging:
			var wave = fmod(anim_timer * 5.0, float(segments_count))
			if abs(float(i) - wave) < 1.5:
				is_lit = true
		
		var seg_poly = PackedVector2Array([
			Vector2(sx + slant, bar_y),
			Vector2(sx + seg_w + slant, bar_y),
			Vector2(sx + seg_w, bar_y + bar_h),
			Vector2(sx, bar_y + bar_h)
		])
		
		if is_lit:
			# Lit active segment
			var s_col = cell_col
			# Top-to-bottom subtle gradient
			draw_colored_polygon(seg_poly, s_col)
			
			# Glass reflection highlight on top half
			var hl_poly = PackedVector2Array([
				Vector2(sx + slant, bar_y),
				Vector2(sx + seg_w + slant, bar_y),
				Vector2(sx + seg_w + (slant * 0.5), bar_y + (bar_h * 0.45)),
				Vector2(sx + (slant * 0.5), bar_y + (bar_h * 0.45))
			])
			draw_colored_polygon(hl_poly, Color(1, 1, 1, 0.35))
			
			# Segment border
			draw_polyline(seg_poly, Color(1, 1, 1, 0.6), 1.0, true)
		else:
			# Empty uncharged segment slot
			draw_colored_polygon(seg_poly, Color(0.16, 0.18, 0.22, 0.6))
			draw_polyline(seg_poly, Color(0.25, 0.28, 0.35, 0.4), 1.0, true)

	# 4. Bottom Subtitle (Role + Status)
	var sub_text = robot_role
	if is_charging:
		sub_text = "⚡ CHARGING IN PROGRESS // 45W FAST DOCK"
	draw_string(font, Vector2(12, h - 5), sub_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.55, 0.60, 0.70))

func snprintf_volt(bat: float) -> String:
	var v = 18.0 + (bat / 100.0) * 6.8
	return str(snapped(v, 0.1))
