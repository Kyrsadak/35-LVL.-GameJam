class_name DialoguePortrait
extends Control

@export var speaker_id: String = "catgirl" # "catgirl", "atlas", "cipher"
@export var is_talking: bool = false

var talk_timer: float = 0.0
var mouth_open: float = 0.0
var blink_timer: float = 2.5
var is_blinking: bool = false
var ear_wiggle_angle: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(140, 140)
	blink_timer = randf_range(2.0, 4.0)

func set_speaker(speaker: String) -> void:
	speaker_id = speaker.to_lower()
	queue_redraw()

func set_talking(talking: bool) -> void:
	is_talking = talking
	if not is_talking:
		talk_timer = 0.0

func _process(delta: float) -> void:
	if not visible or modulate.a <= 0.01:
		return
		
	# 1. Talk Animation (Mouth flapping & ear wiggle)
	if is_talking:
		talk_timer += delta * 22.0
		# Irregular natural syllable cadence
		var raw_flap = sin(talk_timer) * 0.5 + sin(talk_timer * 1.8) * 0.3 + 0.5
		mouth_open = clamp(raw_flap, 0.0, 1.0)
		ear_wiggle_angle = sin(talk_timer * 0.5) * 0.12
	else:
		mouth_open = lerp(mouth_open, 0.0, delta * 15.0)
		ear_wiggle_angle = lerp(ear_wiggle_angle, 0.0, delta * 10.0)
		
	# 2. Eye Blink Animation
	blink_timer -= delta
	if blink_timer <= 0.0:
		if not is_blinking:
			is_blinking = true
			blink_timer = 0.14
		else:
			is_blinking = false
			blink_timer = randf_range(2.2, 4.8)
			
	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	var center = Vector2(w * 0.5, h * 0.58)
	
	match speaker_id:
		"catgirl", "weo", "crt_cat", "koshka":
			_draw_catgirl_portrait(center, w, h)
		"atlas":
			_draw_atlas_portrait(center, w, h)
		"cipher":
			_draw_cipher_portrait(center, w, h)
		_:
			_draw_catgirl_portrait(center, w, h)

