extends State
class_name PlayerState

var player: PlayerEntity
var character_controller: CharacterController

func _ready() -> void:
	await super._ready()
	if owner is CharacterController:
		character_controller = owner
		var p = character_controller.get_parent()
		if p is PlayerEntity:
			player = p
