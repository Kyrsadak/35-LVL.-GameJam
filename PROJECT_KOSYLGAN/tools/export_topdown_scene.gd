extends Node3D

var items = [
	{
		"name": "topdown_robot_dau",
		"scene": "res://characters/robots/RobotAtlas.tscn",
		"cam_size": 2.8,
		"y_offset": -0.8
	},
	{
		"name": "topdown_robot_jam",
		"scene": "res://characters/robots/RobotCipher.tscn",
		"cam_size": 2.8,
		"y_offset": -0.8
	},
	{
		"name": "topdown_charging_station",
		"scene": "res://systems/charging_station.tscn",
		"cam_size": 3.6,
		"y_offset": 0.0
	},
	{
		"name": "topdown_terminal",
		"scene": "res://systems/terminal.tscn",
		"cam_size": 3.0,
		"y_offset": -0.8
	},
	{
		"name": "topdown_guide_tablet",
		"scene": "res://systems/guide_tablet.tscn",
		"cam_size": 2.2,
		"y_offset": -0.5
	},
	{
		"name": "topdown_pushable_box",
		"scene": "res://systems/pushable_box.tscn",
		"cam_size": 2.4,
		"y_offset": -0.6
	},
	{
		"name": "topdown_key_module",
		"scene": "res://systems/key_module.tscn",
		"cam_size": 1.8,
		"y_offset": -0.5
	},
	{
		"name": "topdown_socket_terminal",
		"scene": "res://systems/socket_terminal.tscn",
		"cam_size": 2.6,
		"y_offset": 0.0
	},
	{
		"name": "topdown_robocat_girl",
		"scene": "res://scenes/props/prop_robocat_girl.tscn",
		"cam_size": 2.6,
		"y_offset": 0.0
	}
]

@onready var viewport: SubViewport = $SubViewport
@onready var camera: Camera3D = $SubViewport/Camera3D
@onready var container: Node3D = $SubViewport/Container

func _ready() -> void:
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("figma_assets/topdown_sprites"):
		dir.make_dir_recursive("figma_assets/topdown_sprites")

	camera.transform = Transform3D().looking_at(Vector3.DOWN, Vector3(0, 0, -1))
	camera.position = Vector3(0, 10.0, 0)

	call_deferred("_run_captures")

func _run_captures() -> void:
	for item in items:
		for c in container.get_children():
			c.queue_free()

		await get_tree().create_timer(0.1).timeout

		var scn = load(item["scene"])
		if scn:
			var inst = scn.instantiate()
			container.add_child(inst)
			inst.position = Vector3(0, item["y_offset"], 0)
			camera.size = item["cam_size"]

			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			await get_tree().create_timer(0.15).timeout

			var img = viewport.get_texture().get_image()
			if img and not img.is_empty():
				# globalize_path replaced
				var abs_path_loaded = load("res://figma_assets/topdown_sprites/" + item["name"] + ".png")
				img.save_png(abs_path)
				print("Saved: ", abs_path)

	# 1. Floor tile
	for c in container.get_children():
		c.queue_free()
	var floor_mesh = CSGBox3D.new()
	floor_mesh.size = Vector3(2.0, 0.2, 2.0)
	floor_mesh.material = load("res://assets/materials/mat_space_floor.tres")
	container.add_child(floor_mesh)
	camera.size = 2.0
	await get_tree().create_timer(0.15).timeout
	var img_f = viewport.get_texture().get_image()
	if img_f and not img_f.is_empty():
		img_f.save_png(ProjectSettings.globalize_path("res://figma_assets/topdown_sprites/topdown_floor_tile.png"))

	# 2. Wall segment
	for c in container.get_children():
		c.queue_free()
	var wall_mesh = CSGBox3D.new()
	wall_mesh.size = Vector3(2.0, 3.0, 0.5)
	wall_mesh.material = load("res://assets/materials/mat_space_wall.tres")
	container.add_child(wall_mesh)
	camera.size = 2.4
	await get_tree().create_timer(0.15).timeout
	var img_w = viewport.get_texture().get_image()
	if img_w and not img_w.is_empty():
		img_w.save_png(ProjectSettings.globalize_path("res://figma_assets/topdown_sprites/topdown_wall_segment.png"))

	print("COMPLETE!")
	get_tree().quit(0)
