class_name CrtTvOffEffect
extends CanvasLayer

## Old CRT TV Power-Off Screen Collapse Effect & Transition to Main Menu

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
	
	# Step 0: Quick phosphor power-down flash
	tween.tween_method(func(val): mat.set_shader_parameter("flash", val), 0.0, 0.4, 0.05)
	tween.tween_method(func(val): mat.set_shader_parameter("flash", val), 0.4, 0.0, 0.05)
	
	# Step 1: Vertical collapse into horizontal scanning line (0.32s)
	tween.tween_method(func(val): mat.set_shader_parameter("collapse_v", val), 0.0, 1.0, 0.32).set_ease(Tween.EASE_IN)
	
	# Step 2: Horizontal collapse into center phosphor dot (0.35s)
	tween.tween_method(func(val): mat.set_shader_parameter("collapse_h", val), 0.0, 1.0, 0.35).set_ease(Tween.EASE_IN)
	
	# Step 3: Phosphor dot fade out into complete darkness (0.55s)
	tween.tween_method(func(val): mat.set_shader_parameter("dot_fade", val), 0.0, 1.0, 0.55).set_ease(Tween.EASE_OUT)
	
	# Step 4: Short black pause before transition (0.35s)
	tween.tween_interval(0.35)
	
	tween.tween_callback(func():
		if callback.is_valid():
			callback.call()
		else:
			get_tree().change_scene_to_file("res://ui/main_menu.tscn")
	)
