extends Control

@onready var time_label: Label = %TimeLabel
@onready var replay_btn: Button = %ReplayBtn
@onready var menu_btn: Button = %MenuBtn

func _ready() -> void:
	if GameManager:
		var total_secs = int(GameManager.total_game_time)
		var mins = total_secs / 60
		var secs = total_secs % 60
		time_label.text = "⏱️ Время выполнения миссии: %02d:%02d" % [mins, secs]

	replay_btn.pressed.connect(_on_replay_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)

func _on_replay_pressed() -> void:
	if GameManager:
		GameManager.start_new_game()

func _on_menu_pressed() -> void:
	if GameManager:
		GameManager.return_to_main_menu()
