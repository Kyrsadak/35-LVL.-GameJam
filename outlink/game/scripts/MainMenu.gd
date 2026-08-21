# res://game/scripts/MainMenu.gd
extends Control

## Главное меню игры.

@onready var start_button: Button = $Panel/VBox/StartButton
@onready var levels_container: VBoxContainer = $Panel/VBox/LevelsContainer
@onready var quit_button: Button = $Panel/VBox/QuitButton
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var subtitle_label: Label = $Panel/VBox/SubtitleLabel
@onready var controls_label: Label = $Panel/VBox/ControlsLabel

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Кнопки быстрого выбора уровня (для отладки/удобства)
	for i in range(GameManager.LEVELS.size()):
		var btn := Button.new()
		btn.text = "► " + GameManager.get_level_name(i)
		btn.custom_minimum_size = Vector2(320, 36)
		btn.pressed.connect(_on_level_pressed.bind(i))
		levels_container.add_child(btn)

	# Анимация заголовка — лёгкая пульсация
	var tw := create_tween().set_loops()
	tw.tween_property(title_label, "modulate", Color(0.5, 1.0, 0.8, 1.0), 1.6)
	tw.tween_property(title_label, "modulate", Color(1.0, 0.85, 0.3, 1.0), 1.6)

func _on_start_pressed() -> void:
	AudioManager.play_ui_click()
	GameManager.start_new_game()

func _on_level_pressed(idx: int) -> void:
	AudioManager.play_ui_click()
	GameManager.load_level(idx)

func _on_quit_pressed() -> void:
	AudioManager.play_ui_click()
	get_tree().quit()
