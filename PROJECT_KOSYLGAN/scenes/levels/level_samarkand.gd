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
		hud.set_level_info(3, "SAMARKAND (САМАРКАНД)", "Синхронизируйте 5-релейную матрицу, запитайте оба энерго-шлюза и доставьте ядро")
	if RobotManager and RobotManager.has_method("show_message"):
		RobotManager.show_message("⚡ МИССИЯ 3: САМАРКАНД // Запитайте 5-рубильниковый терминал тяжелым ящиком и введите код частот (3-1-4-2-5)!", 5.0)
