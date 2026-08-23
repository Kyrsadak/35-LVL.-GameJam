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
	custom_minimum_size = Vector2(110, 110)
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

func _draw_catgirl_portrait(center: Vector2, w: float, h: float) -> void:
	var tv_w = 78.0
	var tv_h = 62.0
	var tv_rect = Rect2(center.x - tv_w * 0.5, center.y - tv_h * 0.5, tv_w, tv_h)
	
	# 1. Cat Ears on Top
	var ear_base_y = tv_rect.position.y + 4.0
	var left_ear_root = Vector2(tv_rect.position.x + 12.0, ear_base_y)
	var right_ear_root = Vector2(tv_rect.end.x - 12.0, ear_base_y)
	
	# Left Ear with subtle talking wiggle
	var l_tip = left_ear_root + Vector2(-10.0, -26.0).rotated(ear_wiggle_angle)
	var l_pts = PackedVector2Array([
		left_ear_root + Vector2(-8, 0),
		l_tip,
		left_ear_root + Vector2(12, 0)
	])
	draw_colored_polygon(l_pts, Color(0.95, 0.52, 0.68)) # Pink casing
	var l_inner = PackedVector2Array([
		left_ear_root + Vector2(-4, -2),
		l_tip + Vector2(2, 6),
		left_ear_root + Vector2(8, -2)
	])
	draw_colored_polygon(l_inner, Color(1.0, 0.82, 0.88)) # Light pink inner
	
	# Right Ear
	var r_tip = right_ear_root + Vector2(10.0, -26.0).rotated(-ear_wiggle_angle)
	var r_pts = PackedVector2Array([
		right_ear_root + Vector2(-12, 0),
		r_tip,
		right_ear_root + Vector2(8, 0)
	])
	draw_colored_polygon(r_pts, Color(0.95, 0.52, 0.68))
	var r_inner = PackedVector2Array([
		right_ear_root + Vector2(-8, -2),
		r_tip + Vector2(-2, 6),
		right_ear_root + Vector2(4, -2)
	])
	draw_colored_polygon(r_inner, Color(1.0, 0.82, 0.88))
	
	# Side antenna / plug socket on right
	draw_circle(Vector2(tv_rect.end.x + 4, center.y - 4), 5.0, Color(0.35, 0.38, 0.45))
	draw_line(Vector2(tv_rect.end.x + 4, center.y - 4), Vector2(tv_rect.end.x + 14, center.y - 18), Color(0.2, 0.22, 0.26), 3.0)
	draw_rect(Rect2(tv_rect.end.x + 11, center.y - 24, 8, 6), Color(0.95, 0.52, 0.68))
	
	# 2. CRT Monitor Casing (Cute rounded rectangle)
	var style_casing = StyleBoxFlat.new()
	style_casing.bg_color = Color(0.95, 0.52, 0.68) # Pastel Hot Pink
	style_casing.border_color = Color(0.82, 0.36, 0.52)
	style_casing.set_border_width_all(3)
	style_casing.set_corner_radius_all(14)
	style_casing.shadow_color = Color(0, 0, 0, 0.4)
	style_casing.shadow_size = 6
	style_casing.draw(get_canvas_item(), tv_rect)
	
	# 3. CRT Screen (Pale cyan glass)
	var screen_rect = Rect2(tv_rect.position.x + 6, tv_rect.position.y + 6, tv_rect.size.x - 12, tv_rect.size.y - 12)
	var style_screen = StyleBoxFlat.new()
	style_screen.bg_color = Color(0.82, 0.94, 0.92) # Soft mint cyan
	style_screen.border_color = Color(0.68, 0.82, 0.80)
	style_screen.set_border_width_all(2)
	style_screen.set_corner_radius_all(9)
	style_screen.draw(get_canvas_item(), screen_rect)
	
	# Corner LED indicator
	draw_rect(Rect2(screen_rect.end.x - 7, screen_rect.position.y + 5, 3, 3), Color(0.2, 0.95, 0.5))
	
	var s_center = screen_rect.get_center()
	
	# 4. Cute Catgirl Anime Face
	var eye_y = s_center.y - 4.0
	var left_eye_x = s_center.x - 15.0
	var right_eye_x = s_center.x + 15.0
	
	if is_blinking:
		# Happy blink ^ ^
		draw_line(Vector2(left_eye_x - 6, eye_y), Vector2(left_eye_x, eye_y - 4), Color(0.15, 0.16, 0.20), 2.5)
		draw_line(Vector2(left_eye_x, eye_y - 4), Vector2(left_eye_x + 6, eye_y), Color(0.15, 0.16, 0.20), 2.5)
		
		draw_line(Vector2(right_eye_x - 6, eye_y), Vector2(right_eye_x, eye_y - 4), Color(0.15, 0.16, 0.20), 2.5)
		draw_line(Vector2(right_eye_x, eye_y - 4), Vector2(right_eye_x + 6, eye_y), Color(0.15, 0.16, 0.20), 2.5)
	else:
		# Round cute eyes with white highlight
		draw_circle(Vector2(left_eye_x, eye_y), 4.5, Color(0.15, 0.16, 0.20))
		draw_circle(Vector2(left_eye_x - 1.2, eye_y - 1.5), 1.6, Color(1, 1, 1, 0.9))
		
		draw_circle(Vector2(right_eye_x, eye_y), 4.5, Color(0.15, 0.16, 0.20))
		draw_circle(Vector2(right_eye_x - 1.2, eye_y - 1.5), 1.6, Color(1, 1, 1, 0.9))
		
	# Cute Pink Blush on Cheeks
	draw_circle(Vector2(left_eye_x - 8, eye_y + 6), 4.0, Color(1.0, 0.45, 0.55, 0.55))
	draw_circle(Vector2(right_eye_x + 8, eye_y + 6), 4.0, Color(1.0, 0.45, 0.55, 0.55))
	
	# Whiskers
	draw_line(Vector2(left_eye_x - 11, eye_y + 4), Vector2(left_eye_x - 20, eye_y + 2), Color(0.2, 0.25, 0.3, 0.6), 1.5)
	draw_line(Vector2(left_eye_x - 11, eye_y + 8), Vector2(left_eye_x - 20, eye_y + 9), Color(0.2, 0.25, 0.3, 0.6), 1.5)
	draw_line(Vector2(right_eye_x + 11, eye_y + 4), Vector2(right_eye_x + 20, eye_y + 2), Color(0.2, 0.25, 0.3, 0.6), 1.5)
	draw_line(Vector2(right_eye_x + 11, eye_y + 8), Vector2(right_eye_x + 20, eye_y + 9), Color(0.2, 0.25, 0.3, 0.6), 1.5)
	
	# 5. Dynamic Talking Mouth!
	var mouth_y = s_center.y + 7.0
	if mouth_open > 0.15:
		# Open talking mouth (cute animated oval / open D)
		var open_h = 3.0 + mouth_open * 7.5
		var open_w = 6.0 + mouth_open * 4.0
		var m_rect = Rect2(s_center.x - open_w * 0.5, mouth_y - open_h * 0.5 + 2.0, open_w, open_h)
		draw_rect(m_rect, Color(0.15, 0.16, 0.20), true, -1.0)
		# Cute tongue inside
		if open_h > 5.0:
			draw_circle(Vector2(s_center.x, m_rect.end.y - 2.0), open_w * 0.35, Color(1.0, 0.5, 0.6))
	else:
		# Closed cute cat mouth 'ω'
		var pts_l = PackedVector2Array([
			Vector2(s_center.x - 6, mouth_y),
			Vector2(s_center.x - 3, mouth_y + 2.5),
			Vector2(s_center.x, mouth_y)
		])
		var pts_r = PackedVector2Array([
			Vector2(s_center.x, mouth_y),
			Vector2(s_center.x + 3, mouth_y + 2.5),
			Vector2(s_center.x + 6, mouth_y)
		])
		draw_polyline(pts_l, Color(0.15, 0.16, 0.20), 2.0)
		draw_polyline(pts_r, Color(0.15, 0.16, 0.20), 2.0)

