extends Node3D

func _ready() -> void:
	var vp = SubViewport.new()
	vp.size = Vector2i(1400, 1400)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var scn = load("res://scenes/levels/level_khiva.tscn").instantiate()
	vp.add_child(scn)

	# Remove HUD and in-game camera to get clean topdown render
	var hud = scn.find_child("HUD", true, false)
	if hud:
		hud.queue_free()
	var in_cam = scn.find_child("TopDownCamera", true, false)
	if in_cam:
		in_cam.queue_free()

	var cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 48.0
	cam.transform = Transform3D().looking_at(Vector3.DOWN, Vector3(0, 0, -1))
	cam.position = Vector3(0, 45.0, 0)
	vp.add_child(cam)

	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw

	var img = vp.get_texture().get_image()
	if img and not img.is_empty():
		# globalize_path replaced
		var p_loaded = load("res://../Data/Level 2. Khiva_schematic.png")
		img.save_png(p)
		print("Khiva schematic saved: ", p)

	get_tree().quit(0)
