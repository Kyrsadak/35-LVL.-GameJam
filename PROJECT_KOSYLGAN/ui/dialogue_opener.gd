extends Area3D
## DialogueOpener — триггер области для запуска диалога
## Используется коллектаблами и раздатчиками предметов

@export var dialog_timeline: Resource = null
@export var jump_to_label: String = "OnDefault"
@export var one_shot: bool = true

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if one_shot and _triggered:
		return
	# Проверяем что это игрок
	if not (body.is_in_group("player") or body is CharacterBody3D):
		return
	_triggered = true
	_try_open_dialogue()

func _try_open_dialogue() -> void:
	if dialog_timeline == null:
		return
	# Пробуем найти DialogueManager или похожий
	var dm = get_tree().get_first_node_in_group("dialogue_manager")
	if dm and dm.has_method("start_dialogue"):
		dm.start_dialogue(dialog_timeline, jump_to_label)
	elif RobotManager and RobotManager.has_method("start_dialogue"):
		RobotManager.start_dialogue(dialog_timeline, jump_to_label)

func reset() -> void:
	_triggered = false