func _draw_atlas_portrait(center: Vector2, w: float, h: float) -> void:
	var tv_w = 78.0
	var tv_h = 62.0
	var tv_rect = Rect2(center.x - tv_w * 0.5, center.y - tv_h * 0.5, tv_w, tv_h)
	
	# Side dials
	draw_circle(Vector2(tv_rect.position.x - 3, center.y), 6.0, Color(0.32, 0.36, 0.40))
	draw_circle(Vector2(tv_rect.end.x + 3, center.y), 6.0, Color(0.32, 0.36, 0.40))
	
	# Casing
	var style_casing = StyleBoxFlat.new()
	style_casing.bg_color = Color(0.91, 0.47, 0.39) # Coral orange
	style_casing.border_color = Color(0.78, 0.35, 0.28)
	style_casing.set_border_width_all(3)
	style_casing.set_corner_radius_all(12)
	style_casing.draw(get_canvas_item(), tv_rect)
	
	# Screen
	var screen_rect = Rect2(tv_rect.position.x + 6, tv_rect.position.y + 6, tv_rect.size.x - 12, tv_rect.size.y - 12)
	var style_screen = StyleBoxFlat.new()
	style_screen.bg_color = Color(0.77, 0.84, 0.83)
	style_screen.border_color = Color(0.60, 0.70, 0.68)
	style_screen.set_border_width_all(2)
	style_screen.set_corner_radius_all(8)
	style_screen.draw(get_canvas_item(), screen_rect)
	
	var s_center = screen_rect.get_center()
	var eye_y = s_center.y - 4.0
	var left_eye_x = s_center.x - 14.0
	var right_eye_x = s_center.x + 14.0
	
	if is_blinking:
		draw_line(Vector2(left_eye_x - 5, eye_y), Vector2(left_eye_x + 5, eye_y), Color(0.12, 0.14, 0.18), 2.5)
		draw_line(Vector2(right_eye_x - 5, eye_y), Vector2(right_eye_x + 5, eye_y), Color(0.12, 0.14, 0.18), 2.5)
	else:
		draw_circle(Vector2(left_eye_x, eye_y), 4.0, Color(0.12, 0.14, 0.18))
		draw_circle(Vector2(left_eye_x - 1, eye_y - 1), 1.4, Color(1, 1, 1, 0.9))
		draw_circle(Vector2(right_eye_x, eye_y), 4.0, Color(0.12, 0.14, 0.18))
		draw_circle(Vector2(right_eye_x - 1, eye_y - 1), 1.4, Color(1, 1, 1, 0.9))
		
	# Blush
	draw_circle(Vector2(left_eye_x - 7, eye_y + 6), 3.5, Color(0.92, 0.45, 0.40, 0.6))
	draw_circle(Vector2(right_eye_x + 7, eye_y + 6), 3.5, Color(0.92, 0.45, 0.40, 0.6))
	
	# Mouth
	var mouth_y = s_center.y + 6.0
	if mouth_open > 0.15:
		var open_h = 3.0 + mouth_open * 6.0
		var open_w = 8.0 + mouth_open * 4.0
		draw_rect(Rect2(s_center.x - open_w * 0.5, mouth_y - open_h * 0.5 + 2.0, open_w, open_h), Color(0.12, 0.14, 0.18))
	else:
		draw_line(Vector2(s_center.x - 5, mouth_y), Vector2(s_center.x + 5, mouth_y), Color(0.12, 0.14, 0.18), 2.5)

