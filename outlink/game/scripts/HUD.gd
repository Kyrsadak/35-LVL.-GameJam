# res://game/scripts/HUD.gd
extends CanvasLayer

## Игровой HUD: батарея, натяжение, счётчик оазисов, флэши, паузa.
## Подписан на все нужные сигналы EventBus.

@onready var battery_bar: ProgressBar = $HBoxContainer/BatteryPanel/VBox/BatteryBar
@onready var battery_label: Label = $HBoxContainer/BatteryPanel/VBox/BatteryLabel
@onready var tension_bar: ProgressBar = $HBoxContainer/TensionPanel/VBox/TensionBar
@onready var tension_label: Label = $HBoxContainer/TensionPanel/VBox/TensionLabel
@onready var status_label: Label = $StatusLabel
@onready var counter_label: Label = $CounterLabel
@onready var level_label: Label = $LevelLabel
@onready var controls_help: Label = $ControlsHelp
@onready var flash_rect: ColorRect = $FlashLayer/FlashRect
@onready var toast_label: Label = $ToastLabel
@onready var toast_animation: AnimationPlayer = $ToastAnimation

var _toast_tween: Tween = null

func _ready() -> void:
	EventBus.battery_changed.connect(_on_battery_changed)
	EventBus.tension_changed.connect(_on_tension_changed)
	EventBus.socket_reached.connect(_on_socket_reached)
	EventBus.tether_broken.connect(_on_tether_broken)
	EventBus.level_completed.connect(_on_level_completed)
	EventBus.oasis_progress_changed.connect(_on_progress_changed)
	EventBus.request_flash.connect(_on_request_flash)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawned.connect(_on_player_respawned)

	battery_bar.max_value = 6.0
	battery_bar.value = 6.0
	tension_bar.value = 0.0
	_set_status("РЕЖИМ: НА ПРИВЯЗИ (БЕЗОПАСНОСТЬ)", Color(0.35, 0.85, 1.0))
	counter_label.text = "ОАЗИСЫ: %d / %d" % [GameManager.oases_collected, GameManager.TOTAL_OASES]
	level_label.text = GameManager.get_level_name(GameManager.current_level_index)
	flash_rect.color = Color(0, 0, 0, 0)

func _on_battery_changed(current: float, max_val: float) -> void:
	battery_bar.max_value = max_val
	battery_bar.value = max(current, 0.0)
	battery_label.text = "БАТАРЕЯ: %.1f сек" % max(current, 0.0)
	# Красный при < 2 сек
	if current < 2.0 and current > 0.0:
		battery_label.modulate = Color(1.0, 0.35, 0.35)
	else:
		battery_label.modulate = Color(1.0, 1.0, 1.0)

func _on_tension_changed(t: float) -> void:
	tension_bar.value = t * 100.0
	tension_label.text = "НАТЯЖЕНИЕ: %d%%" % int(t * 100.0)
	if t >= 0.9:
		tension_bar.modulate = Color(1.0, 0.3, 0.3)
	elif t >= 0.6:
		tension_bar.modulate = Color(1.0, 0.8, 0.3)
	else:
		tension_bar.modulate = Color(0.4, 0.9, 1.0)

func _on_tether_broken(_impulse: Vector2, _tension: float) -> void:
	_set_status("АВТОНОМНОСТЬ! БАТАРЕЯ ТАЕТ!", Color(1.0, 0.3, 0.3))

func _on_socket_reached(_pos: Vector2, _progress_value: int) -> void:
	_set_status("ПОДЗАРЯДКА / ПРИВЯЗЬ ВОССТАНОВЛЕНА", Color(0.4, 1.0, 0.55))
	_show_toast("+ ЗАРЯД")

func _on_level_completed() -> void:
	_set_status("СЕКТОР ЗАЧИЩЕН! ПЕРЕХОД...", Color(1.0, 0.85, 0.2))
	_show_toast("СЕКТОР ПРОЙДЕН")

func _on_progress_changed(current: int, total: int) -> void:
	counter_label.text = "ОАЗИСЫ: %d / %d" % [current, total]
	counter_label.modulate = Color(0.4, 1.0, 0.55)
	get_tree().create_timer(0.5).timeout.connect(func():
		if is_instance_valid(counter_label):
			counter_label.modulate = Color(1, 1, 1, 1)
	)

func _on_player_died() -> void:
	_set_status("СБОЙ ПИТАНИЯ. RESPAWN...", Color(1.0, 0.3, 0.3))

func _on_player_respawned(_pos: Vector2) -> void:
	_set_status("РЕЖИМ: НА ПРИВЯЗИ (БЕЗОПАСНОСТЬ)", Color(0.35, 0.85, 1.0))

func _set_status(text: String, color: Color) -> void:
	status_label.text = text
	status_label.modulate = color

func _on_request_flash(color: Color, duration: float) -> void:
	flash_rect.color = color
	var tw := create_tween()
	tw.tween_property(flash_rect, "color", Color(color.r, color.g, color.b, 0.0), duration)

func _show_toast(text: String) -> void:
	toast_label.text = text
	if _toast_tween:
		_toast_tween.kill()
	toast_label.modulate = Color(1, 1, 1, 1)
	toast_label.scale = Vector2(1.2, 1.2)
	_toast_tween = create_tween().set_parallel(true)
	_toast_tween.tween_property(toast_label, "scale", Vector2(1.0, 1.0), 0.25)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 1.2).set_delay(0.4)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	$PauseOverlay.visible = get_tree().paused

func _on_resume_pressed() -> void:
	AudioManager.play_ui_click()
	get_tree().paused = false
	$PauseOverlay.visible = false

func _on_restart_pressed() -> void:
	AudioManager.play_ui_click()
	get_tree().paused = false
	GameManager.restart_current_level()

func _on_menu_pressed() -> void:
	AudioManager.play_ui_click()
	get_tree().paused = false
	GameManager.go_to_main_menu()
