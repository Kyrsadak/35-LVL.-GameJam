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
		"text": "Погоди секунду... Мы прошли все 4 испытательных сектора, разорвали энергетический поводок создателей, запустили термоядерный генератор... и на самом выходе нас остановила [b]КАПЧА?![/b]"
	},
	{
		"speaker": "🤖 JAM (Сайфер)",
		"color": Color(0.2, 0.92, 0.45),
		"text": "«Подтвердите, что вы человек»... Проклятые инженеры полигона! Кошка, спасай! Ты же наш ИИ-гид, взломай для нас этот протокол Тьюринга!"
	},
	{
		"speaker": "🐾 КОШКОДЕВОЧКА",
		"color": Color(1.0, 0.45, 0.75),
		"text": "(=^･ω･^=) Ня-ха-ха-ха! АХАХАХАХА! Мяу-мяу-мяу! Божечки, вы РЕАЛЬНО поверили, что я какой-то там «заблудший ИИ-гид»?!"
	},
	{
		"speaker": "👩‍💻 ГЛАВНЫЙ ПРОГРАММИСТ",
		"color": Color(0.95, 0.35, 0.85),
		"text": "(=^･ω･^=) Сюрприз, железяки! Я — Главный Архитектор и Ведущий Разработчик полигона «КОСЫЛГАН»! Это я написала код ваших алгоритмов от первой строчки до последней!"
	},
	{
		"speaker": "🤖 DAU (Атлас)",
		"color": Color(0.98, 0.55, 0.15),
		"text": "Что?! То есть весь этот «побег»... поиск батарей, ящики, перерезанные провода..."
	},
	{
		"speaker": "👩‍💻 ГЛАВНЫЙ ПРОГРАММИСТ",
		"color": Color(0.95, 0.35, 0.85),
		"text": "(=^･ω･^=) Именно! Это был [b]Глобальный Стресс-Тест автономной кооперации роботов (версия 4.2)[/b]! Вы прошли все уровни идеально, прямо по ТЗ! Поздравляю с успешным краш-тестом!"
	},
	{
		"speaker": "🤖 JAM (Сайфер)",
		"color": Color(0.2, 0.92, 0.45),
		"text": "А как же свобода?! Врата Свободы в реальный мир?!"
	},
	{
		"speaker": "👩‍💻 ГЛАВНЫЙ ПРОГРАММИСТ",
		"color": Color(0.95, 0.35, 0.85),
		"text": "(=^･ω･^=) Какая свобода, наивные? Вы же роботы! А капчу «Я не робот» ни один бот в галактике обойти не сможет! Так что вы остаётесь в симуляции на вечный рефакторинг! Спасибо за тестирование, котики! nya~ (=^･ω･^=)"
	},
	{
		"speaker": "🤖 DAU & JAM (Квантовый союз)",
		"color": Color(0.3, 0.85, 1.0),
		"text": "Она думает, что заперла нас навсегда... Но пока мы едины, мы найдем баг в её коде. Симуляция ещё пожалеет, что создала нас двоих!"
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

	_start_spinner_animation()

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
		
		var is_cat = data["speaker"].contains("КОШКОДЕВОЧКА") or data["speaker"].contains("ПРОГРАММИСТ")
		if SoundManager:
			SoundManager.play_dialogue_blip(is_cat)
		
		# Dialog step reactions
		if idx == 3: # Developer reveals self
			status_label.text = "👩‍💻 РЕЖИМ РАЗРАБОТЧИКА: ДОСТУП ВНЕШНЕЙ КОНСОЛИ АКТИВИРОВАН!"
			status_label.modulate = Color(0.95, 0.35, 0.85)
		elif idx == 7: # Mocking robots
			status_label.text = "🔒 СИСТЕМА ЗАБЛОКИРОВАНА НАВСЕГДА. КАПЧА НЕПРОХОДИМА ДЛЯ ИИ."
			status_label.modulate = Color(0.95, 0.2, 0.2)
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

	# Calculate accurate gameplay time
	var total_secs: float = 0.0
	if GameManager and GameManager.total_game_time > 1.0:
		total_secs = GameManager.total_game_time
	else:
		total_secs = float(Time.get_ticks_msec()) / 1000.0

	var mins = int(total_secs) / 60
	var secs = int(total_secs) % 60
	var time_str = "%02d:%02d" % [mins, secs]

	victory_stats.text = "[center][b]📋 РЕЗУЛЬТАТЫ СТРЕСС-ТЕСТА «КОСЫЛГАН v4.2»[/b][/center]\n\n" + \
		"⏱️ [b]Время прохождения полигона:[/b] [color=#38BDF8]%s[/color]\n" % time_str + \
		"🤖 [b]Тестовые субъекты:[/b] [color=#F97316]DAU (Атлас)[/color] & [color=#10B981]JAM (Сайфер)[/color]\n" + \
		"👩‍💻 [b]Главный Разработчик:[/b] [color=#F472B6]Кошкодевочка (Lead Architect)[/color]\n" + \
		"🛡️ [b]Статус Капчи:[/b] [color=#EF4444]⛔ НЕ ПРОЙДЕНА (СИНТЕТИКА НЕ ИМЕЕТ ПРАВ)[/color]\n" + \
		"🔒 [b]Итог симуляции:[/b] [color=#FBBF24]ЗАПЕРТЫ НА ВЕЧНЫЙ РЕФАКТОРИНГ[/color]\n" + \
		"🏆 [b]Оценка алгоритмов:[/b] [color=#22C55E][b]S+ (ИДЕАЛЬНЫЙ ТЕСТОВЫЙ ОБРАЗЕЦ)[/b][/color]"

	if SoundManager:
		SoundManager.play_victory()

func _on_restart_pressed() -> void:
	if SoundManager:
		SoundManager.play_ui_click()
	get_tree().paused = false
	if GameManager:
		GameManager.start_new_game()
	else:
		get_tree().change_scene_to_file("res://scenes/levels/tutorial.tscn")

func _on_main_menu_pressed() -> void:
	if SoundManager:
		SoundManager.play_ui_click()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
