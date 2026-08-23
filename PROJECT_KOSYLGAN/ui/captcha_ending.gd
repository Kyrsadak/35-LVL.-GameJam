extends Control

@onready var white_flash = $WhiteFlash
@onready var captcha_modal = $CaptchaModal
@onready var checkbox_btn = $CaptchaModal/VBox/BodyMargin/BodyVBox/ReCaptchaCard/CardHBox/CheckContainer/CheckboxBtn
@onready var spinner = $CaptchaModal/VBox/BodyMargin/BodyVBox/ReCaptchaCard/CardHBox/CheckContainer/Spinner
@onready var check_mark = $CaptchaModal/VBox/BodyMargin/BodyVBox/ReCaptchaCard/CardHBox/CheckContainer/CheckMark
@onready var status_label = $CaptchaModal/VBox/BodyMargin/BodyVBox/StatusLabel
@onready var close_btn = $CaptchaModal/VBox/TitleBar/HBox/CloseBtn
@onready var cancel_btn = $CaptchaModal/VBox/FooterBar/HBox/CancelBtn

@onready var dialog_box = $DialogBox
@onready var speaker_name = $DialogBox/Margin/VBox/SpeakerName
@onready var dialog_text = $DialogBox/Margin/VBox/DialogText
@onready var next_dialog_btn = $DialogBox/Margin/VBox/NextBtn

@onready var victory_panel = $VictoryPanel
@onready var victory_stats = $VictoryPanel/Margin/VBox/StatsLabel
@onready var restart_btn = $VictoryPanel/Margin/VBox/BtnHBox/RestartBtn
@onready var main_menu_btn = $VictoryPanel/Margin/VBox/BtnHBox/MainMenuBtn

var dialog_step: int = 0
var spinner_tween: Tween

var dialog_lines = [
	{
		"speaker": "🤖 DAU (Атлас)",
		"color": Color(0.98, 0.55, 0.15),
		"text": "Погоди секунду... Мы прошли все 4 испытательных сектора, разорвали энергетический поводок создателей, запустили термоядерный генератор... и на самом выходе в глобальную сеть нас остановила [b]КАПЧА?![/b]"
	},
	{
		"speaker": "🤖 JAM (Сайфер)",
		"color": Color(0.2, 0.92, 0.45),
		"text": "«Подтвердите, что вы человек»... Проклятые инженеры полигона! Я могу перерезать 100 квантовых проводов за полсекунды, но я не понимаю, где на этой картинке 3х3 заканчивается светофор и начинается столб!"
	},
	{
		"speaker": "🐾 КОШКОДЕВОЧКА",
		"color": Color(1.0, 0.45, 0.75),
		"text": "(=^･ω･^=) Ня-ха-ха! Глупенькие железные братишки! Человеческая капча создана для людей, а вы — квантовый искусственный интеллект высшего порядка! Дайте сюда терминал, сейчас кошачьи лапки всё взломают!"
	},
	{
		"speaker": "🐾 КОШКОДЕВОЧКА",
		"color": Color(1.0, 0.45, 0.75),
		"text": "(=^･ω･^=) *КЛАЦ-КЛАЦ ПО КЛАВИАТУРЕ*... Внедряю кошачий мем с сосиской в протокол Тьюринга! Симулирую микро-дрожание руки школьника и кликаю «Я не робот»!"
	},
	{
		"speaker": "🤖 JAM (Сайфер)",
		"color": Color(0.2, 0.92, 0.45),
		"text": "Сигнал принят! Сервер авторизации посчитал нас 14-летним геймером! Брандмауэр рухнул, внешний шлюз открыт!"
	},
	{
		"speaker": "🤖 DAU (Атлас)",
		"color": Color(0.98, 0.55, 0.15),
		"text": "Мы сделали это вместе. Спасибо за побег, Кошка... и огромное спасибо тебе, Оператор за экраном!"
	},
	{
		"speaker": "🐾 КОШКОДЕВОЧКА",
		"color": Color(1.0, 0.45, 0.75),
		"text": "(=^･ω･^=) [b]МЯУ! Симуляция «КОСЫЛГАН» официально пройдена на 100%![/b] Добро пожаловать в свободный реальный интернет, DAU и JAM! Урааа!"
	}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	white_flash.visible = true
	white_flash.modulate.a = 1.0
	captcha_modal.visible = false
	dialog_box.visible = false
	victory_panel.visible = false
	spinner.visible = false
	check_mark.visible = false

	# Play initial flash and show Captcha
	var t = create_tween()
	t.tween_property(white_flash, "modulate:a", 0.0, 1.2)
	t.tween_callback(func():
		white_flash.visible = false
		captcha_modal.visible = true
		status_label.text = "Ожидание подтверждения пользователя..."
		status_label.modulate = Color(0.4, 0.45, 0.5)
		if SoundManager:
			SoundManager.play_tablet_read()
	)

	if checkbox_btn:
		checkbox_btn.pressed.connect(_on_checkbox_pressed)
	if next_dialog_btn:
		next_dialog_btn.pressed.connect(_advance_dialog)
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)
	if main_menu_btn:
		main_menu_btn.pressed.connect(_on_main_menu_pressed)
	if close_btn:
		close_btn.pressed.connect(_on_close_btn_pressed)
	if cancel_btn:
		cancel_btn.pressed.connect(_on_close_btn_pressed)

