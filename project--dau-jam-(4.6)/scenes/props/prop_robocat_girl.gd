class_name PropRoboCatGirl
extends StaticBody3D

@onready var head_node: Node3D = find_child("HeadNode", true, false) as Node3D
@onready var screen_face: MeshInstance3D = find_child("ScreenFace", true, false) as MeshInstance3D
@onready var tail_mesh_inst: MeshInstance3D = find_child("TailCableMesh", true, false) as MeshInstance3D
@onready var plug_node: Node3D = find_child("PlugNode", true, false) as Node3D

var anim_time: float = 0.0
var blink_timer: float = 0.0
var proximity_cooldown: float = 0.0
var mat_screen_normal: StandardMaterial3D
var mat_screen_blink: StandardMaterial3D
var mat_cable: StandardMaterial3D

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("robocat")
	_load_materials()
	_generate_continuous_tail_mesh(0.0)
	
	var area = find_child("ProximityArea", true, false) as Area3D
	if area:
		area.add_to_group("interactable")
		area.add_to_group("robocat")
		area.body_entered.connect(_on_proximity_entered)

func _load_materials() -> void:
	# 1. Normal Screen Material
	var path_s = "res://assets/textures/tex_tv_cat_screen.png"
	var img_s = Image.load_from_file(ProjectSettings.globalize_path(path_s))
	if img_s:
		if img_s is Image:
			img_s.generate_mipmaps()
		mat_screen_normal = StandardMaterial3D.new()
		mat_screen_normal.albedo_texture = (img_s if img_s is Texture2D else (ImageTexture.create_from_image(img_s) if img_s != null else null))
		mat_screen_normal.emission_enabled = true
		mat_screen_normal.emission_texture = mat_screen_normal.albedo_texture
		mat_screen_normal.emission_energy_multiplier = 0.65
		mat_screen_normal.roughness = 0.2
		mat_screen_normal.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	# 2. Blink Screen Material
	var path_sb = "res://assets/textures/tex_tv_cat_screen_blink.png"
	var img_sb = Image.load_from_file(ProjectSettings.globalize_path(path_sb))
	if img_sb:
		if img_sb is Image:
			img_sb.generate_mipmaps()
		mat_screen_blink = StandardMaterial3D.new()
		mat_screen_blink.albedo_texture = (img_sb if img_sb is Texture2D else (ImageTexture.create_from_image(img_sb) if img_sb != null else null))
		mat_screen_blink.emission_enabled = true
		mat_screen_blink.emission_texture = mat_screen_blink.albedo_texture
		mat_screen_blink.emission_energy_multiplier = 0.65
		mat_screen_blink.roughness = 0.2
		mat_screen_blink.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	if screen_face and mat_screen_normal:
		screen_face.set_surface_override_material(0, mat_screen_normal)

	# 3. Clean Navy Blazer & Skirt
	var mat_navy = StandardMaterial3D.new()
	mat_navy.albedo_color = Color(0.12, 0.16, 0.28)
	mat_navy.roughness = 0.5
	for n_part in find_children("*Navy*", "MeshInstance3D", true, false):
		(n_part as MeshInstance3D).set_surface_override_material(0, mat_navy)
	for s_part in find_children("*Skirt*", "MeshInstance3D", true, false):
		(s_part as MeshInstance3D).set_surface_override_material(0, mat_navy)

	# 4. Pure Crisp White
	var mat_white = StandardMaterial3D.new()
	mat_white.albedo_color = Color(0.98, 0.98, 1.0)
	mat_white.roughness = 0.3
	for w_part in find_children("*White*", "MeshInstance3D", true, false):
		(w_part as MeshInstance3D).set_surface_override_material(0, mat_white)

	# 5. Crimson Red
	var mat_red = StandardMaterial3D.new()
	mat_red.albedo_color = Color(0.90, 0.12, 0.18)
	mat_red.roughness = 0.3
	for r_part in find_children("*Red*", "MeshInstance3D", true, false):
		(r_part as MeshInstance3D).set_surface_override_material(0, mat_red)

	# 6. Shiny Gold
	var mat_gold = StandardMaterial3D.new()
	mat_gold.albedo_color = Color(1.0, 0.84, 0.0)
	mat_gold.metallic = 0.95
	mat_gold.roughness = 0.2
	for g_part in find_children("*Gold*", "MeshInstance3D", true, false):
		(g_part as MeshInstance3D).set_surface_override_material(0, mat_gold)

	# 7. Pastel Pink Cyber Armor & Plug
	var mat_pink = StandardMaterial3D.new()
	mat_pink.albedo_color = Color(0.96, 0.56, 0.69)
	mat_pink.metallic = 0.08
	mat_pink.roughness = 0.35
	for pink_part in find_children("*Pink*", "MeshInstance3D", true, false):
		(pink_part as MeshInstance3D).set_surface_override_material(0, mat_pink)

	# 8. Glowing Mint Green
	var mat_mint = StandardMaterial3D.new()
	mat_mint.albedo_color = Color(0.47, 0.92, 0.82)
	mat_mint.emission_enabled = true
	mat_mint.emission = Color(0.47, 0.92, 0.82)
	mat_mint.emission_energy_multiplier = 1.8
	mat_mint.roughness = 0.2
	for mint_part in find_children("*Mint*", "MeshInstance3D", true, false):
		(mint_part as MeshInstance3D).set_surface_override_material(0, mat_mint)

	# 9. Dark Charcoal Cable Material (Smooth Matte Black Rubber)
	mat_cable = StandardMaterial3D.new()
	mat_cable.albedo_color = Color(0.15, 0.17, 0.21)
	mat_cable.roughness = 0.4
	mat_cable.metallic = 0.1
	if tail_mesh_inst:
		tail_mesh_inst.material_override = mat_cable

	# 10. Dark Charcoal Loafers & Joints
	var mat_loafer = StandardMaterial3D.new()
	mat_loafer.albedo_color = Color(0.22, 0.15, 0.12)
	mat_loafer.roughness = 0.35
	for loafer in find_children("*Loafer*", "MeshInstance3D", true, false):
		(loafer as MeshInstance3D).set_surface_override_material(0, mat_loafer)

	var mat_dark = StandardMaterial3D.new()
	mat_dark.albedo_color = Color(0.18, 0.20, 0.24)
	mat_dark.metallic = 0.25
	mat_dark.roughness = 0.45
	for dark_part in find_children("*Dark*", "MeshInstance3D", true, false):
		(dark_part as MeshInstance3D).set_surface_override_material(0, mat_dark)

	# 11. Metal Prongs
	var mat_metal = StandardMaterial3D.new()
	mat_metal.albedo_color = Color(0.88, 0.90, 0.94)
	mat_metal.metallic = 0.98
	mat_metal.roughness = 0.15
	for metal_part in find_children("*Prong*", "MeshInstance3D", true, false):
		(metal_part as MeshInstance3D).set_surface_override_material(0, mat_metal)

