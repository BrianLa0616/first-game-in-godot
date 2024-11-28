extends Node

var gameNumber = 1

var current_scene = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(get_tree().root.get_children())
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	
func switch_scene(res_path):
	call_deferred("_deferred_switch_scene", res_path)
	gameNumber += 1
	
func _deferred_switch_scene(res_path):
	var treechildren = get_tree().root.get_children()
	print_debug("scene swticher tree: ", treechildren)
	var root = get_tree().root
	current_scene.free()
	var s = load(res_path)
	current_scene = s.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene
	var newtreechildren = get_tree().root.get_children()
	print_debug("new scene swticher tree: ", newtreechildren)
	print_debug("res_path: ", res_path)