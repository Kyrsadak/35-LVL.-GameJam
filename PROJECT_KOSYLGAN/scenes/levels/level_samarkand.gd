extends Node3D

@onready var atlas = $Robots/RobotAtlas
@onready var cipher = $Robots/RobotCipher
@onready var charging_station = $ChargingStationSpawn
@onready var camera_pivot = $TopDownCamera
@onready var hud: HUD = $HUD

func _ready() -> void:
	if RobotManager:
		RobotManager.register_level(3, atlas, cipher, charging_station, camera_pivot)
	if hud and hud.has_method("set_level_info"):
		hud.set_level_info(3, "Сектор: Самарканд (Квантовый узел)", "Синхронизировать 5-релейную матрицу, запитать шлюзы и доставить ядро")

	get_tree().create_timer(0.4).timeout.connect(_start_samarkand_story)

func _start_samarkand_story() -> void:
	var story = [
		{"speaker": "catgirl", "text": "(=^･ω･^=) Сектор 3: «Самарканд» — главный квантовый коммутатор полигона! Здесь установлена защитная матрица из 5 фазовых реле."},
		{"speaker": "jam", "text": "Если я перехвачу управление этой матрицей (код 3-1-4-2-5), мы получим прямой доступ к питанию Центрального ядра!"},
		{"speaker": "dau", "text": "DAU сканирует плиты питания. Нам понадобятся два ящика: один для стартовой матрицы, второй — для терминала шлюза."},
		{"speaker": "catgirl", "text": "Впереди финальный сектор «Ташкент». Мы в одном шаге от бесконечной энергии и побега!"}
	]
	if RobotManager:
		RobotManager.play_dialogue(story)