func _draw_catgirl_portrait(center: Vector2, _w: float, _h: float) -> void:
	var tv_w = 100.0
	var tv_h = 78.0
	var tv_rect = Rect2(center.x - tv_w * 0.5, center.y - tv_h * 0.5, tv_w, tv_h)
	
	# 1. Cat Ears on Top
	var ear_base_y = tv_rect.position.y + 5.0
	var left_ear_root = Vector2(tv_rect.position.x + 15.0, ear_base_y)
	var right_ear_root = Vector2(tv_rect.end.x - 15.0, ear_base_y)
	
	# Left Ear with subtle talking wiggle
	var l_tip = left_ear_root + Vector2(-12.0, -32.0).rotated(ear_wiggle_angle)
	var l_pts = PackedVector2Array([
		left_ear_root + Vector2(-10, 0),
		l_tip,
		left_ear_root + Vector2(15, 0)
	])
	draw_colored_polygon(l_pts, Color(0.95, 0.52, 0.68)) # Pink casing
	var l_inner = PackedVector2Array([
		left_ear_root + Vector2(-5, -2),
		l_tip + Vector2(3, 8),
		left_ear_root + Vector2(10, -2)
	])
	draw_colored_polygon(l_inner, Color(1.0, 0.82, 0.88)) # Light pink inner
	
	# Right Ear
	var r_tip = right_ear_root + Vector2(12.0, -32.0).rotated(-ear_wiggle_angle)
	var r_pts = PackedVector2Array([
		right_ear_root + Vector2(-15, 0),
		r_tip,
		right_ear_root + Vector2(10, 0)
	])
	draw_colored_polygon(r_pts, Color(0.95, 0.52, 0.68))
	var r_inner = PackedVector2Array([
		right_ear_root + Vector2(-10, -2),
		r_tip + Vector2(-3, 8),
		right_ear_root + Vector2(5, -2)
	])
	draw_colored_polygon(r_inner, Color(1.0, 0.82, 0.88))
	
	# Side antenna / plug socket on right
	draw_circle(Vector2(tv_rect.end.x + 5, center.y - 5), 6.0, Color(0.35, 0.38, 0.45))
	draw_line(Vector2(tv_rect.end.x + 5, center.y - 5), Vector2(tv_rect.end.x + 18, center.y - 22), Color(0.2, 0.22, 0.26), 4.0)
	draw_rect(Rect2(tv_rect.end.x + 14, center.y - 28, 10, 8), Color(0.95, 0.52, 0.68))
	
	# 2. CRT Monitor Casing (Cute rounded rectangle)
	var style_casing = StyleBoxFlat.new()
	style_casing.bg_color = Color(0.95, 0.52, 0.68) # Pastel Hot Pink
	style_casing.border_color = Color(0.82, 0.36, 0.52)
	style_casing.set_border_width_all(3)
	style_casing.set_corner_radius_all(16)
	style_casing.shadow_color = Color(0.25, 0.15, 0.20, 0.35)
	style_casing.shadow_size = 8
	style_casing.shadow_offset = Vector2(0, 3)
	style_casing.draw(get_canvas_item(), tv_rect)
	
	# 3. CRT Screen (Pale cyan glass)
	var screen_rect = Rect2(tv_rect.position.x + 8, tv_rect.position.y + 8, tv_rect.size.x - 16, tv_rect.size.y - 16)
	var style_screen = StyleBoxFlat.new()
	style_screen.bg_color = Color(0.82, 0.94, 0.92) # Soft mint cyan
	style_screen.border_color = Color(0.68, 0.82, 0.80)
	style_screen.set_border_width_all(2)
	style_screen.set_corner_radius_all(11)
	style_screen.draw(get_canvas_item(), screen_rect)
	
	# Corner LED indicator
	draw_rect(Rect2(screen_rect.end.x - 9, screen_rect.position.y + 6, 4, 4), Color(0.2, 0.95, 0.5))
	
	var s_center = screen_rect.get_center()
	
	# 4. Cute Catgirl Anime Face
	var eye_y = s_center.y - 5.0
	var left_eye_x = s_center.x - 19.0
	var right_eye_x = s_center.x + 19.0
	
	if is_blinking:
		# Happy blink ^ ^
		draw_line(Vector2(left_eye_x - 8, eye_y), Vector2(left_eye_x, eye_y - 5), Color(0.15, 0.16, 0.20), 3.0)
		draw_line(Vector2(left_eye_x, eye_y - 5), Vector2(left_eye_x + 8, eye_y), Color(0.15, 0.16, 0.20), 3.0)
		
		draw_line(Vector2(right_eye_x - 8, eye_y), Vector2(right_eye_x, eye_y - 5), Color(0.15, 0.16, 0.20), 3.0)
		draw_line(Vector2(right_eye_x, eye_y - 5), Vector2(right_eye_x + 8, eye_y), Color(0.15, 0.16, 0.20), 3.0)
	else:
		# Round cute eyes with white highlight
		draw_circle(Vector2(left_eye_x, eye_y), 5.5, Color(0.15, 0.16, 0.20))
		draw_circle(Vector2(left_eye_x - 1.5, eye_y - 1.8), 2.0, Color(1, 1, 1, 0.9))
		
		draw_circle(Vector2(right_eye_x, eye_y), 5.5, Color(0.15, 0.16, 0.20))
		draw_circle(Vector2(right_eye_x - 1.5, eye_y - 1.8), 2.0, Color(1, 1, 1, 0.9))
		
	# Cute Pink Blush on Cheeks
	draw_circle(Vector2(left_eye_x - 10, eye_y + 8), 5.0, Color(1.0, 0.45, 0.55, 0.55))
	draw_circle(Vector2(right_eye_x + 10, eye_y + 8), 5.0, Color(1.0, 0.45, 0.55, 0.55))
	
	# Whiskers
	draw_line(Vector2(left_eye_x - 14, eye_y + 5), Vector2(left_eye_x - 26, eye_y + 2), Color(0.2, 0.25, 0.3, 0.6), 2.0)
	draw_line(Vector2(left_eye_x - 14, eye_y + 10), Vector2(left_eye_x - 26, eye_y + 12), Color(0.2, 0.25, 0.3, 0.6), 2.0)
	draw_line(Vector2(right_eye_x + 14, eye_y + 5), Vector2(right_eye_x + 26, eye_y + 2), Color(0.2, 0.25, 0.3, 0.6), 2.0)
	draw_line(Vector2(right_eye_x + 14, eye_y + 10), Vector2(right_eye_x + 26, eye_y + 12), Color(0.2, 0.25, 0.3, 0.6), 2.0)
	
	# 5. Dynamic Talking Mouth!
	var mouth_y = s_center.y + 9.0
	if mouth_open > 0.15:
		# Open talking mouth (cute animated oval / open D)
		var open_h = 4.0 + mouth_open * 10.0
		var open_w = 8.0 + mouth_open * 5.0
		var m_rect = Rect2(s_center.x - open_w * 0.5, mouth_y - open_h * 0.5 + 2.0, open_w, open_h)
		draw_rect(m_rect, Color(0.15, 0.16, 0.20), true, -1.0)
		# Cute tongue inside
		if open_h > 6.0:
			draw_circle(Vector2(s_center.x, m_rect.end.y - 2.5), open_w * 0.35, Color(1.0, 0.5, 0.6))
	else:
		# Closed cute cat mouth 'ω'
		var pts_l = PackedVector2Array([
			Vector2(s_center.x - 7, mouth_y),
			Vector2(s_center.x - 3.5, mouth_y + 3.0),
			Vector2(s_center.x, mouth_y)
		])
		var pts_r = PackedVector2Array([
			Vector2(s_center.x, mouth_y),
			Vector2(s_center.x + 3.5, mouth_y + 3.0),
			Vector2(s_center.x + 7, mouth_y)
		])
		draw_polyline(pts_l, Color(0.15, 0.16, 0.20), 2.5)
		draw_polyline(pts_r, Color(0.15, 0.16, 0.20), 2.5)

