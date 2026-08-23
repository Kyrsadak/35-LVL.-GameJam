class_name MainMenu3D
extends Node3D

@onready var contraption_root: Node3D = $Contraption
@onready var gear_top: MeshInstance3D = $Contraption/GearTop
@onready var gear_bottom: MeshInstance3D = $Contraption/GearBottom
@onready var slider_music: Node3D = $Contraption/FrontPlate/SliderMusic
@onready var slider_sound: Node3D = $Contraption/FrontPlate/SliderSound
@onready var slider_cube_music: MeshInstance3D = $Contraption/FrontPlate/SliderMusic/CubeMusic
@onready var slider_cube_sound: MeshInstance3D = $Contraption/FrontPlate/SliderSound/CubeSound
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var camera: Camera3D = $Camera3D

# UI Overlay Elements
@onready var ui_canvas: CanvasLayer = $CanvasLayer
@onready var rules_modal: PanelContainer = %RulesModal
@onready var close_rules_btn: Button = %CloseRulesBtn

@onready var btn_lvl0: Button = %BtnLvl0
@onready var btn_lvl1: Button = %BtnLvl1
@onready var btn_lvl2: Button = %BtnLvl2
@onready var btn_lvl3: Button = %BtnLvl3
@onready var btn_lvl4: Button = %BtnLvl4

var anim_time: float = 0.0
var music_vol_ratio: float = 0.75
var sound_vol_ratio: float = 0.85

var is_dragging_music: bool = false
var is_dragging_sound: bool = false

# Slider geometry bounds in local X coordinates of SliderMusic / SliderSound
const SLIDER_LOCAL_MIN: float = -0.48
const SLIDER_LOCAL_MAX: float = 0.48

func _ready() -> void:
	_build_procedural_gears()
	_update_slider_positions()
	
	if rules_modal:
		rules_modal.visible = false
	if close_rules_btn:
		close_rules_btn.pressed.connect(_hide_rules)
		close_rules_btn.mouse_entered.connect(_play_hover)

	# Play ambient background music safely via SoundManager
	if SoundManager:
		_apply_music_volume()
		SoundManager.play_bgm()

	# Connect Level Select Buttons
	if btn_lvl0:
		btn_lvl0.pressed.connect(func(): _play_click(); _launch_game(1))
		btn_lvl0.mouse_entered.connect(_play_hover)
	if btn_lvl1:
		btn_lvl1.pressed.connect(func(): _play_click(); _launch_game(2))
		btn_lvl1.mouse_entered.connect(_play_hover)
	if btn_lvl2:
		btn_lvl2.pressed.connect(func(): _play_click(); _launch_game(3))
		btn_lvl2.mouse_entered.connect(_play_hover)
	if btn_lvl3:
		btn_lvl3.pressed.connect(func(): _play_click(); _launch_game(4))
		btn_lvl3.mouse_entered.connect(_play_hover)
	if btn_lvl4:
		btn_lvl4.pressed.connect(func(): _play_click(); _launch_game(5))
		btn_lvl4.mouse_entered.connect(_play_hover)

	# Play ambient background music safely
	if audio_player:
		var music_path = "res://audio/loading_screen.mp3"
		if not ResourceLoader.exists(music_path):
			music_path = "res://audio/bgm.mp3"
		if ResourceLoader.exists(music_path):
			var music_res = ResourceLoader.load(music_path)
			if music_res is AudioStream:
				audio_player.stream = music_res
				_apply_music_volume()
				audio_player.play()
>>>>>>> origin/daulet

func _process(delta: float) -> void:
	anim_time += delta
	
	# Continuous mechanical gear rotation
	if gear_top:
		gear_top.rotation.z += 0.35 * delta
	if gear_bottom:
		gear_bottom.rotation.z -= 0.52 * delta
		
	# Subtle living suspension wobble / float
	if contraption_root:
		contraption_root.rotation.z = sin(anim_time * 1.6) * 0.018
		contraption_root.rotation.x = cos(anim_time * 1.2) * 0.012
		contraption_root.position.y = sin(anim_time * 2.0) * 0.035

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_0:
			_play_click()
			_launch_game(1)
		elif event.keycode == KEY_1:
			_play_click()
			_launch_game(2)
		elif event.keycode == KEY_2:
			_play_click()
			_launch_game(3)
		elif event.keycode == KEY_3:
			_play_click()
			_launch_game(4)
		elif event.keycode == KEY_4 or event.keycode == KEY_5:
			_play_click()
			_launch_game(5)

	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_handle_mouse_click(mb.position)
			else:
				is_dragging_music = false
				is_dragging_sound = false
				
	elif event is InputEventMouseMotion:
		var mm = event as InputEventMouseMotion
		if is_dragging_music or is_dragging_sound:
			_handle_slider_drag(mm.position)
		else:
			_handle_mouse_hover(mm.position)