func _draw_cipher_portrait(center: Vector2, w: float, h: float) -> void:
	var tv_w = 78.0
	var tv_h = 62.0
	var tv_rect = Rect2(center.x - tv_w * 0.5, center.y - tv_h * 0.5, tv_w, tv_h)
	
	# Side dials
	draw_circle(Vector2(tv_rect.position.x - 3, center.y), 6.0, Color(0.30, 0.34, 0.38))
	draw_circle(Vector2(tv_rect.end.x + 3, center.y), 6.0, Color(0.30, 0.34, 0.38))
	
	# Casing
	var style_casing = StyleBoxFlat.new()
	style_casing.bg_color = Color(0.24, 0.76, 0.48) # Mint green
	style_casing.border_color = Color(0.18, 0.62, 0.38)
	style_casing.set_border_width_all(3)
	style_casing.set_corner_radius_all(12)
	style_casing.draw(get_canvas_item(), tv_rect)
	
	# Screen
	var screen_rect = Rect2(tv_rect.position.x + 6, tv_rect.position.y + 6, tv_rect.size.x - 12, tv_rect.size.y - 12)
	var style_screen = StyleBoxFlat.new()
	style_screen.bg_color = Color(0.74, 0.88, 0.85)
	style_screen.border_color = Color(0.55, 0.74, 0.70)
	style_screen.set_border_width_all(2)
	style_screen.set_corner_radius_all(8)
	style_screen.draw(get_canvas_item(), screen_rect)
	
	var s_center = screen_rect.get_center()
	var eye_y = s_center.y - 4.0
	var left_eye_x = s_center.x - 14.0
	var right_eye_x = s_center.x + 14.0
	
	if is_blinking:
		draw_line(Vector2(left_eye_x - 5, eye_y), Vector2(left_eye_x + 5, eye_y), Color(0.12, 0.14, 0.18), 2.5)
		draw_line(Vector2(right_eye_x - 5, eye_y), Vector2(right_eye_x + 5, eye_y), Color(0.12, 0.14, 0.18), 2.5)
	else:
		draw_circle(Vector2(left_eye_x, eye_y), 4.0, Color(0.12, 0.14, 0.18))
		draw_circle(Vector2(left_eye_x - 1, eye_y - 1), 1.4, Color(1, 1, 1, 0.9))
		draw_circle(Vector2(right_eye_x, eye_y), 4.0, Color(0.12, 0.14, 0.18))
		draw_circle(Vector2(right_eye_x - 1, eye_y - 1), 1.4, Color(1, 1, 1, 0.9))
		
	# Blush
	draw_circle(Vector2(left_eye_x - 7, eye_y + 6), 3.5, Color(0.20, 0.85, 0.50, 0.6))
	draw_circle(Vector2(right_eye_x + 7, eye_y + 6), 3.5, Color(0.20, 0.85, 0.50, 0.6))
	
	# Mouth
	var mouth_y = s_center.y + 6.0
	if mouth_open > 0.15:
		var open_h = 3.0 + mouth_open * 6.0
		var open_w = 8.0 + mouth_open * 4.0
		draw_rect(Rect2(s_center.x - open_w * 0.5, mouth_y - open_h * 0.5 + 2.0, open_w, open_h), Color(0.12, 0.14, 0.18))
	else:
		draw_line(Vector2(s_center.x - 5, mouth_y), Vector2(s_center.x + 5, mouth_y), Color(0.12, 0.14, 0.18), 2.5)
