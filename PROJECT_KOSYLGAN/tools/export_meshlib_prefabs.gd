extends SceneTree

func _init() -> void:
	print("--- EXTRACTING ALL MESHES FROM MESHLIB ---")
	var dir = DirAccess.open("res://")
	dir.make_dir_recursive("res://scenes/modular_kit")
	
	var meshlib = load("res://assets/kits/meshlib_prototype_bits.tres") as MeshLibrary
	if not meshlib:
		print("FAILED to load meshlib!")
		quit()
		return
		
	for id in meshlib.get_item_list():
		var item_name = meshlib.get_item_name(id)
		var mesh = meshlib.get_item_mesh(id)
		var shapes = meshlib.get_item_shapes(id)
		
		var root = StaticBody3D.new()
		root.name = item_name
		root.collision_layer = 2
		root.collision_mask = 7
		
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.name = "Mesh"
		mesh_inst.mesh = mesh
		root.add_child(mesh_inst)
		mesh_inst.owner = root
		
		if shapes.size() > 0:
			for i in range(0, shapes.size(), 2):
				var shape = shapes[i]
				var transform = shapes[i+1] if i+1 < shapes.size() else Transform3D.IDENTITY
				var col = CollisionShape3D.new()
				col.name = "CollisionShape" + str(i/2)
				col.shape = shape
				col.transform = transform
				root.add_child(col)
				col.owner = root
		else:
			# Auto create convex collision shape
			var shape = mesh.create_convex_shape()
			var col = CollisionShape3D.new()
			col.name = "CollisionShape"
			col.shape = shape
			root.add_child(col)
			col.owner = root
			
		var scene = PackedScene.new()
		scene.pack(root)
		var path = "res://scenes/modular_kit/" + item_name + ".tscn"
		ResourceSaver.save(scene, path)
		print("Exported prefab: ", path)
		
	print("ALL PREFABS EXPORTED SUCCESSFULLY!")
	quit()
