extends Control

@onready var play_btn: Button = %PlayBtn
@onready var lvl1_btn: Button = %Lvl1Btn
@onready var lvl2_btn: Button = %Lvl2Btn
@onready var lvl3_btn: Button = %Lvl3Btn
@onready var rules_btn: Button = %RulesBtn
@onready var quit_btn: Button = %QuitBtn
@onready var rules_dialog: Panel = %RulesPanel
@onready var close_rules_btn: Button = %CloseRulesBtn
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	play_btn.pressed.connect(_on_play_pressed)
	lvl1_btn.pressed.connect(func(): _load_level(1))
	lvl2_btn.pressed.connect(func(): _load_level(2))
	lvl3_btn.pressed.connect(func(): _load_level(3))
	rules_btn.pressed.connect(_show_rules)
	quit_btn.pressed.connect(_on_quit_pressed)
	close_rules_btn.pressed.connect(_hide_rules)
	rules_dialog.visible = false
	
	if ResourceLoader.exists("res://audio/loading_screen.mp3"):
		var music = load("res://audio/loading_screen.mp3")
		if music and audio_player:
			audio_player.stream = music
			audio_player.play()

func _on_play_pressed() -> void:
	if GameManager:
		GameManager.start_new_game()

func _load_level(idx: int) -> void:
	if GameManager:
		GameManager.load_level(idx)

func _show_rules() -> void:
	rules_dialog.visible = true

func _hide_rules() -> void:
	rules_dialog.visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()
