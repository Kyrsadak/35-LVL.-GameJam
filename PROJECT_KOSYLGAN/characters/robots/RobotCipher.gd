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
	var target = current_interactable
	if not target and push_ray and push_ray.is_colliding():
		target = push_ray.get_collider()
	
	if target and not target.is_in_group("socket_terminal") and not target.is_in_group("terminal"):
		if target.get_parent() and (target.get_parent().is_in_group("socket_terminal") or target.get_parent().is_in_group("terminal")):
			target = target.get_parent()

	# 1. Hack standard door terminal
	if target and target.is_in_group("terminal"):
		if target.has_method("start_hack"):
			target.start_hack(self)
			hack_started.emit(target)
			return

	# 2. Activate Socket Terminal / Power Receiver Dock with battery
	elif target and target.is_in_group("socket_terminal"):
		if target.has_method("activate_generator"):
			target.activate_generator(self)
			return

	# 3. Guide tablet (Atlas only)
	elif target and target.is_in_group("guide_tablet"):
		if RobotManager:
			RobotManager.show_message("[CIPHER]: Этот чертёж слишком сложен для меня. Нужен ATLAS!")

	# 4. Battery / Key module (Atlas only)
	elif target and (target.is_in_group("key_module") or target.is_in_group("battery_cell")):
		if RobotManager:
			RobotManager.show_message("[CIPHER]: Батарея слишком тяжелая! Нужен вилочный погрузчик ATLAS.")

	# 5. Generic interactable
	elif target and target.has_method("interact"):
		target.interact(self)

func play_hack_animation() -> void:
	if skin and skin.has_method("play_hack"):
		skin.play_hack()
