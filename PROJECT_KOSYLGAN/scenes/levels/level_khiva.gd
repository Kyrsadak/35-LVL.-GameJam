extends Node3D

@onready var atlas = $Robots/RobotAtlas
@onready var cipher = $Robots/RobotCipher
@onready var charging_station = $ChargingStationSpawn
@onready var camera_pivot = $TopDownCamera
@onready var hud = $HUD

func _ready() -> void:
	if RobotManager:
		RobotManager.register_level(3, atlas, cipher, charging_station, camera_pivot)
	if hud and hud.has_method("set_level_info"):
		hud.set_level_info(2, "Сектор: Хива (Физический полигон)", "Shift: Спринт | Расчистить завал ящиков, запитать генератор и активировать плиту")

	get_tree().create_timer(0.4).timeout.connect(_start_khiva_story)

func _start_khiva_story() -> void:
	var story = [
		{"speaker": "catgirl", "text": "(=^･ω･^=) Сектор 2: «Хива»! Создатели усложнили физические барьеры и заблокировали склад тяжелыми ящиками."},
		{"speaker": "dau", "text": "Для вилочного погрузчика DAU это не помеха. Я расчищу проход и поставлю ящик на нажимную плиту в северном ангаре!"},
		{"speaker": "jam", "text": "Датчики фиксируют всплеск активности наблюдателей. Программисты за стеклом не ожидали такой координации между нами!"}
	]
	if RobotManager:
		RobotManager.play_dialogue(story)
