# res://game/scripts/Level.gd
extends Node2D
class_name Level

## Скрипт уровня. При старте:
##  - находит стартовый оазис (Socket с is_starting_anchor = true)
##  - перемещает игрока к нему и цепляет
##  - фиксирует checkpoint в GameManager

@export var level_index: int = 0

func _ready() -> void:
	# Настроим индекс в GameManager (на случай, если уровень запущен напрямую)
	if GameManager.current_level_index != level_index and level_index >= 0:
		GameManager.current_level_index = level_index

	var start_socket: Socket = _find_starting_socket()
	var player_node := _find_player()
	if player_node and start_socket:
		player_node.global_position = start_socket.global_position
		if player_node is Player:
			(player_node as Player).current_socket_pos = start_socket.global_position
		GameManager.set_checkpoint(start_socket.global_position)

func _find_starting_socket() -> Socket:
	for child in get_children():
		if child is Socket and (child as Socket).is_starting_anchor:
			return child as Socket
	# fallback: первый Socket
	for child in get_children():
		if child is Socket:
			return child as Socket
	return null

func _find_player() -> Node2D:
	for child in get_children():
		if child.is_in_group("Player"):
			return child
	return null