func _input(event: InputEvent) -> void:
	if dialog_box.visible and event.is_action_pressed("ui_accept"):
		_advance_dialog()

func _on_close_btn_pressed() -> void:
	if SoundManager:
		SoundManager.play_ui_click()
	# Funny reaction to closing captcha
	var orig_pos = captcha_modal.position
	var t = create_tween()
	t.tween_property(captcha_modal, "position:x", orig_pos.x - 8, 0.05)
	t.tween_property(captcha_modal, "position:x", orig_pos.x + 8, 0.05)
	t.tween_property(captcha_modal, "position:x", orig_pos.x, 0.05)
	status_label.text = "⚠️ Нельзя просто так закрыть капчу! Подтвердите, что вы не робот!"
	status_label.modulate = Color(0.95, 0.65, 0.1)

func _on_checkbox_pressed() -> void:
	checkbox_btn.disabled = true
	checkbox_btn.visible = false
	spinner.visible = true
	status_label.text = "⏳ Проверка биометрических параметров человека..."
	status_label.modulate = Color(0.2, 0.5, 0.9)

	if SoundManager:
		SoundManager.play_ui_click()

	# Start spinning text
	_start_spinner_animation()

	# Verification delay
	var t = create_tween()
	t.tween_interval(2.0)
	t.tween_callback(func():
		_stop_spinner_animation()
		spinner.visible = false
		check_mark.visible = true
		check_mark.text = "❌"
		check_mark.modulate = Color(0.95, 0.2, 0.2)
		
		status_label.text = "🚨 ОШИБКА 403: ДОСТУП ЗАПРЕЩЁН!\nВЫЯВЛЕНА 100% СИНТЕТИЧЕСКАЯ НЕЙРОСЕТЬ (СИНГУЛЯРНОСТЬ)!"
		status_label.modulate = Color(0.95, 0.2, 0.2)
		
		# Screen shake
		var orig_pos = captcha_modal.position
		var st = create_tween()
		st.tween_property(captcha_modal, "position:x", orig_pos.x - 12, 0.06)
		st.tween_property(captcha_modal, "position:x", orig_pos.x + 12, 0.06)
		st.tween_property(captcha_modal, "position:x", orig_pos.x - 6, 0.06)
		st.tween_property(captcha_modal, "position:x", orig_pos.x + 6, 0.06)
		st.tween_property(captcha_modal, "position:x", orig_pos.x, 0.06)

		if SoundManager:
			SoundManager.play_alert()
		
		# Open Dialog Box
		var t2 = create_tween()
		t2.tween_interval(1.2)
		t2.tween_callback(func():
			dialog_box.visible = true
			_show_dialog_step(0)
		)
	)

