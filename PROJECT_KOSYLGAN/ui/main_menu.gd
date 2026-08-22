class_name MainMenu
extends Control

@onready var play_btn: Button = %PlayBtn
@onready var lvl1_btn: Button = %Lvl1Btn
@onready var lvl2_btn: Button = %Lvl2Btn
@onready var lvl3_btn: Button = %Lvl3Btn
@onready var rules_btn: Button = %RulesBtn
@onready var quit_btn: Button = %QuitBtn
@onready var rules_dialog: PanelContainer = %RulesPanel
@onready var close_rules_btn: Button = %CloseRulesBtn
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var bg_canvas: Control = %BackgroundCanvas
@onready var hero_container: Control = %HeroContainer

var anim_timer: float = 0.0
var particles: Array[Dictionary] = []

func _ready() -> void:
	# Wire Buttons
	play_btn.pressed.connect(_on_play_pressed)
	lvl1_btn.pressed.connect(func(): _load_level(1))
	lvl2_btn.pressed.connect(func(): _load_level(2))
	lvl3_btn.pressed.connect(func(): _load_level(3))
	rules_btn.pressed.connect(_show_rules)
	quit_btn.pressed.connect(_on_quit_pressed)
	close_rules_btn.pressed.connect(_hide_rules)
	rules_dialog.visible = false
	
	# Connect UI hover sounds to all buttons
	var all_buttons = [play_btn, lvl1_btn, lvl2_btn, lvl3_btn, rules_btn, quit_btn, close_rules_btn]
	for b in all_buttons:
		if b:
			b.mouse_entered.connect(_on_button_hovered.bind(b))
			b.pressed.connect(_on_button_clicked)

	# Initialize background floating cyber particles
	for i in range(40):
		particles.append({
			"pos": Vector2(randf(), randf()),
			"speed": randf_range(0.015, 0.045),
			"size": randf_range(2.0, 4.5),
			"alpha": randf_range(0.2, 0.75),
			"color": Color(0.0, 0.9, 1.0) if randf() > 0.45 else Color(1.0, 0.65, 0.1)
		})

	# Start Menu Music
	if audio_player:
		var stream = load("res://audio/loading_screen.mp3")
		if stream:
			audio_player.stream = stream
			audio_player.volume_db = -6.0
			audio_player.play()
			
	# Smooth Hero Entrance Animation
	if hero_container:
		hero_container.modulate.a = 0.0
		hero_container.scale = Vector2(0.96, 0.96)
		hero_container.pivot_offset = Vector2(500, 350)
		var t = create_tween().set_parallel(true)
		t.tween_property(hero_container, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		t.tween_property(hero_container, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	anim_timer += delta
	if bg_canvas:
		bg_canvas.queue_redraw()

func _on_bg_canvas_draw() -> void:
	if not bg_canvas:
		return
	var size = bg_canvas.get_size()
	
	# 1. Deep Space Cyber Radial Gradient
	var center = size * 0.5
	var bg_col_dark = Color(0.04, 0.06, 0.10, 1.0)
	var bg_col_edge = Color(0.015, 0.025, 0.04, 1.0)
	bg_canvas.draw_rect(Rect2(Vector2.ZERO, size), bg_col_edge, true)
	
	# Atlas Left Cyan Glow Aura
	var cyan_glow = Color(0.0, 0.8, 1.0, 0.06 + 0.02 * sin(anim_timer * 2.0))
	bg_canvas.draw_circle(Vector2(size.x * 0.25, size.y * 0.5), size.y * 0.45, cyan_glow)
	
	# Cipher Right Amber Glow Aura
	var amber_glow = Color(1.0, 0.55, 0.05, 0.06 + 0.02 * cos(anim_timer * 2.2))
	bg_canvas.draw_circle(Vector2(size.x * 0.75, size.y * 0.5), size.y * 0.45, amber_glow)
	
	# 2. Isometric Perspective Grid Lines
	var grid_color = Color(0.12, 0.22, 0.35, 0.22)
	var grid_step = 60.0
	var offset_y = fmod(anim_timer * 15.0, grid_step)
	for x in range(0, int(size.x) + int(grid_step), int(grid_step)):
		bg_canvas.draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)
	for y in range(0, int(size.y) + int(grid_step), int(grid_step)):
		var actual_y = y + offset_y
		if actual_y <= size.y:
			bg_canvas.draw_line(Vector2(0, actual_y), Vector2(size.x, actual_y), grid_color, 1.0)

	# 3. Floating Cyber Particle Sparks
	for p in particles:
		p.pos.y -= p.speed * 0.016
		if p.pos.y < 0.0:
			p.pos.y = 1.0
			p.pos.x = randf()
		
		var px = p.pos.x * size.x
		var py = p.pos.y * size.y
		var pulse = 0.7 + 0.3 * sin(anim_timer * 3.0 + p.speed * 100.0)
		var p_col = p.color * Color(1, 1, 1, p.alpha * pulse)
		bg_canvas.draw_circle(Vector2(px, py), p.size, p_col)

func _on_button_hovered(btn: Button) -> void:
	if SoundManager and SoundManager.has_method("play_ui_hover"):
		SoundManager.play_ui_hover()
	# Subtle scale punch
	var t = create_tween()
	t.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.12).set_trans(Tween.TRANS_QUAD)

func _on_button_clicked() -> void:
	if SoundManager and SoundManager.has_method("play_ui_click"):
		SoundManager.play_ui_click()

func _on_play_pressed() -> void:
	_animate_launch(func():
		if GameManager:
			GameManager.start_new_game()
	)

func _load_level(idx: int) -> void:
	_animate_launch(func():
		if GameManager:
			GameManager.load_level(idx)
	)

func _animate_launch(callback: Callable) -> void:
	var t = create_tween().set_parallel(true)
	t.tween_property(self, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "scale", Vector2(1.05, 1.05), 0.4).set_trans(Tween.TRANS_CUBIC)
	t.chain().tween_callback(callback)

func _show_rules() -> void:
	rules_dialog.visible = true
	rules_dialog.modulate.a = 0.0
	rules_dialog.scale = Vector2(0.92, 0.92)
	rules_dialog.pivot_offset = rules_dialog.size / 2.0
	var t = create_tween().set_parallel(true)
	t.tween_property(rules_dialog, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(rules_dialog, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _hide_rules() -> void:
	var t = create_tween().set_parallel(true)
	t.tween_property(rules_dialog, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(rules_dialog, "scale", Vector2(0.92, 0.92), 0.2).set_trans(Tween.TRANS_CUBIC)
	t.chain().tween_callback(func(): rules_dialog.visible = false)

func _on_quit_pressed() -> void:
	get_tree().quit()
