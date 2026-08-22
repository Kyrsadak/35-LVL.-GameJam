extends Node3D

@onready var atlas = $Robots/RobotAtlas
@onready var cipher = $Robots/RobotCipher
@onready var charging_station = $ChargingStation
@onready var camera_pivot = $TopDownCamera
@onready var hud = $HUD

@onready var plate1 = $PressurePlate1
@onready var plate2 = $PressurePlate2
@onready var laser_gate1 = $LaserGate1

var plate1_active: bool = false
var plate2_active: bool = false

func _ready() -> void:
	if RobotManager:
		RobotManager.register_level(3, atlas, cipher, charging_station, camera_pivot)
	if hud and hud.has_method("set_level_info"):
		hud.set_level_info(3, "Центр Управления", "ПКМ: Обзор 360° | Колесо: Зум | F: Сброс | TAB: Смена | E: Действие")

	if plate1:
		plate1.activated.connect(func(): _on_plate_changed(1, true))
		plate1.deactivated.connect(func(): _on_plate_changed(1, false))
	if plate2:
		plate2.activated.connect(func(): _on_plate_changed(2, true))
		plate2.deactivated.connect(func(): _on_plate_changed(2, false))

func _on_plate_changed(plate_num: int, is_on: bool) -> void:
	if plate_num == 1:
		plate1_active = is_on
	elif plate_num == 2:
		plate2_active = is_on

	if laser_gate1 and laser_gate1.has_method("open"):
		if plate1_active and plate2_active:
			laser_gate1.open()
		else:
			laser_gate1.close()
