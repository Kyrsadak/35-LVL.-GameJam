@tool
extends SceneTree

func _init() -> void:
	print("Starting Top-Down Sprites Generation...")
	var root_node = Node3D.new()
	root.add_child(root_node)

	var dir = DirAccess.open("res://")
	if not dir.dir_exists("figma_assets/topdown_sprites"):
		dir.make_dir_recursive("figma_assets/topdown_sprites")

	# Setup SubViewport for High-Res transparent rendering
	var viewport = SubViewport.new()
	viewport.size = Vector2i(512, 512)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root_node.add_child(viewport)

	# World Environment
	var env = Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.9, 0.92, 1.0)
	env.ambient_light_energy = 1.2

	var we = WorldEnvironment.new()
	we.environment = env
	viewport.add_child(we)

	# Directional Light from above-angle for subtle depth shading
	var light = DirectionalLight3D.new()
	light.transform = Transform3D().looking_at(Vector3(0.3, -1.0, -0.4).normalized(), Vector3.UP)
	light.light_energy = 1.2
	light.light_color = Color(1.0, 0.98, 0.95)
	light.shadow_enabled = true
	viewport.add_child(light)

	# Camera looking directly down (Orthogonal top-down)
	var camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.transform = Transform3D().looking_at(Vector3.DOWN, Vector3.FORWARD)
	camera.position = Vector3(0, 10.0, 0)
	viewport.add_child(camera)

	# Node container for the subject
	var subject_container = Node3D.new()
	viewport.add_child(subject_container)

	# List of items to capture
	var items = [
		{
			"name": "topdown_robot_dau",
			"scene": "res://characters/robots/RobotAtlas.tscn",
			"cam_size": 2.6,
			"y_offset": -0.8
		},
		{
			"name": "topdown_robot_jam",
			"scene": "res://characters/robots/RobotCipher.tscn",
			"cam_size": 2.6,
			"y_offset": -0.8
		},
		{
			"name": "topdown_charging_station",
			"scene": "res://systems/charging_station.tscn",
			"cam_size": 3.4,
			"y_offset": 0.0
		},
		{
			"name": "topdown_terminal",
			"scene": "res://systems/terminal.tscn",
			"cam_size": 2.8,
			"y_offset": -0.8
		},
		{
			"name": "topdown_guide_tablet",
			"scene": "res://systems/guide_tablet.tscn",
			"cam_size": 2.0,
			"y_offset": -0.5
		},
		{
			"name": "topdown_pushable_box",
			"scene": "res://systems/pushable_box.tscn",
			"cam_size": 2.2,
			"y_offset": -0.6
		},
		{
			"name": "topdown_key_module",
			"scene": "res://systems/key_module.tscn",
			"cam_size": 1.6,
			"y_offset": -0.5
		},
		{
			"name": "topdown_socket_terminal",
			"scene": "res://systems/socket_terminal.tscn",
			"cam_size": 2.4,
			"y_offset": 0.0
		},
		{
			"name": "topdown_robocat_girl",
			"scene": "res://scenes/props/prop_robocat_girl.tscn",
			"cam_size": 2.4,
			"y_offset": 0.0
		}
	]

	for item in items:
		for c in subject_container.get_children():
			c.queue_free()
		await process_frame
		await process_frame

		var scn = load(item["scene"])
		if scn:
			var inst = scn.instantiate()
			subject_container.add_child(inst)
			inst.position = Vector3(0, item["y_offset"], 0)
			camera.size = item["cam_size"]

			await process_frame
			await process_frame
			await process_frame

			var img = viewport.get_texture().get_image()
			if img:
				var path = "res://figma_assets/topdown_sprites/" + item["name"] + ".png"
				img.save_png(ProjectSettings.globalize_path(path))
				print("Generated: ", path)

	# 1. Top-down Floor Tile
	for c in subject_container.get_children():
		c.queue_free()
	
	var floor_mesh = CSGBox3D.new()
	floor_mesh.size = Vector3(2.0, 0.2, 2.0)
	floor_mesh.material = load("res://assets/materials/mat_space_floor.tres")
	subject_container.add_child(floor_mesh)
	camera.size = 2.0
	
	await process_frame
	await process_frame
	var img_f = viewport.get_texture().get_image()
	if img_f:
		img_f.save_png(ProjectSettings.globalize_path("res://figma_assets/topdown_sprites/topdown_floor_tile.png"))
		print("Generated: topdown_floor_tile.png")

	# 2. Top-down Wall Segment
	for c in subject_container.get_children():
		c.queue_free()
	
	var wall_mesh = CSGBox3D.new()
	wall_mesh.size = Vector3(2.0, 3.0, 0.5)
	wall_mesh.material = load("res://assets/materials/mat_space_wall.tres")
	subject_container.add_child(wall_mesh)
	camera.size = 2.4
	
	await process_frame
	await process_frame
	var img_w = viewport.get_texture().get_image()
	if img_w:
		img_w.save_png(ProjectSettings.globalize_path("res://figma_assets/topdown_sprites/topdown_wall_segment.png"))
		print("Generated: topdown_wall_segment.png")

	await process_frame
	await process_frame
	print("All top-down sprites generated successfully!")
	quit(0)
