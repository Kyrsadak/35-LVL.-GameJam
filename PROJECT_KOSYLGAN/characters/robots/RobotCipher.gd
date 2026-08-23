class_name RobotCipher
extends RobotBase

signal hack_started(terminal: Node)

func _ready() -> void:
	robot_id = "cipher"
	robot_display_name = "CIPHER (ХАКЕР)"
	robot_color = Color(0.2, 0.9, 0.5)
	super._ready()
	if skin and skin.has_method("set_skin_material"):
		skin.set_skin_material(load("res://characters/player/CharacterSkins/character_mat_cipher.tres"))

func interact() -> void:
	# 1. Hack standard door terminal
	if current_interactable and current_interactable.is_in_group("terminal"):
		if current_interactable.has_method("start_hack"):
			current_interactable.start_hack(self)
			hack_started.emit(current_interactable)
			return

	# 2. Activate Socket Terminal / Power Receiver Dock with battery
	elif current_interactable and current_interactable.is_in_group("socket_terminal"):
		if current_interactable.has_method("activate_generator"):
			current_interactable.activate_generator(self)
			return

	# 3. Guide tablet (Atlas only)
	elif current_interactable and current_interactable.is_in_group("guide_tablet"):
		if RobotManager:
			RobotManager.show_message("CIPHER не может прочесть чертёж! Нужен ATLAS.")

	# 4. Battery / Key module (Atlas only)
	elif current_interactable and (current_interactable.is_in_group("key_module") or current_interactable.is_in_group("battery_cell")):
		if RobotManager:
			RobotManager.show_message("Батарея слишком тяжелая! Нужен ATLAS с вилочным захватом, чтобы поднять её.")

	# 5. Generic interactable
	elif current_interactable and current_interactable.has_method("interact"):
		current_interactable.interact(self)

func play_hack_animation() -> void:
	if skin and skin.has_method("play_hack"):
		skin.play_hack()
