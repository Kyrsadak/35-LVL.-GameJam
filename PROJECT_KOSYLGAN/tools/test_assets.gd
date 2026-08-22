extends SceneTree

func _init() -> void:
	print("--- TESTING ALL DEMO PROTOTYPE ASSETS ---")
	var assets = [
		"res://assets/prototype_bits/Barrel_A.gltf",
		"res://assets/prototype_bits/Barrel_B.gltf",
		"res://assets/prototype_bits/Barrel_C.gltf",
		"res://assets/prototype_bits/Box_A.gltf",
		"res://assets/prototype_bits/Box_B.gltf",
		"res://assets/prototype_bits/Box_C.gltf",
		"res://assets/prototype_bits/Can_A.gltf",
		"res://assets/prototype_bits/Can_B.gltf",
		"res://assets/prototype_bits/Door_A_Decorated.gltf",
		"res://assets/prototype_bits/Door_B.gltf",
		"res://assets/prototype_bits/Locker.gltf",
		"res://assets/prototype_bits/Locker_Decorated.gltf",
		"res://assets/prototype_bits/Pallet_Large.gltf",
		"res://assets/prototype_bits/Pallet_Small.gltf",
		"res://assets/prototype_bits/Pallet_Small_Decorated_A.gltf",
		"res://assets/prototype_bits/Pallet_Small_Decorated_B.gltf",
		"res://assets/prototype_bits/Workbench.gltf",
		"res://assets/prototype_bits/Workbench_Decorated.gltf",
		"res://assets/prototype_bits/table_medium.gltf",
		"res://assets/prototype_bits/table_medium_Decorated.gltf",
		"res://assets/prototype_bits/Weaponrack.gltf",
		"res://assets/prototype_bits/Weaponrack_Decorated.gltf",
		"res://assets/prototype_bits/target_wall_large_A.gltf",
		"res://assets/prototype_bits/target_wall_large_B.gltf"
	]
	var success_count = 0
	for a in assets:
		var res = load(a)
		if res:
			var inst = res.instantiate()
			print("OK: ", a)
			success_count += 1
		else:
			print("FAIL: ", a)
	print("TOTAL SUCCESS: ", success_count, " / ", assets.size())
	quit()
