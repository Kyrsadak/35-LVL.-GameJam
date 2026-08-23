class_name FloorCable
extends Node3D

## 3D Sci-Fi Power Conduit / Cable on the floor.
## Dynamically connects interactive elements and illuminates when energized.

@export var points: Array[Vector3] = []
@export var cable_radius: float = 0.04
@export var unpowered_color: Color = Color(0.22, 0.24, 0.28, 1.0)
@export var powered_color: Color = Color(0.15, 0.85, 1.0, 1.0)
@export var powered_emission_energy: float = 2.5
@export var is_powered: bool = false : set = set_powered
@export var source_plate_path: NodePath
@export var target_terminal_path: NodePath

var cable_mesh_instance: MeshInstance3D
var cable_material: StandardMaterial3D

func _ready() -> void:
	_create_material()
	_generate_cable_mesh()
	_update_visuals()
	
	# Auto-bind to PressurePlate signals if assigned
	if not source_plate_path.is_empty():
		var plate = get_node_or_null(source_plate_path)
		if plate and plate.has_signal("activated"):
			plate.activated.connect(func(): set_powered(true))
			plate.deactivated.connect(func(): set_powered(false))

func _create_material() -> void:
	cable_material = StandardMaterial3D.new()
	cable_material.roughness = 0.35
	cable_material.metallic = 0.65

func set_powered(state: bool) -> void:
	is_powered = state
	_update_visuals()

func _update_visuals() -> void:
	if not cable_material:
		return
	if is_powered:
		cable_material.albedo_color = powered_color
		cable_material.emission_enabled = true
		cable_material.emission = powered_color
		cable_material.emission_energy_multiplier = powered_emission_energy
	else:
		cable_material.albedo_color = unpowered_color
		cable_material.emission_enabled = false
		cable_material.emission = Color.BLACK
		cable_material.emission_energy_multiplier = 0.0

func _generate_cable_mesh() -> void:
	if points.size() < 2:
		return
		
	# Clean up previous mesh
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()

	cable_mesh_instance = MeshInstance3D.new()
	var arr_mesh = ArrayMesh.new()
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	var uvs = PackedVector2Array()
	
	var ring_segments = 8
	
	for i in range(points.size()):
		var p = points[i]
		var fwd = Vector3.FORWARD
		if i < points.size() - 1:
			fwd = (points[i+1] - p).normalized()
		elif i > 0:
			fwd = (p - points[i-1]).normalized()
			
		var up = Vector3.UP
		if abs(fwd.dot(up)) > 0.95:
			up = Vector3.RIGHT
		var right = fwd.cross(up).normalized()
		var real_up = right.cross(fwd).normalized()
		
		var v_offset = i * ring_segments
		for s in range(ring_segments):
			var angle = (float(s) / ring_segments) * TAU
			var offset = (right * cos(angle) + real_up * sin(angle)) * cable_radius
			# Keep cable resting on the floor plane
			var pos = p + offset
			if pos.y < 0.02:
				pos.y = 0.02
			vertices.append(pos)
			normals.append(offset.normalized())
			uvs.append(Vector2(float(s) / ring_segments, float(i)))
			
		if i < points.size() - 1:
			var next_offset = (i + 1) * ring_segments
			for s in range(ring_segments):
				var next_s = (s + 1) % ring_segments
				var c1 = v_offset + s
				var c2 = v_offset + next_s
				var n1 = next_offset + s
				var n2 = next_offset + next_s
				
				indices.append(c1)
				indices.append(n1)
				indices.append(c2)
				
				indices.append(c2)
				indices.append(n1)
				indices.append(n2)

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	cable_mesh_instance.mesh = arr_mesh
	cable_mesh_instance.material_override = cable_material
	add_child(cable_mesh_instance)