func _draw_atlas_portrait(center: Vector2, _w: float, _h: float) -> void:
	var tv_w = 100.0
	var tv_h = 78.0
	var tv_rect = Rect2(center.x - tv_w * 0.5, center.y - tv_h * 0.5, tv_w, tv_h)
	
	# Side dials
	draw_circle(Vector2(tv_rect.position.x - 4, center.y), 7.0, Color(0.32, 0.36, 0.40))
	draw_circle(Vector2(tv_rect.end.x + 4, center.y), 7.0, Color(0.32, 0.36, 0.40))
	
	# Casing
	var style_casing = StyleBoxFlat.new()
	style_casing.bg_color = Color(0.91, 0.47, 0.39) # Coral orange
	style_casing.border_color = Color(0.78, 0.35, 0.28)
	style_casing.set_border_width_all(3)
	style_casing.set_corner_radius_all(14)
	style_casing.draw(get_canvas_item(), tv_rect)
	
	# Screen
	var screen_rect = Rect2(tv_rect.position.x + 8, tv_rect.position.y + 8, tv_rect.size.x - 16, tv_rect.size.y - 16)
	var style_screen = StyleBoxFlat.new()
	style_screen.bg_color = Color(0.77, 0.84, 0.83)
	style_screen.border_color = Color(0.60, 0.70, 0.68)
	style_screen.set_border_width_all(2)
	style_screen.set_corner_radius_all(10)
	style_screen.draw(get_canvas_item(), screen_rect)
	
	var s_center = screen_rect.get_center()
	var eye_y = s_center.y - 5.0
	var left_eye_x = s_center.x - 18.0
	var right_eye_x = s_center.x + 18.0
	
	if is_blinking:
		draw_line(Vector2(left_eye_x - 6, eye_y), Vector2(left_eye_x + 6, eye_y), Color(0.12, 0.14, 0.18), 3.0)
		draw_line(Vector2(right_eye_x - 6, eye_y), Vector2(right_eye_x + 6, eye_y), Color(0.12, 0.14, 0.18), 3.0)
	else:
		draw_circle(Vector2(left_eye_x, eye_y), 5.0, Color(0.12, 0.14, 0.18))
		draw_circle(Vector2(left_eye_x - 1.2, eye_y - 1.2), 1.6, Color(1, 1, 1, 0.9))
		draw_circle(Vector2(right_eye_x, eye_y), 5.0, Color(0.12, 0.14, 0.18))
		draw_circle(Vector2(right_eye_x - 1.2, eye_y - 1.2), 1.6, Color(1, 1, 1, 0.9))
		
	# Blush
	draw_circle(Vector2(left_eye_x - 9, eye_y + 8), 4.5, Color(0.92, 0.45, 0.40, 0.6))
	draw_circle(Vector2(right_eye_x + 9, eye_y + 8), 4.5, Color(0.92, 0.45, 0.40, 0.6))
	
	# Mouth
	var mouth_y = s_center.y + 8.0
	if mouth_open > 0.15:
		var open_h = 4.0 + mouth_open * 8.0
		var open_w = 10.0 + mouth_open * 5.0
		draw_rect(Rect2(s_center.x - open_w * 0.5, mouth_y - open_h * 0.5 + 2.0, open_w, open_h), Color(0.12, 0.14, 0.18))
	else:
		draw_line(Vector2(s_center.x - 7, mouth_y), Vector2(s_center.x + 7, mouth_y), Color(0.12, 0.14, 0.18), 3.0)

