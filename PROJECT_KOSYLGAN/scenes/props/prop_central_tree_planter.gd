extends Node3D

## Central Stylized Low-Poly Tree with Wooden Planter & Circular Bench
## Perfectly matching the reference art: low-poly faceted green foliage, 
## stylized wood trunk, white stones on moss bed, and warm wooden bench seating.

@onready var foliage_root = $TreeModel/Foliage
var anim_time: float = 0.0

func _process(delta: float) -> void:
	anim_time += delta
	if foliage_root:
		# Gentle organic canopy breeze
		foliage_root.rotation.z = sin(anim_time * 1.2) * 0.02
		foliage_root.rotation.x = cos(anim_time * 0.9) * 0.015