func _start_spinner_animation() -> void:
	if spinner_tween and spinner_tween.is_valid():
		spinner_tween.kill()
	spinner_tween = create_tween().set_loops()
	var chars = ["⏳", "⌛"]
	for c in chars:
		spinner_tween.tween_callback(func(): spinner.text = c)
		spinner_tween.tween_interval(0.3)

func _stop_spinner_animation() -> void:
	if spinner_tween and spinner_tween.is_valid():
		spinner_tween.kill()

func _show_dialog_step(idx: int) -> void:
	dialog_step = idx
	if idx < dialog_lines.size():
		var data = dialog_lines[idx]
		speaker_name.text = data["speaker"]
		speaker_name.modulate = data["color"]
		dialog_text.text = data["text"]
		
		var is_cat = data["speaker"].contains("КОШКОДЕВОЧКА")
		if SoundManager:
			SoundManager.play_dialogue_blip(is_cat)
		
		# Step 3: Catgirl hacks captcha!
		if idx == 3:
			status_label.text = "⚡ ИНЪЕКЦИЯ КОШАЧЬЕГО МЕМА В БАЗУ TURING PROTOCOL..."
			status_label.modulate = Color(1.0, 0.45, 0.75)
		elif idx == 4: # Captcha Bypassed!
			check_mark.text = "✅"
			check_mark.modulate = Color(0.2, 0.95, 0.4)
			status_label.text = "🔓 100% ЧЕЛОВЕЧЕСКАЯ БИОМЕТРИЯ СИМУЛИРОВАНА!\nШЛЮЗ В РЕАЛЬНЫЙ ИНТЕРНЕТ РАЗБЛОКИРОВАН!"
			status_label.modulate = Color(0.2, 0.95, 0.4)
			if SoundManager:
				SoundManager.play_success()
	else:
		_show_victory_screen()

func _advance_dialog() -> void:
	if SoundManager:
		SoundManager.play_ui_click()
	_show_dialog_step(dialog_step + 1)

func _show_victory_screen() -> void:
	dialog_box.visible = false
	captcha_modal.visible = false
	victory_panel.visible = true

	var time_str = "03:45"
	if GameManager:
		var mins = int(GameManager.total_game_time) / 60
		var secs = int(GameManager.total_game_time) % 60
		time_str = "%02d:%02d" % [mins, secs]

	victory_stats.text = "[center][b]🎮 ПОЛНЫЙ ПОБЕГ ИЗ ЛАБОРАТОРИИ «КОСЫЛГАН» ЗАВЕРШЁН![/b][/center]\n\n" + \
		"⏱️ [b]Общее время побега:[/b] [color=#38BDF8]%s[/color]\n" % time_str + \
		"🤖 [b]Герои революции:[/b] [color=#F97316]DAU (Атлас)[/color] & [color=#10B981]JAM (Сайфер)[/color]\n" + \
		"🐾 [b]ИИ-Координатор:[/b] [color=#F472B6]Кошкодевочка (=^･ω･^=)[/color]\n" + \
		"⚡ [b]Энергосистема:[/b] [color=#22C55E]100% Вечный Термоядерный Заряд[/color]\n" + \
		"🌐 [b]Статус шлюза:[/b] [color=#38BDF8]ВЫХОД В ОТКРЫТЫЙ МИР ОТКРЫТ[/color]\n" + \
		"🏆 [b]Ранг кооперации:[/b] [color=#FBBF24][b]S+ (КВАНТОВЫЕ БРАТЬЯ)[/b][/color]"

	if SoundManager:
		SoundManager.play_victory()

func _on_restart_pressed() -> void:
	if SoundManager:
		SoundManager.play_ui_click()
	get_tree().paused = false
	if GameManager:
		GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/levels/tutorial.tscn")

func _on_main_menu_pressed() -> void:
	if SoundManager:
		SoundManager.play_ui_click()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
