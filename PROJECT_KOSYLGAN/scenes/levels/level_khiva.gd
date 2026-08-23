extends Node3D

@onready var atlas = $Robots/RobotAtlas
@onready var cipher = $Robots/RobotCipher
@onready var charging_station = $ChargingStationSpawn
@onready var camera_pivot = $TopDownCamera
@onready var hud = $HUD

func _ready() -> void:
	if RobotManager:
		RobotManager.register_level(2, atlas, cipher, charging_station, camera_pivot)
	if hud and hud.has_method("set_level_info"):
		hud.set_level_info(2, "KHIVA (ХИВА)", "Shift: Спринт | Разберите завал, запитайте генератор и активируйте терминал плитой!")
	if RobotManager and RobotManager.has_method("show_message"):
		RobotManager.show_message("📍 МИССИЯ 2: ХИВА // Shift — Спринт (без штрафа энергии)! Расчищайте завалы и запитывайте терминалы!", 4.5)