func _handle_mouse_click(screen_pos: Vector2) -> void:
	var hit = _raycast_mouse(screen_pos)
	if hit.is_empty():
		return
		
	var collider = hit.collider
	if not collider or not collider is Node:
		return
		
	var target_name = collider.name
	var target_parent = collider.get_parent()
	var parent_name = target_parent.name if target_parent else ""

	if "BtnPlay" in target_name or "BtnPlay" in parent_name:
		_animate_click_feedback(collider)
		_play_click()
		_launch_game(1)
	elif "BtnLvl1" in target_name or "BtnLvl1" in parent_name:
		_animate_click_feedback(collider)
		_play_click()
		_launch_game(1)
	elif "BtnLvl2" in target_name or "BtnLvl2" in parent_name:
		_animate_click_feedback(collider)
		_play_click()
		_launch_game(2)
	elif "BtnLvl3" in target_name or "BtnLvl3" in parent_name:
		_animate_click_feedback(collider)
		_play_click()
		_launch_game(3)
	elif "BtnRules" in target_name or "BtnRules" in parent_name:
		_animate_click_feedback(collider)
		_play_click()
		_show_rules()
	elif "BtnExit" in target_name or "BtnExit" in parent_name or "HexBadge" in target_name:
		_animate_click_feedback(collider)
		_play_click()
		get_tree().quit()
	elif "SliderMusic" in target_name or "SliderMusic" in parent_name:
		is_dragging_music = true
		_handle_slider_drag(screen_pos)
		_play_click()
	elif "SliderSound" in target_name or "SliderSound" in parent_name:
		is_dragging_sound = true
		_handle_slider_drag(screen_pos)
		_play_click()

var _last_hovered_collider: Node = null
func _handle_mouse_hover(screen_pos: Vector2) -> void:
	var hit = _raycast_mouse(screen_pos)
	var collider = hit.collider if not hit.is_empty() and hit.has("collider") else null
	if collider != _last_hovered_collider:
		_last_hovered_collider = collider
		if collider:
			_play_hover()

func _handle_slider_drag(screen_pos: Vector2) -> void:
	var slider_node = slider_music if is_dragging_music else slider_sound
	if not slider_node or not camera:
		return
		
	var from = camera.project_ray_origin(screen_pos)
	var dir = camera.project_ray_normal(screen_pos)
	
	# Project ray onto slider plane
	var slider_plane = Plane(slider_node.global_transform.basis.z, slider_node.global_position)
	var hit_world = slider_plane.intersects_ray(from, dir)
	if hit_world == null:
		return
		
	var local_pos = slider_node.to_local(hit_world)
	var t = clamp(inverse_lerp(SLIDER_LOCAL_MIN, SLIDER_LOCAL_MAX, local_pos.x), 0.0, 1.0)
	
	if is_dragging_music:
		music_vol_ratio = t
		_apply_music_volume()
	elif is_dragging_sound:
		sound_vol_ratio = t
		_apply_sound_volume()
	_update_slider_positions()

func _update_slider_positions() -> void:
	if slider_cube_music:
		slider_cube_music.position.x = lerp(SLIDER_LOCAL_MIN, SLIDER_LOCAL_MAX, music_vol_ratio)
	if slider_cube_sound:
		slider_cube_sound.position.x = lerp(SLIDER_LOCAL_MIN, SLIDER_LOCAL_MAX, sound_vol_ratio)

func _apply_music_volume() -> void:
	var vol_db = -80.0 if music_vol_ratio <= 0.01 else linear_to_db(music_vol_ratio)
	if SoundManager and SoundManager.has_method("set_bgm_volume"):
		SoundManager.set_bgm_volume(vol_db)
	if audio_player:
		audio_player.volume_db = vol_db

func _apply_sound_volume() -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		if sound_vol_ratio <= 0.01:
			AudioServer.set_bus_volume_db(bus_idx, -80.0)
		else:
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(sound_vol_ratio))

