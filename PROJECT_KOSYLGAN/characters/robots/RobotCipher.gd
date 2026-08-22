class_name RobotCipher
extends RobotBase

signal hack_started(terminal: Node)

func _ready() -> void:
	robot_id = "cipher"
	robot_display_name = "CIPHER (ХАКЕР)"
	robot_color = Color(1.0, 0.55, 0.1)
	super._ready()
	if skin and skin.has_method("set_skin_material"):
		skin.set_skin_material(load("res://characters/player/CharacterSkins/character_mat_cipher.tres"))

func interact() -> void:
	if current_interactable and current_interactable.is_in_group("terminal"):
		if current_interactable.has_method("start_hack"):
			current_interactable.start_hack(self)
			hack_started.emit(current_interactable)
			return
	elif current_interactable and current_interactable.is_in_group("guide_tablet"):
		# Hint
		if RobotManager:
			RobotManager.show_message("CIPHER не распознает чертёж! Нужен силовой робот ATLAS.")
	elif current_interactable and current_interactable.is_in_group("key_module"):
		if RobotManager:
			RobotManager.show_message("Модуль слишком тяжелый! Нужен ATLAS, чтобы поднять его.")
	elif current_interactable and current_interactable.has_method("interact"):
		current_interactable.interact()
