extends Node3D

@onready var atlas = $Robots/RobotAtlas
@onready var cipher = $Robots/RobotCipher
@onready var charging_station = $ChargingStation
@onready var camera_pivot = $TopDownCamera
@onready var hud = $HUD

func _ready() -> void:
	if RobotManager:
		RobotManager.register_level(1, atlas, cipher, charging_station, camera_pivot)
	if hud and hud.has_method("set_level_info"):
		hud.set_level_info(1, "Обучение (Тренировочный блок)", "WASD: Движение  •  TAB: Смена  •  E: Действие  •  R: Рестарт\nПКМ: Обзор 360°  •  Колесо: Зум  •  F: Сброс камеры")