func _animate_click_feedback(node: Node) -> void:
	if not node is Node3D:
		return
	var orig_pos = (node as Node3D).position
	var t = create_tween()
	t.tween_property(node, "position:z", orig_pos.z - 0.06, 0.08).set_trans(Tween.TRANS_QUAD)
	t.tween_property(node, "position:z", orig_pos.z, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _launch_game(level_idx: int) -> void:
	var t = create_tween().set_parallel(true)
	t.tween_property(camera, "fov", 28.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(contraption_root, "position:z", -1.5, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(self, "modulate:a", 0.0, 0.45)
	t.chain().tween_callback(func():
		if GameManager:
			GameManager.load_level(level_idx)
	)

func _show_rules() -> void:
	if rules_modal:
		rules_modal.visible = true
		rules_modal.modulate.a = 0.0
		var t = create_tween()
		t.tween_property(rules_modal, "modulate:a", 1.0, 0.2)

func _hide_rules() -> void:
	if rules_modal:
		var t = create_tween()
		t.tween_property(rules_modal, "modulate:a", 0.0, 0.15)
		t.tween_callback(func(): rules_modal.visible = false)

func _play_hover(_unused: Node = null) -> void:
	if SoundManager and SoundManager.has_method("play_ui_hover"):
		SoundManager.play_ui_hover()

func _play_click() -> void:
	if SoundManager and SoundManager.has_method("play_ui_click"):
		SoundManager.play_ui_click()

func _raycast_mouse(screen_pos: Vector2) -> Dictionary:
	if not camera:
		return {}
	var from = camera.project_ray_origin(screen_pos)
	var dir = camera.project_ray_normal(screen_pos)
	var to = from + dir * 100.0
	var space = get_world_3d().direct_space_state
	if not space:
		return {}
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	return space.intersect_ray(query)

func _build_procedural_gears() -> void:
	if gear_top:
		gear_top.mesh = _generate_gear_mesh(1.15, 0.90, 0.28, 11, 0.14)
		var mat_top = StandardMaterial3D.new()
		mat_top.albedo_color = Color(0.68, 0.54, 0.72) # Stylized purple cog
		mat_top.metallic = 0.4
		mat_top.roughness = 0.45
		gear_top.material_override = mat_top

	if gear_bottom:
		gear_bottom.mesh = _generate_gear_mesh(0.85, 0.68, 0.22, 9, 0.12)
		var mat_bot = StandardMaterial3D.new()
		mat_bot.albedo_color = Color(0.55, 0.44, 0.60) # Darker purple cog
		mat_bot.metallic = 0.45
		mat_bot.roughness = 0.45
		gear_bottom.material_override = mat_bot

func _generate_gear_mesh(outer_r: float, root_r: float, hole_r: float, teeth: int, depth: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half_d = depth * 0.5
	
	# Generate outer rim polygon with teeth
	var rim_pts: Array[Vector2] = []
	for i in range(teeth):
		var base_a = float(i) * (TAU / float(teeth))
		var step_a = TAU / float(teeth)
		
		var a0 = base_a
		var a1 = base_a + step_a * 0.25
		var a2 = base_a + step_a * 0.40
		var a3 = base_a + step_a * 0.60
		var a4 = base_a + step_a * 0.75
		
		rim_pts.append(Vector2(cos(a0) * root_r, sin(a0) * root_r))
		rim_pts.append(Vector2(cos(a1) * root_r, sin(a1) * root_r))
		rim_pts.append(Vector2(cos(a2) * outer_r, sin(a2) * outer_r))
		rim_pts.append(Vector2(cos(a3) * outer_r, sin(a3) * outer_r))
		rim_pts.append(Vector2(cos(a4) * root_r, sin(a4) * root_r))

	var n_pts = rim_pts.size()
	# Front & Back Faces + Center Hole
	for i in range(n_pts):
		var next_i = (i + 1) % n_pts
		var p0 = rim_pts[i]
		var p1 = rim_pts[next_i]
		
		var h_ang0 = float(i) * (TAU / float(n_pts))
		var h_ang1 = float(next_i) * (TAU / float(n_pts))
		var h0 = Vector2(cos(h_ang0) * hole_r, sin(h_ang0) * hole_r)
		var h1 = Vector2(cos(h_ang1) * hole_r, sin(h_ang1) * hole_r)

		# Front Face (+Z)
		st.add_vertex(Vector3(p0.x, p0.y, half_d))
		st.add_vertex(Vector3(p1.x, p1.y, half_d))
		st.add_vertex(Vector3(h1.x, h1.y, half_d))

		st.add_vertex(Vector3(p0.x, p0.y, half_d))
		st.add_vertex(Vector3(h1.x, h1.y, half_d))
		st.add_vertex(Vector3(h0.x, h0.y, half_d))

		# Back Face (-Z)
		st.add_vertex(Vector3(p1.x, p1.y, -half_d))
		st.add_vertex(Vector3(p0.x, p0.y, -half_d))
		st.add_vertex(Vector3(h0.x, h0.y, -half_d))

		st.add_vertex(Vector3(p1.x, p1.y, -half_d))
		st.add_vertex(Vector3(h0.x, h0.y, -half_d))
		st.add_vertex(Vector3(h1.x, h1.y, -half_d))

		# Outer Rim Sides
		st.add_vertex(Vector3(p0.x, p0.y, half_d))
		st.add_vertex(Vector3(p0.x, p0.y, -half_d))
		st.add_vertex(Vector3(p1.x, p1.y, -half_d))

		st.add_vertex(Vector3(p0.x, p0.y, half_d))
		st.add_vertex(Vector3(p1.x, p1.y, -half_d))
		st.add_vertex(Vector3(p1.x, p1.y, half_d))

	st.generate_normals()
	return st.commit()
