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
		hud.set_level_info(2, "Коммуникации", "TAB: Смена робота на месте | E: Действие / Поднять ящик")
