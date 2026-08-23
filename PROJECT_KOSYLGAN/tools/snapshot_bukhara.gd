extends Node3D

func _ready() -> void:
	var vp = SubViewport.new()
	vp.size = Vector2i(1024, 1024)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var scn = load("res://scenes/levels/level_bukhara.tscn").instantiate()
	vp.add_child(scn)

	# Remove existing camera inside level to avoid conflict
	var existing_cam = scn.find_child("TopDownCamera", true, false)
	if existing_cam:
		existing_cam.queue_free()

	var cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 38.0
	cam.transform = Transform3D().looking_at(Vector3.DOWN, Vector3(0, 0, -1))
	cam.position = Vector3(3.0, 40.0, -2.0)
	vp.add_child(cam)

	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw

	var img = vp.get_texture().get_image()
	if img and not img.is_empty():
		var p = ProjectSettings.globalize_path("res://../Data/level_bukhara_topdown.png")
		img.save_png(p)
		print("Snapshot saved: ", p)

	get_tree().quit(0)