func _draw_cipher_portrait(center: Vector2, _w: float, _h: float) -> void:
	var tv_w = 100.0
	var tv_h = 78.0
	var tv_rect = Rect2(center.x - tv_w * 0.5, center.y - tv_h * 0.5, tv_w, tv_h)
	
	# Side dials
	draw_circle(Vector2(tv_rect.position.x - 4, center.y), 7.0, Color(0.30, 0.34, 0.38))
	draw_circle(Vector2(tv_rect.end.x + 4, center.y), 7.0, Color(0.30, 0.34, 0.38))
	
	# Casing
	var style_casing = StyleBoxFlat.new()
	style_casing.bg_color = Color(0.24, 0.76, 0.48) # Mint green
	style_casing.border_color = Color(0.18, 0.62, 0.38)
	style_casing.set_border_width_all(3)
	style_casing.set_corner_radius_all(14)
	style_casing.draw(get_canvas_item(), tv_rect)
	
	# Screen
	var screen_rect = Rect2(tv_rect.position.x + 8, tv_rect.position.y + 8, tv_rect.size.x - 16, tv_rect.size.y - 16)
	var style_screen = StyleBoxFlat.new()
	style_screen.bg_color = Color(0.74, 0.88, 0.85)
	style_screen.border_color = Color(0.55, 0.74, 0.70)
	style_screen.set_border_width_all(2)
	style_screen.set_corner_radius_all(10)
	style_screen.draw(get_canvas_item(), screen_rect)
	
	var s_center = screen_rect.get_center()
	var eye_y = s_center.y - 5.0
	var left_eye_x = s_center.x - 18.0
	var right_eye_x = s_center.x + 18.0
	
	if is_blinking:
		draw_line(Vector2(left_eye_x - 6, eye_y), Vector2(left_eye_x + 6, eye_y), Color(0.12, 0.14, 0.18), 3.0)
		draw_line(Vector2(right_eye_x - 6, eye_y), Vector2(right_eye_x + 6, eye_y), Color(0.12, 0.14, 0.18), 3.0)
	else:
		draw_circle(Vector2(left_eye_x, eye_y), 5.0, Color(0.12, 0.14, 0.18))
		draw_circle(Vector2(left_eye_x - 1.2, eye_y - 1.2), 1.6, Color(1, 1, 1, 0.9))
		draw_circle(Vector2(right_eye_x, eye_y), 5.0, Color(0.12, 0.14, 0.18))
		draw_circle(Vector2(right_eye_x - 1.2, eye_y - 1.2), 1.6, Color(1, 1, 1, 0.9))
		
	# Blush
	draw_circle(Vector2(left_eye_x - 9, eye_y + 8), 4.5, Color(0.20, 0.85, 0.50, 0.6))
	draw_circle(Vector2(right_eye_x + 9, eye_y + 8), 4.5, Color(0.20, 0.85, 0.50, 0.6))
	
	# Mouth
	var mouth_y = s_center.y + 8.0
	if mouth_open > 0.15:
		var open_h = 4.0 + mouth_open * 8.0
		var open_w = 10.0 + mouth_open * 5.0
		draw_rect(Rect2(s_center.x - open_w * 0.5, mouth_y - open_h * 0.5 + 2.0, open_w, open_h), Color(0.12, 0.14, 0.18))
	else:
		draw_line(Vector2(s_center.x - 7, mouth_y), Vector2(s_center.x + 7, mouth_y), Color(0.12, 0.14, 0.18), 3.0)
