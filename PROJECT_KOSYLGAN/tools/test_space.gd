
extends SceneTree

func _init():
    var meshlib = load('res://assets/kits/meshlib_space_ground.tres')
    if meshlib:
        print('SUCCESS! Loaded Space MeshLibrary')
        for id in meshlib.get_item_list():
            print('  Space Item ', id, ': ', meshlib.get_item_name(id))
    else:
        print('FAILED!')
    quit()
