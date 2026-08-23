@tool
extends SceneTree

func _init():
	print("--- TESTING ROBOT SKINS ---")
	var atlas_scene = load("res://characters/robots/RobotAtlas.tscn")
	var atlas = atlas_scene.instantiate()
	var skin_node = atlas.get_node_or_null("Skin")
	print("Atlas Skin node: ", skin_node)
	print("Atlas Skin script: ", skin_node.get_script() if skin_node else "null")
	print("Atlas Skin has update_move_animation: ", skin_node.has_method("update_move_animation") if skin_node else false)
	if skin_node:
		var anim = skin_node.find_child("AnimationPlayer", true, false)
		print("Atlas AnimationPlayer: ", anim)
		if anim:
			print("Atlas Animations: ", anim.get_animation_list())

	var cipher_scene = load("res://characters/robots/RobotCipher.tscn")
	var cipher = cipher_scene.instantiate()
	var cipher_skin = cipher.get_node_or_null("Skin")
	print("Cipher Skin node: ", cipher_skin)
	print("Cipher Skin script: ", cipher_skin.get_script() if cipher_skin else "null")
	print("Cipher Skin has update_move_animation: ", cipher_skin.has_method("update_move_animation") if cipher_skin else false)
	if cipher_skin:
		var anim2 = cipher_skin.find_child("AnimationPlayer", true, false)
		print("Cipher AnimationPlayer: ", anim2)
		if anim2:
			print("Cipher Animations: ", anim2.get_animation_list())

	quit(0)