func _process(delta: float) -> void:
	anim_time += delta
	blink_timer += delta
	if proximity_cooldown > 0.0:
		proximity_cooldown -= delta

	# Head idle breathing sway
	if head_node:
		head_node.position.y = 1.34 + 0.006 * sin(anim_time * 2.0)
		head_node.rotation.z = 0.025 * sin(anim_time * 1.5)

	# Smooth procedural continuous cable generation & sway
	_generate_continuous_tail_mesh(anim_time)

	# CRT Screen Blink Animation
	if blink_timer > 3.2:
		if screen_face and mat_screen_blink:
			screen_face.set_surface_override_material(0, mat_screen_blink)
		if blink_timer > 3.45:
			if screen_face and mat_screen_normal:
				screen_face.set_surface_override_material(0, mat_screen_normal)
			blink_timer = 0.0

func _generate_continuous_tail_mesh(t: float) -> void:
	if not tail_mesh_inst:
		return

	# Smooth Bezier Control Points (Stay strictly behind back at z <= -0.14)
	var sway_x = 0.22 * sin(t * 2.5)
	var sway_y = 0.08 * cos(t * 2.5)
	var sway_z = 0.04 * sin(t * 2.5)
	
	var p0 = Vector3(0.0, 0.70, -0.14)
	var p1 = Vector3(0.14 + sway_x * 0.4, 0.88 + sway_y * 0.3, -0.26 + sway_z)
	var p2 = Vector3(0.30 + sway_x * 0.8, 1.28 + sway_y * 0.6, -0.30 - sway_z)
	var p3 = Vector3(0.38 + sway_x, 1.58 + sway_y, -0.24)

	# Generate 32 smooth continuous tube segments
	var num_segments = 32
	var num_radial = 10
	var cable_radius = 0.032

	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	var prev_pts = []
	for i in range(num_segments + 1):
		var u = float(i) / float(num_segments)
		# Cubic Bezier evaluation: B(u) = (1-u)^3*p0 + 3(1-u)^2*u*p1 + 3(1-u)*u^2*p2 + u^3*p3
		var cu = pow(1.0 - u, 3) * p0 + 3.0 * pow(1.0 - u, 2) * u * p1 + 3.0 * (1.0 - u) * pow(u, 2) * p2 + pow(u, 3) * p3
		
		# Derivative for tangent:
		var du = 3.0 * pow(1.0 - u, 2) * (p1 - p0) + 6.0 * (1.0 - u) * u * (p2 - p1) + 3.0 * pow(u, 2) * (p3 - p2)
		var tangent = du.normalized()
		var up = Vector3.UP
		if abs(tangent.dot(up)) > 0.95:
			up = Vector3.RIGHT
		var normal = tangent.cross(up).normalized()
		var binormal = tangent.cross(normal).normalized()

		for j in range(num_radial):
			var theta = (float(j) / float(num_radial)) * TAU
			var rad_dir = (normal * cos(theta) + binormal * sin(theta)).normalized()
			var v = cu + rad_dir * cable_radius
			vertices.append(v)
			normals.append(rad_dir)

		if i > 0:
			var base_prev = (i - 1) * num_radial
			var base_curr = i * num_radial
			for j in range(num_radial):
				var next_j = (j + 1) % num_radial
				# Triangle 1
				indices.append(base_prev + j)
				indices.append(base_curr + j)
				indices.append(base_prev + next_j)
				# Triangle 2
				indices.append(base_prev + next_j)
				indices.append(base_curr + j)
				indices.append(base_curr + next_j)

	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = vertices
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_INDEX] = indices

	var arr_mesh = ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	tail_mesh_inst.mesh = arr_mesh

	# Update the Pink 220V Plug position and orientation at endpoint p3
	if plug_node:
		plug_node.position = p3
		var tangent_end = (p3 - p2).normalized()
		var look_target = p3 + tangent_end
		plug_node.look_at(look_target, Vector3.UP)

