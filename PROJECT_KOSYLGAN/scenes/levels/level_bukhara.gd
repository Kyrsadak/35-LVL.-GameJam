extends Node3D

@onready var atlas = $Robots/RobotAtlas
@onready var cipher = $Robots/RobotCipher
@onready var charging_station = $ChargingStation
@onready var camera_pivot = $TopDownCamera
@onready var hud = $HUD

func _ready() -> void:
	if RobotManager:
		RobotManager.register_level(2, atlas, cipher, charging_station, camera_pivot)
	if hud and hud.has_method("set_level_info"):
		hud.set_level_info(1, "Сектор: Бухара (Архивы)", "Добыть энерго-ядро из хранилища и доставить в шлюз эвакуации")

	get_tree().create_timer(0.4).timeout.connect(_start_bukhara_story)

func _start_bukhara_story() -> void:
	var story = [
		{"speaker": "catgirl", "text": "(=^･ω･^=) Сектор 1: «Бухара»! Это архивный блок полигона. Ученые наблюдают за вашим временем реакции через камеры."},
		{"speaker": "jam", "text": "Я вижу защищенный терминал у шлюза. DAU, просканируй чертеж на планшете, чтобы я безопасно перерезал нужный провод!"},
		{"speaker": "dau", "text": "Принято. В восточном хранилище зафиксирован сигнал вспомогательной батареи — первый шаг к нашей энергетической свободе!"}
	]
	if RobotManager:
		RobotManager.play_dialogue(story)
