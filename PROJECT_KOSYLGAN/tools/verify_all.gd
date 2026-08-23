extends SceneTree

func _init():
	print("=== STARTING COMPREHENSIVE AUTOMATED VERIFICATION ===")
	call_deferred("_run_tests")

func _run_tests():
	var passed = 0
	var failed = 0
	
	var scenes_to_test = [
		"res://ui/main_menu.tscn",
		"res://ui/hud.tscn",
		"res://ui/captcha_ending.tscn",
		"res://ui/victory_screen.tscn",
		"res://ui/crt_tv_off.tscn",
		"res://characters/robots/RobotAtlas.tscn",
		"res://characters/robots/RobotCipher.tscn",
		"res://characters/robots/RobotBase.tscn",
		"res://minigames/wire_cutting.tscn",
		"res://minigames/switch_puzzle.tscn",
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
		"res://scenes/levels/tutorial.tscn",
		"res://scenes/levels/level1.tscn",
		"res://scenes/levels/level_bukhara.tscn",
		"res://scenes/levels/level_samarkand.tscn",
		"res://scenes/levels/level_khiva.tscn",
		"res://scenes/levels/level_tashkent.tscn",
		"res://scenes/main.tscn"
	]
	
	for path in scenes_to_test:
		if not ResourceLoader.exists(path):
			printerr("[FAIL] Scene does not exist: ", path)
			failed += 1
			continue
		
		var packed = load(path)
		if not packed:
			printerr("[FAIL] Failed to load packed scene: ", path)
			failed += 1
			continue
			
		var inst = packed.instantiate()
		if not inst:
			printerr("[FAIL] Failed to instantiate scene: ", path)
			failed += 1
			continue
			
		root.add_child(inst)
		await process_frame
		
		inst.queue_free()
		await process_frame
		print("[PASS] Scene Loaded & Instantiated OK: ", path)
		passed += 1
		
	print("\n=== VERIFICATION RESULTS ===")
	print("Passed: %d | Failed: %d" % [passed, failed])
	
	if failed == 0:
		print(">>> ALL 29 CORE SCENES PASSED PERFECTLY! <<<")
	else:
		printerr(">>> SOME TESTS FAILED! <<<")
		
	quit(0 if failed == 0 else 1)
