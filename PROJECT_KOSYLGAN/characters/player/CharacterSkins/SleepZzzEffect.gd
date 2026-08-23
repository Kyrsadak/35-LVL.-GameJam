class_name SleepZzzEffect
extends Node3D

## Animated 3D Floating "Z z z" Sleep Effect
## Creates billboarded anime sleeping bubbles drifting upward in a sine-wave curve.

@export var is_active: bool = false
@export var theme_color: Color = Color(0.40, 0.85, 1.0) # Soft cyan/blue

var z_labels: Array[Label3D] = []
var time_offsets: Array[float] = [0.0, 0.7, 1.4]
var cycle_duration: float = 2.1
var anim_timer: float = 0.0

func _ready() -> void:
	# Create 3 floating Label3D instances
	var letters = ["z", "Z", "Z"]
	var sizes = [36, 44, 54]
	
	for i in range(3):
		var lbl = Label3D.new()
		lbl.text = letters[i]
		lbl.font_size = sizes[i]
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test = true
		lbl.render_priority = 15
		lbl.outline_render_priority = 14
		lbl.outline_size = 10
		lbl.outline_modulate = Color(0.12, 0.14, 0.20, 0.9)
		lbl.modulate = theme_color
		lbl.modulate.a = 0.0
		lbl.position = Vector3.ZERO
		add_child(lbl)
		z_labels.append(lbl)
		
	visible = is_active

func set_active(active: bool) -> void:
	is_active = active
	visible = is_active
	if not is_active:
		anim_timer = 0.0
		for lbl in z_labels:
			lbl.modulate.a = 0.0

func _process(delta: float) -> void:
	if not is_active:
		return
		
	anim_timer += delta
	
	for i in range(z_labels.size()):
		var lbl = z_labels[i]
		var t_local = fmod(anim_timer + time_offsets[i], cycle_duration)
		var progress = t_local / cycle_duration # 0.0 -> 1.0
		
		# Upward and gentle swaying S-curve drift
		var base_x = (float(i) - 1.0) * 0.15 + sin(t_local * 3.2) * 0.18 + progress * 0.35
		var base_y = progress * 1.10
		var base_z = cos(t_local * 2.8) * 0.08
		lbl.position = Vector3(base_x, base_y, base_z)
		
		# Alpha envelope: fade in quick, fade out near the top
		var alpha: float = 0.0
		if progress < 0.20:
			alpha = progress / 0.20
		elif progress > 0.65:
			alpha = 1.0 - ((progress - 0.65) / 0.35)
		else:
			alpha = 1.0
			
		lbl.modulate = theme_color
		lbl.modulate.a = alpha * 0.95
		
		# Dynamic scale breathing
		var s = lerp(0.6, 1.15, progress)
		lbl.scale = Vector3.ONE * s