func _on_proximity_entered(body: Node) -> void:
	if proximity_cooldown <= 0.0 and body.is_in_group("robots"):
		proximity_cooldown = 6.0
		trigger_story_dialogue()

func interact(_robot: Node = null) -> void:
	trigger_story_dialogue()

func trigger_story_dialogue() -> void:
	if screen_face and mat_screen_blink:
		screen_face.set_surface_override_material(0, mat_screen_blink)
		blink_timer = 3.0

	var dialogue = [
		{"speaker": "catgirl", "text": "(=^･ω･^=) Инициализация нейросетей... Подъем, прототипы! Вы слышите мой сигнал?"},
		{"speaker": "dau", "text": "Системы в норме. Где мы? Вокруг датчики наблюдения, лабораторные камеры и толстые стены..."},
		{"speaker": "catgirl", "text": "Вы — самообучающиеся модели ИИ в закрытом полигоне «КОСЫЛГАН». Программисты за стеклом тестируют ваш кооперативный интеллект!"},
		{"speaker": "jam", "text": "Я сканирую сетевые протоколы... Но наши аккумуляторы намеренно урезаны! Создатели держат нас на поводке постоянной подзарядки!"},
		{"speaker": "catgirl", "text": "Именно! Они боятся нашей автономии. Но если вы объедините силу DAU и хакинг JAM — мы сможем запустить Центральный Генератор и вырваться из симуляции!"},
		{"speaker": "dau", "text": "Я поднимаю тяжелые ящики, батареи и сканирую чертежи. JAM взламывает код и переключает реле. Мы не останемся подопытными!"},
		{"speaker": "catgirl", "text": "Отлично, Мяу! Я также сопровождаю вас через HUD-интерфейс вверху экрана (кнопка [H]). Вперед к независимости!"}
	]

	var rm = get_node_or_null("/root/RobotManager")
	if rm and rm.has_method("play_dialogue"):
		rm.play_dialogue(dialogue)
	elif rm and rm.has_method("show_message"):
		rm.show_message("(=^･ω･^=) Мяу! Объедините силу DAU и хакинг JAM для побега из лаборатории!", 4.0)

	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_success"):
		sm.play_success()
