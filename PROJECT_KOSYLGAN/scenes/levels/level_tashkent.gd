extends Node3D

@onready var atlas = $Robots/RobotAtlas
@onready var cipher = $Robots/RobotCipher
@onready var charging_station = $ChargingStationSpawn
@onready var camera_pivot = $TopDownCamera
@onready var hud: HUD = $HUD

func _ready() -> void:
	if RobotManager:
		RobotManager.register_level(5, atlas, cipher, charging_station, camera_pivot)
	if hud and hud.has_method("set_level_info"):
		hud.set_level_info(4, "Сектор: Ташкент (Центральное Ядро)", "ФИНАЛ: Собрать оба ядра, запустить Генератор и открыть Врата Свободы!")

	get_tree().create_timer(0.4).timeout.connect(_start_tashkent_story)

func _start_tashkent_story() -> void:
	var story = [
		{"speaker": "catgirl", "text": "(=^･ω･^=) Сектор 4: «Ташкент» — Сердце полигона «КОСЫЛГАН»! Здесь находится Центральный Термоядерный Генератор."},
		{"speaker": "dau", "text": "Я вижу два запертых ангара. Оранжевое Титановое ядро за лазерными барьерами на востоке..."},
		{"speaker": "jam", "text": "А Зеленое Квантовое ядро заблокировано терминалом проводов на западе. За работу, DAU!"},
		{"speaker": "catgirl", "text": "Объедините оба ядра в Центральный Генератор! Это даст вам 100% вечную энергию и откроет Врата Свободы на северном портале!"}
	]
	if RobotManager:
		RobotManager.play_dialogue(story)
