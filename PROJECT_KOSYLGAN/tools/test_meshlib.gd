
extends SceneTree

func _init():
    var meshlib = load('res://assets/kits/meshlib_prototype_bits.tres')
    if meshlib:
        print('SUCCESS! Loaded MeshLibrary: ', meshlib.get_class())
        var count = meshlib.get_item_list().size()
        print('Total items in MeshLibrary: ', count)
        for id in meshlib.get_item_list():
            print('  Item ', id, ': ', meshlib.get_item_name(id))
    else:
        print('FAILED to load MeshLibrary!')
    quit()
