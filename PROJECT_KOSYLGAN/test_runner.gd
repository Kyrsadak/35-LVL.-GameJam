extends SceneTree

func _init() -> void:
	print("--- Running Test Runner for Actual Scenes ---")
	var scenes_to_test = [
		"res://ui/main_menu.tscn",
		"res://ui/hud.tscn",
		"res://ui/victory_screen.tscn",
		"res://ui/captcha_ending.tscn",
		"res://ui/crt_tv_off.tscn",
		"res://scenes/main.tscn",
		"res://scenes/levels/tutorial.tscn",
		"res://scenes/levels/level_tashkent.tscn",
		"res://scenes/levels/level_samarkand.tscn",
		"res://scenes/levels/level_bukhara.tscn",
		"res://scenes/levels/level_khiva.tscn",
		"res://characters/robots/RobotAtlas.tscn",
		"res://characters/robots/RobotCipher.tscn",
		"res://systems/freedom_portal.tscn",
		"res://systems/socket_terminal.tscn",
		"res://systems/dual_generator.tscn",
		"res://systems/key_module.tscn",
		"res://systems/pushable_box.tscn",
		"res://systems/pressure_plate.tscn",
		"res://systems/terminal.tscn",
		"res://systems/guide_tablet.tscn",
		"res://systems/floor_cable.tscn",
		"res://systems/laser_gate.tscn",
		"res://systems/charging_station.tscn",
		"res://systems/top_down_camera.tscn",
		"res://minigames/wire_cutting.tscn",
		"res://minigames/switch_puzzle.tscn"
	]
	
	var pass_count = 0
	var fail_count = 0
	
	for s in scenes_to_test:
		var res = ResourceLoader.load(s)
		if res:
			var inst = res.instantiate()
			if inst:
				print("PASS: ", s)
				pass_count += 1
				inst.queue_free()
			else:
				print("FAILED to instantiate: ", s)
				fail_count += 1
		else:
			print("FAILED to load resource: ", s)
			fail_count += 1
			
	print("\n=== Test finished: %d passed, %d failed ===" % [pass_count, fail_count])
	quit(fail_count)
