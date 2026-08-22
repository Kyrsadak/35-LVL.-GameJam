# res://game/scripts/VictoryScreen.gd
extends Control

## Экран победы: показывает статистику, финальный ранг и результаты прохождения.

@onready var stats_label: Label = $Panel/VBox/StatsLabel
@onready var menu_button: Button = $Panel/VBox/MenuButton
@onready var restart_button: Button = $Panel/VBox/RestartButton

func _ready() -> void:
	menu_button.pressed.connect(_on_menu_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	_build_stats()

func _build_stats() -> void:
	var lines: Array[String] = []
	lines.append("🏆 %s" % GameManager.get_rank_title())
	lines.append("ОАЗИСОВ СВОБОДЫ: %d / %d" % [GameManager.oases_collected, GameManager.TOTAL_OASES])
	lines.append("ВСЕГО СМЕРТЕЙ: %d" % GameManager.total_deaths)
	lines.append("")
	lines.append("ЛУЧШИЕ ВРЕМЕНА ПО СЕКТОРАМ:")
	for i in range(GameManager.LEVELS.size()):
		if GameManager.best_times.has(i):
			lines.append("  %s : %s" % [GameManager.get_level_name(i), GameManager.format_time(GameManager.best_times[i])])
		else:
			lines.append("  %s : —" % GameManager.get_level_name(i))
	stats_label.text = "\n".join(lines)

func _on_menu_pressed() -> void:
	AudioManager.play_ui_click()
	GameManager.go_to_main_menu()

func _on_restart_pressed() -> void:
	AudioManager.play_ui_click()
	GameManager.start_new_game()
