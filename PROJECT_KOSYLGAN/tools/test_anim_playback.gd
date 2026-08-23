@tool
extends SceneTree

func _init():
	print("--- TEST ANIMATION PLAYBACK ---")
	var atlas_scene = load("res://characters/robots/RobotAtlas.tscn")
	var atlas = atlas_scene.instantiate()
	var root = Node3D.new()
	root.add_child(atlas)
	
	var skin = atlas.get_node("Skin")
	var anim_player: AnimationPlayer = skin.find_child("AnimationPlayer", true, false)
	print("Atlas Skin anim_player: ", anim_player)
	print("Has Run anim: ", anim_player.has_animation("Run") if anim_player else false)
	
	if anim_player:
		anim_player.play("Run")
		anim_player.advance(0.16)
		var left_leg = skin.find_child("LeftLegPivot", true, false)
		print("LeftLegPivot rotation after 0.16s in Run: ", left_leg.rotation if left_leg else "NOT FOUND")
		var right_leg = skin.find_child("RightLegPivot", true, false)
		print("RightLegPivot rotation after 0.16s in Run: ", right_leg.rotation if right_leg else "NOT FOUND")

	var cipher_scene = load("res://characters/robots/RobotCipher.tscn")
	var cipher = cipher_scene.instantiate()
	root.add_child(cipher)
	
	var c_skin = cipher.get_node("Skin")
	var c_anim: AnimationPlayer = c_skin.find_child("AnimationPlayer", true, false)
	if c_anim:
		c_anim.play("Run")
		c_anim.advance(0.16)
		var c_left_leg = c_skin.find_child("LeftLegPivot", true, false)
		print("Cipher LeftLegPivot rotation after 0.16s in Run: ", c_left_leg.rotation if c_left_leg else "NOT FOUND")
		var c_right_arm = c_skin.find_child("RightArmPivot", true, false)
		print("Cipher RightArmPivot rotation after 0.16s in Run: ", c_right_arm.rotation if c_right_arm else "NOT FOUND")
	
	root.free()
	quit(0)
