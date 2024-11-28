extends Node

var score = 0

@onready var score_label = $ScoreLabel

func add_point():
	score += 1
	score_label.text = "You collected " + str(score) + " coins."

func _on_next_level_button_pressed() -> void:
	# Define the source and destination paths
	var root = get_tree().root
	var currentGameIndex = root.get_child_count() - 2
	var nextGameIndex = currentGameIndex + 1
	var source_scene_path
	if (currentGameIndex == 1):
		source_scene_path = "res://scenes/game.tscn"
	else:
		source_scene_path = "res://scenes/game" + str(currentGameIndex) + ".tscn"
	
	print_debug("currentGameIndex: ", currentGameIndex)
	var destination_scene_path = "res://scenes/game" + str(nextGameIndex) + ".tscn"
	var current_scene_path = "res://scenes/game" + str(currentGameIndex) + ".tscn"
	
	# Load the source scene
	var source_scene = ResourceLoader.load(source_scene_path)
	if source_scene == null:
		push_error("Source scene not found: %s" % source_scene_path)
		return
	
	# Save the duplicated scene to the destination path
	var save_result = ResourceSaver.save(source_scene, destination_scene_path)
	if save_result != OK:
		push_error("Failed to save duplicated scene: %s" % destination_scene_path)
		return
	
	print_debug("destination_scene_path: ", destination_scene_path)
	# Switch to the duplicated scene
	SceneSwitcher.switch_scene(destination_scene_path)
