class_name RobotAtlas
extends RobotBase

signal guide_read(guide_id: String, text: String)
signal key_module_picked(module: Node3D)
signal key_module_inserted()

@onready var push_ray: RayCast3D = $PushRay

func _ready() -> void:
	robot_id = "atlas"
	robot_display_name = "ATLAS (СИЛОВОЙ)"
	robot_color = Color(0.1, 0.7, 1.0)
	super._ready()
	if skin and skin.has_method("set_skin_material"):
		skin.set_skin_material(load("res://characters/player/CharacterSkins/character_mat_atlas.tres"))

func interact() -> void:
	# 1. Check if holding a key module and near socket
	if carried_object != null:
		if current_interactable and current_interactable.is_in_group("socket_terminal"):
			if current_interactable.has_method("insert_module"):
				current_interactable.insert_module(carried_object)
				carried_object = null
				key_module_inserted.emit()
				return
		else:
			# Drop key module if not near socket
			_drop_carried_object()
			return

	# 2. Check if near guide tablet
	if current_interactable and current_interactable.is_in_group("guide_tablet"):
		if current_interactable.has_method("read_guide"):
			var info = current_interactable.read_guide()
			guide_read.emit(info.get("id", ""), info.get("text", ""))
			return

	# 3. Check if near key module to pick up
	if current_interactable and current_interactable.is_in_group("key_module"):
		_pick_up_object(current_interactable)
		return

func _pick_up_object(obj: Node3D) -> void:
	if obj.has_method("pick_up"):
		obj.pick_up(carry_pivot)
		carried_object = obj
		key_module_picked.emit(obj)

func _drop_carried_object() -> void:
	if carried_object and carried_object.has_method("drop"):
		carried_object.drop(global_position + (-global_transform.basis.z * 1.2))
		carried_object = null

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# Check box pushing for ATLAS
	if is_active and not is_discharged:
		_check_box_push()

func _check_box_push() -> void:
	if not push_ray or not push_ray.is_colliding():
		return
	var collider = push_ray.get_collider()
	if collider and collider.is_in_group("pushable_box"):
		if collider.has_method("push"):
			var push_dir = -global_transform.basis.z
			collider.push(push_dir, velocity.length())
