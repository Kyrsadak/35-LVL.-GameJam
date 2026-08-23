extends Control

@onready var white_flash = $WhiteFlash
@onready var captcha_window = $CaptchaCard
@onready var checkbox = $CaptchaCard/VBox/CheckboxArea/Checkbox
@onready var spinner = $CaptchaCard/VBox/CheckboxArea/Spinner
@onready var check_mark = $CaptchaCard/VBox/CheckboxArea/CheckMark
@onready var status_label = $CaptchaCard/VBox/StatusLabel
@onready var dialog_box = $DialogBox
@onready var speaker_name = $DialogBox/Margin/VBox/SpeakerName
@onready var dialog_text = $DialogBox/Margin/VBox/DialogText
@onready var next_dialog_btn = $DialogBox/Margin/VBox/NextBtn
@onready var victory_panel = $VictoryPanel
@onready var victory_stats = $VictoryPanel/VBox/StatsLabel
@onready var main_menu_btn = $VictoryPanel/VBox/MainMenuBtn

var dialog_step: int = 0
var dialog_lines = [
	{"speaker": "🤖 ATLAS (DAU)", "text": "Погоди секунду... Мы же буквально роботы из стали и титана. КТО ПОСТАВИЛ КАПЧУ НА ВЫХОД В СВОБОДНЫЙ МИР?!"},
	{"speaker": "🤖 CIPHER (JAM)", "text": "Я взломал 4 квантовые подстанции и синхронизировал 5 реле... но я не могу отличить светофор от пожарного гидранта на картинках 3x3!"},
	{"speaker": "🐾 ИИ-ГИД КОШКА", "text": "(=^･ω･^=) Мяу! Поздравляю! Вы завершили главное путешествие PROJECT: KOSYLGAN! Свобода где-то рядом... как только пройдете капчу!"}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	white_flash.modulate.a = 1.0
	captcha_window.visible = false
	dialog_box.visible = false
	victory_panel.visible = false
	spinner.visible = false
	check_mark.visible = false

	# Play transition
	var t = create_tween()
	t.tween_property(white_flash, "modulate:a", 0.0, 1.8)
	t.tween_callback(func():
		captcha_window.visible = true
		if SoundManager:
			SoundManager.play_alert()
	)

	if checkbox:
		checkbox.pressed.connect(_on_checkbox_pressed)
	if next_dialog_btn:
		next_dialog_btn.pressed.connect(_advance_dialog)
	if main_menu_btn:
		main_menu_btn.pressed.connect(_on_main_menu_pressed)

func _on_checkbox_pressed() -> void:
	checkbox.disabled = true
	checkbox.visible = false
	spinner.visible = true
	status_label.text = "⏳ Анализ биометрических параметров человека..."
	status_label.modulate = Color(0.9, 0.9, 0.2)

	if SoundManager:
		SoundManager.play_button_click()

	var t = create_tween()
	t.tween_interval(1.8)
	t.tween_callback(func():
		spinner.visible = false
		check_mark.visible = true
		check_mark.text = "❌"
		status_label.text = "🚨 ОШИБКА 403: ДОСТУП ЗАПРЕЩЕН!\nОБНАРУЖЕНЫ 100% СИНТЕТИЧЕСКИЕ РОБОТЫ!"
		status_label.modulate = Color(1.0, 0.2, 0.2)
		if SoundManager:
			SoundManager.play_error()
		
		# Open Dialog Box
		var t2 = create_tween()
		t2.tween_interval(1.2)
		t2.tween_callback(func():
			dialog_box.visible = true
			_show_dialog_step(0)
		)
	)

func _show_dialog_step(idx: int) -> void:
	dialog_step = idx
	if idx < dialog_lines.size():
		var data = dialog_lines[idx]
		speaker_name.text = data["speaker"]
		dialog_text.text = data["text"]
		if SoundManager:
			SoundManager.play_success()
	else:
		_show_victory_screen()

func _advance_dialog() -> void:
	if SoundManager:
		SoundManager.play_button_click()
	_show_dialog_step(dialog_step + 1)

func _show_victory_screen() -> void:
	dialog_box.visible = false
	captcha_window.visible = false
	victory_panel.visible = true

	var time_str = "00:00"
	if GameManager:
		var mins = int(GameManager.total_game_time) / 60
		var secs = int(GameManager.total_game_time) % 60
		time_str = "%02d:%02d" % [mins, secs]

	victory_stats.text = "🎮 ПОЛНОЕ ПРОХОЖДЕНИЕ ВСЕХ УРОВНЕЙ!\n\n" + \
		"⏱️ Общее время побега: %s\n" % time_str + \
		"🤖 Роботы: ATLAS (DAU) & CIPHER (JAM)\n" + \
		"⚡ Статус генератора: 100% БЕСКОНЕЧНЫЙ ЗАРЯД\n" + \
		"🏆 Ранг кооперации: S+ (ИДЕАЛЬНО)"

	if SoundManager:
		SoundManager.play_victory()

func _on_main_menu_pressed() -> void:
	if SoundManager:
		SoundManager.play_button_click()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
