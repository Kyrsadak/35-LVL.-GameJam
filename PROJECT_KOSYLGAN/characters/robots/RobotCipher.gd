class_name RobotCipher
extends RobotBase

signal hack_started(terminal: Node)

func _ready() -> void:
	robot_id = "cipher"
	robot_display_name = "JAM (ХАКЕР)"
	robot_color = Color(0.2, 0.9, 0.5)
	super._ready()
	if skin and skin.has_method("set_skin_material"):
		skin.set_skin_material(load("res://characters/player/CharacterSkins/character_mat_cipher.tres"))

func interact() -> void:
	# 0. If currently docked inside charging station, ALWAYS undock first!
	if is_on_charging_station:
		if RobotManager and RobotManager.charging_station and is_instance_valid(RobotManager.charging_station):
			if RobotManager.charging_station.has_method("undock_robot"):
				RobotManager.charging_station.undock_robot(self)
				return
			elif RobotManager.charging_station.has_method("interact"):
				RobotManager.charging_station.interact(self)
				return
		for cs in get_tree().get_nodes_in_group("charging_station"):
			if cs.has_method("undock_robot"):
				cs.undock_robot(self)
				return
			elif cs.has_method("interact"):
				cs.interact(self)
				return
		return

	# If carrying green quantum battery
	if carried_object != null:
		var gen = current_interactable
		if gen and not gen.is_in_group("dual_generator") and gen.get_parent() and gen.get_parent().is_in_group("dual_generator"):
			gen = gen.get_parent()
		if not gen and push_ray and push_ray.is_colliding():
			var col = push_ray.get_collider()
			if col and (col.is_in_group("dual_generator") or (col.get_parent() and col.get_parent().is_in_group("dual_generator"))):
				gen = col if col.is_in_group("dual_generator") else col.get_parent()

		if gen and gen.is_in_group("dual_generator") and gen.has_method("try_insert_battery"):
			if gen.try_insert_battery(self, carried_object):
				return
		else:
			# Drop carried battery
			_drop_carried_object()
			return

	var target = get_best_interactable()
	
	# Find ancestor if collider or docked item is a child of interactable system
	var node = target
	while node and node != get_tree().root:
		if node.is_in_group("socket_terminal") or node.is_in_group("terminal") or node.is_in_group("dual_generator") or node.is_in_group("guide_tablet"):
			target = node
			break
		node = node.get_parent()

	# 1. Activate Socket Terminal / Power Receiver Dock with battery
	if target and target.is_in_group("socket_terminal"):
		if target.has_method("activate_generator"):
			target.activate_generator(self)
			return
		elif target.has_method("interact"):
			target.interact(self)
			return

	# 2. Pick up Cipher Quantum Key Module (Green)
	elif target and target.is_in_group("key_module"):
		var req = target.required_robot_id if "required_robot_id" in target else ""
		if req == "cipher":
			_pick_up_object(target)
			return
		else:
			if RobotManager:
				RobotManager.show_message("Это тяжелое титановое ядро! Его может поднять только ATLAS.", 3.0)
			return

	# 3. Hack standard door terminal
	elif target and target.is_in_group("terminal"):
		if target.has_method("start_hack"):
			target.start_hack(self)
			hack_started.emit(target)
			return

	# 4. Guide tablet (Atlas only)
	elif target and target.is_in_group("guide_tablet"):
		if RobotManager:
			RobotManager.show_message("Этот чертёж слишком сложен для меня. Нужен ATLAS!")

	# 5. Generic interactable
	elif target and target.has_method("interact"):
		target.interact(self)

func play_hack_animation() -> void:
	if skin and skin.has_method("play_hack"):
		skin.play_hack()

func _pick_up_object(obj: Node3D) -> void:
	if obj and obj.has_method("pick_up"):
		if SoundManager and SoundManager.has_method("play_pickup"):
			SoundManager.play_pickup()
		obj.pick_up(carry_pivot)
		carried_object = obj

func _drop_carried_object() -> void:
	if carried_object and carried_object.has_method("drop"):
		if SoundManager and SoundManager.has_method("play_drop"):
			SoundManager.play_drop()
		var forward = get_facing_direction()
		var drop_pos = global_position + (forward * 1.5)
		drop_pos.y = max(drop_pos.y, 0.0)
		carried_object.drop(drop_pos)
		carried_object = null
