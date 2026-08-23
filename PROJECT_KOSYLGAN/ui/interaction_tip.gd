extends Node3D
## InteractionTip — показывает подсказку "Нажми E для взаимодействия"
## Появляется над интерактивными объектами

@export var tip_text: String = "E — взаимодействие"
@export var auto_show: bool = true

var _label: Label3D = null

func _ready() -> void:
	_label = Label3D.new()
	_label.text = tip_text
	_label.font_size = 36
	_label.modulate = Color(1.0, 0.92, 0.3, 1.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.position = Vector3(0, 1.6, 0)
	_label.outline_size = 12
	_label.outline_modulate = Color(0.05, 0.05, 0.05, 0.85)
	add_child(_label)
	
	if auto_show:
		_label.visible = false

func show_tip() -> void:
	if _label:
		_label.visible = true

func hide_tip() -> void:
	if _label:
		_label.visible = false

func set_tip_text(text: String) -> void:
	tip_text = text
	if _label:
		_label.text = text
