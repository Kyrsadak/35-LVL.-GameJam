class_name BatteryDisplay
extends Control

@export var robot_name: String = "ATLAS"
@export var theme_color: Color = Color(0.20, 0.65, 0.95)
@export var current_battery: float = 100.0
@export var max_battery: float = 100.0
@export var is_active: bool = true
@export var is_charging: bool = false

var anim_timer: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(250, 48)

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
	
	# 1. Background Panel
	var bg_col = Color(0.10, 0.12, 0.16, 0.90) if is_active else Color(0.08, 0.09, 0.12, 0.65)
	var border_col = theme_color if is_active else Color(0.30, 0.33, 0.40, 0.5)
	if is_active:
		border_col.a = 0.80 + 0.20 * sin(anim_timer * 3.5)
	
	draw_rect(Rect2(0, 0, w, h), bg_col, true)
	draw_rect(Rect2(0, 0, w, h), border_col, false, 2.0)
	
	# 2. Header: ONLY Robot Name and Percentage
	var font = ThemeDB.fallback_font
	var name_col = Color(1.0, 1.0, 1.0, 1.0) if is_active else Color(0.70, 0.72, 0.78, 0.8)
	draw_string(font, Vector2(10, 18), robot_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, name_col)
	
	var pct = int(round((current_battery / max_battery) * 100.0))
	var pct_str = str(pct) + "%"
	
	# Color by percentage
	var fill_col = theme_color
	if pct <= 25:
		fill_col = Color(1.0, 0.22, 0.20) # Red
		if is_active:
			fill_col.a = 0.70 + 0.30 * sin(anim_timer * 8.0)
	elif pct <= 50:
		fill_col = Color(1.0, 0.75, 0.15) # Amber Yellow
	
	draw_string(font, Vector2(w - 60, 18), pct_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 15, fill_col)
	
	# 3. Main Smooth Continuous Battery Bar with 10 Micro-Ticks
	var bar_x = 10.0
	var bar_y = 24.0
	var bar_w = w - 20.0
	var bar_h = 16.0
	
	# Slot Background
	draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.05, 0.06, 0.08, 0.95), true)
	draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.25, 0.28, 0.35, 0.6), false, 1.0)
	
	# Smooth Filled Width
	var fill_w = bar_w * clamp(current_battery / max_battery, 0.0, 1.0)
	if fill_w > 0.0:
		# Main Bar Fill
		draw_rect(Rect2(bar_x, bar_y, fill_w, bar_h), fill_col, true)
		
		# Top Highlight Glass Stripe
		draw_rect(Rect2(bar_x, bar_y, fill_w, bar_h * 0.45), Color(1.0, 1.0, 1.0, 0.30), true)
		
		# Glowing Leading Edge Line
		draw_line(Vector2(bar_x + fill_w, bar_y), Vector2(bar_x + fill_w, bar_y + bar_h), Color(1.0, 1.0, 1.0, 0.9), 2.0)
	
	# Sub-segment divider ticks (10 clean vertical lines)
	for i in range(1, 10):
		var tick_x = bar_x + (bar_w * (float(i) / 10.0))
		draw_line(Vector2(tick_x, bar_y), Vector2(tick_x, bar_y + bar_h), Color(0.06, 0.08, 0.10, 0.85), 1.5)
	
	# Charging ripple animation
	if is_charging:
		var wave_x = bar_x + fmod(anim_timer * 120.0, bar_w)
		draw_line(Vector2(wave_x, bar_y), Vector2(wave_x, bar_y + bar_h), Color(1.0, 1.0, 1.0, 0.8), 4.0)
