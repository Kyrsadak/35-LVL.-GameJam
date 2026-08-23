class_name CrtTvOffEffect
extends CanvasLayer

## Pure Black CRT TV Power-Off Screen Collapse Effect & Transition to Main Menu

@onready var top_shutter: ColorRect = $TopShutter
@onready var bottom_shutter: ColorRect = $BottomShutter
@onready var left_shutter: ColorRect = $LeftShutter
@onready var right_shutter: ColorRect = $RightShutter
@onready var center_beam: ColorRect = $CenterBeam
@onready var center_dot: ColorRect = $CenterDot
@onready var blackout: ColorRect = $Blackout

func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_reset_elements()

func _reset_elements() -> void:
	var vp_size = get_viewport().get_visible_rect().size
	if vp_size.x <= 0: vp_size = Vector2(1280, 720)
	
	# Initial open state
	top_shutter.position = Vector2.ZERO
	top_shutter.size = Vector2(vp_size.x, 0)
	
	bottom_shutter.position = Vector2(0, vp_size.y)
	bottom_shutter.size = Vector2(vp_size.x, 0)
	
	left_shutter.position = Vector2.ZERO
	left_shutter.size = Vector2(0, vp_size.y)
	
	right_shutter.position = Vector2(vp_size.x, 0)
	right_shutter.size = Vector2(0, vp_size.y)
	
	center_beam.visible = false
	center_beam.position = Vector2(0, vp_size.y * 0.5 - 2)
	center_beam.size = Vector2(vp_size.x, 4)
	center_beam.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	center_dot.visible = false
	center_dot.position = Vector2(vp_size.x * 0.5 - 4, vp_size.y * 0.5 - 4)
	center_dot.size = Vector2(8, 8)
	center_dot.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	blackout.visible = false
	blackout.size = vp_size

func play_effect(callback: Callable = Callable()) -> void:
	var vp_size = get_viewport().get_visible_rect().size
	if vp_size.x <= 0: vp_size = Vector2(1280, 720)
	_reset_elements()
	
	if SoundManager:
		SoundManager.play_tv_off()

	center_beam.visible = true
	var half_h = vp_size.y * 0.5
	var half_w = vp_size.x * 0.5

	var tween = create_tween().set_trans(Tween.TRANS_CUBIC)
	
	# Phase 1: Vertical collapse into thin horizontal scanline (0.24s)
	tween.parallel().tween_property(top_shutter, "size:y", half_h - 2.0, 0.24).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(bottom_shutter, "position:y", half_h + 2.0, 0.24).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(bottom_shutter, "size:y", half_h, 0.24).set_ease(Tween.EASE_IN)
	
	# Phase 2: Horizontal collapse into center phosphor point (0.24s)
	tween.chain().tween_callback(func():
		center_dot.visible = true
	)
	tween.parallel().tween_property(left_shutter, "size:x", half_w - 4.0, 0.24).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(right_shutter, "position:x", half_w + 4.0, 0.24).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(right_shutter, "size:x", half_w, 0.24).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(center_beam, "size:x", 8.0, 0.24).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(center_beam, "position:x", half_w - 4.0, 0.24).set_ease(Tween.EASE_IN)

	# Phase 3: Center phosphor dot fades out into darkness (0.28s)
	tween.chain().tween_property(center_dot, "modulate:a", 0.0, 0.28).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(center_beam, "modulate:a", 0.0, 0.28).set_ease(Tween.EASE_OUT)
	
	# Phase 4: Full pitch black screen blink pause (0.25s)
	tween.chain().tween_callback(func():
		blackout.visible = true
	)
	tween.tween_interval(0.25)
	
	# Phase 5: Smoothly load main menu and clean up
	tween.tween_callback(func():
		if callback.is_valid():
			callback.call()
		else:
			get_tree().change_scene_to_file("res://ui/main_menu.tscn")
		queue_free()
	)
