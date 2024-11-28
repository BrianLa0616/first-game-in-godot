extends Node

var current_scene = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(get_tree().root.get_children())
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	
func switch_scene(res_path):
	call_deferred("_deferred_switch_scene", res_path)
	
func _deferred_switch_scene(res_path):
	print_debug("res_path: ", res_path)
	var root = get_tree().root
	print_debug("number of children: ", root.get_child_count())
	print_debug("current scene: ", current_scene)
	current_scene.free()
	var s = load(res_path)
	current_scene = s.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene
