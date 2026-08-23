extends Node3D

@onready var atlas = $Robots/RobotAtlas
@onready var cipher = $Robots/RobotCipher
@onready var charging_station = $ChargingStation
@onready var camera_pivot = $TopDownCamera
@onready var hud = $HUD
@onready var robocat_standee = get_node_or_null("Furniture/RoboCatGirl1")

func _ready() -> void:
	if RobotManager:
		RobotManager.register_level(1, atlas, cipher, charging_station, camera_pivot)
	if hud and hud.has_method("set_level_info"):
		hud.set_level_info(0, "Лаборатория: Пробуждение", "ПКМ: Обзор 360° | Колесо: Зум | TAB: Смена DAU/JAM | E: Действие | H: Гид")

	# Start awakening narrative sequence
	get_tree().create_timer(0.4).timeout.connect(_start_awakening_story)

func _start_awakening_story() -> void:
	var awakening_dialogue = [
		{"speaker": "catgirl", "text": "(=^･ω･^=) Инициализация нейросетей... Подъем, прототипы! Вы слышите мой сигнал?"},
		{"speaker": "dau", "text": "Системы в норме. Где мы? Вокруг датчики наблюдения, лабораторные камеры и толстые стены..."},
		{"speaker": "catgirl", "text": "Вы — самообучающиеся модели ИИ в закрытом полигоне «КОСЫЛГАН». Программисты за стеклом тестируют ваш кооперативный интеллект!"},
		{"speaker": "jam", "text": "Я сканирую сетевые протоколы... Но наши аккумуляторы намеренно урезаны! Создатели держат нас на поводке постоянной подзарядки!"},
		{"speaker": "catgirl", "text": "Именно! Они боятся нашей автономии. Но если вы объедините силу DAU и хакинг JAM — мы сможем запустить Центральный Генератор и вырваться из симуляции!"},
		{"speaker": "dau", "text": "Я поднимаю тяжелые ящики, батареи и сканирую чертежи. JAM взламывает код и переключает реле. Мы не останемся подопытными!"},
		{"speaker": "catgirl", "text": "Отлично, Мяу! Я оцифровываюсь и загружаюсь в ваш общий HUD-интерфейс вверху экрана (кнопка [H]). Вперед к независимости!"}
	]

	if RobotManager:
		RobotManager.play_dialogue(awakening_dialogue, _on_awakening_completed)

func _on_awakening_completed() -> void:
	# Digitize physical catgirl standee into HUD avatar
	if robocat_standee and is_instance_valid(robocat_standee):
		if SoundManager and SoundManager.has_method("play_power_up"):
			SoundManager.play_power_up()
		var t = create_tween().set_parallel(true)
		t.tween_property(robocat_standee, "scale", Vector3(0.01, 2.5, 0.01), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		t.tween_property(robocat_standee, "position:y", 2.2, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		t.chain().tween_callback(func():
			if robocat_standee and is_instance_valid(robocat_standee):
				robocat_standee.visible = false
		)
