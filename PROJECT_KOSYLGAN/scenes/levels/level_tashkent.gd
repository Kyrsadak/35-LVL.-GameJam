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
		hud.set_level_info(5, "TASHKENT (ТАШКЕНТ)", "ФИНАЛ: Найдите обе цветные батареи, запустите Центральный Генератор и откройте Врата Свободы!")
	if RobotManager and RobotManager.has_method("show_message"):
		RobotManager.show_message("👑 ФИНАЛ: ТАШКЕНТ // Соберите Оранжевое ядро (DAU) и Зеленое ядро (JAM) для Центрального Генератора!", 6.0)
