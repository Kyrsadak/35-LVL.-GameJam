class_name CrtTvOffEffect
extends CanvasLayer

## Old CRT TV Power-Off Screen Collapse Effect & Transition to Main Menu (1.2s total)

@onready var color_rect: ColorRect = $ColorRect

var mat: ShaderMaterial

func _ready() -> void:
	layer = 125
	process_mode = Node.PROCESS_MODE_ALWAYS
	if color_rect and color_rect.material is ShaderMaterial:
		mat = color_rect.material as ShaderMaterial
		mat.set_shader_parameter("collapse_v", 0.0)
		mat.set_shader_parameter("collapse_h", 0.0)
		mat.set_shader_parameter("dot_fade", 0.0)
		mat.set_shader_parameter("flash", 0.0)
	visible = false

func play_effect(callback: Callable = Callable()) -> void:
	visible = true
	if not mat and color_rect and color_rect.material is ShaderMaterial:
		mat = color_rect.material as ShaderMaterial
	
	if SoundManager:
		SoundManager.play_tv_off()

	var tween = create_tween().set_trans(Tween.TRANS_CUBIC)
	
	# Step 0: Quick initial discharge flash (0.04s)
	tween.tween_method(func(val): mat.set_shader_parameter("flash", val), 0.0, 0.5, 0.03)
	tween.tween_method(func(val): mat.set_shader_parameter("flash", val), 0.5, 0.0, 0.03)
	
	# Step 1: Rapid vertical collapse into horizontal scanline beam (0.24s)
	tween.tween_method(func(val): mat.set_shader_parameter("collapse_v", val), 0.0, 1.0, 0.24).set_ease(Tween.EASE_IN)
	
	# Step 2: Horizontal collapse into center phosphor dot (0.24s)
	tween.tween_method(func(val): mat.set_shader_parameter("collapse_h", val), 0.0, 1.0, 0.24).set_ease(Tween.EASE_IN)
	
	# Step 3: Phosphor dot extinguishes into complete blackness (0.28s)
	tween.tween_method(func(val): mat.set_shader_parameter("dot_fade", val), 0.0, 1.0, 0.28).set_ease(Tween.EASE_OUT)
	
	# Step 4: Quick black pulse / CRT shutter blink before transition (0.25s)
	tween.tween_interval(0.25)
	
	# Step 5: Smoothly load the main menu
	tween.tween_callback(func():
		if callback.is_valid():
			callback.call()
		else:
			get_tree().change_scene_to_file("res://ui/main_menu.tscn")
	)
