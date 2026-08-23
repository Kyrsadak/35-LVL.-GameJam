extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var f = FileAccess.open("res://tools/anim_test_output.txt", FileAccess.WRITE)
	f.store_line("=== TESTING ANIMATIONS ===")
	
	var atlas_scene = load("res://characters/robots/RobotAtlas.tscn")
	var cipher_scene = load("res://characters/robots/RobotCipher.tscn")
	
	var atlas = atlas_scene.instantiate()
	root.add_child(atlas)
	var cipher = cipher_scene.instantiate()
	root.add_child(cipher)
	
	var atlas_skin = atlas.get_node("Skin")
	var cipher_skin = cipher.get_node("Skin")
	
	f.store_line("Atlas anim_player: " + str(atlas_skin.anim_player))
	f.store_line("Cipher anim_player: " + str(cipher_skin.anim_player))
	
	if atlas_skin.anim_player:
		f.store_line("Atlas anims: " + str(atlas_skin.anim_player.get_animation_list()))
	if cipher_skin.anim_player:
		f.store_line("Cipher anims: " + str(cipher_skin.anim_player.get_animation_list()))
		
	# Test update_move_animation
	atlas_skin.update_move_animation(1.0, 0.016)
	cipher_skin.update_move_animation(1.0, 0.016)
	
	f.store_line("Atlas current_anim: " + str(atlas_skin.current_anim) + " | is_playing: " + str(atlas_skin.anim_player.is_playing() if atlas_skin.anim_player else false))
	f.store_line("Cipher current_anim: " + str(cipher_skin.current_anim) + " | is_playing: " + str(cipher_skin.anim_player.is_playing() if cipher_skin.anim_player else false))
	
	var atlas_leg = atlas_skin.get_node_or_null("Visuals/LeftLegPivot")
	var cipher_leg = cipher_skin.get_node_or_null("Visuals/LeftLegPivot")
	f.store_line("Atlas leg node: " + str(atlas_leg))
	f.store_line("Cipher leg node: " + str(cipher_leg))
	
	f.close()
	quit()
