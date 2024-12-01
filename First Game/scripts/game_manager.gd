extends Node

var score = 0

@onready var score_label = $ScoreLabel
@onready var next_level_button: Button = $"../NextLevelButton"
@onready var player: CharacterBody2D = $"../Player"
@onready var WorldGeneration: Node = $"../WorldGeneration"
@onready var open_ai: Node = $"../OpenAI"

const enemyPath = preload("res://scenes/slime.tscn")

var url = "https://api.openai.com/v1/chat/completions"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	overlay.connect("request_completed", Callable(self, "_on_request_completed"))

	if (SceneSwitcher.scenePrompt != null):
		print("calling world request completed")
		WorldGeneration._on_world_request_completed(SceneSwitcher.scenePrompt)
	open_ai.connect("categorization_completed", Callable(self, "_on_categorization_completed"))

	next_level_button.pressed.connect(_on_next_level_button_pressed)
	line_edit.text_submitted.connect(_on_LineEdit_text_entered)
	add_key_action("shoot", Key.KEY_F)
	
func add_point():
	score += 1
	score_label.text = "You collected " + str(score) + " coins."
	
func _on_categorization_completed(message: Array) -> void:	
	var output = message[0]
	var original_input = message[1]
	match output:
		"shoot":
			message = await open_ai.parse_shoot(original_input)
			output = message[0]
			print(message)
			var input = message[1]
			var path = await get_image_path(output[0])
			var speed = output[1]
			player.shoot(path, speed)
		"build":
			print("a")
		"spawn":
			var enemy = enemyPath.instantiate()
			print(player.global_position)
			enemy.global_position = player.global_position + Vector2(10, -10)
			print(type_string(typeof(player.global_position)))
			get_parent().add_child(enemy)
		"gameplay":
			print("c")
		"none":
			print("no matching functionality")

func get_image_path(object):
	var path = ""
	const image_paths = ["res://assets/sprites/fire.webp", "res://assets/sprites/ice.webp", "res://assets/sprites/thunder.webp"]
	var result = await open_ai.closest_match(object)
	path = image_paths[result[0]]
	return path

func _on_next_level_button_pressed() -> void:
	# Define the source and destination paths
	var currentGameIndex = SceneSwitcher.gameNumber
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
	
func split_game_scene_text(source_scene_text: String) -> Dictionary:
	var start_marker = "[node name=\"Game\" type=\"Node2D\"]"
	var end_marker = "[node name=\"Coins\" type=\"Node\" parent=\".\"]"
	
	var start_pos = source_scene_text.find(start_marker)
	if start_pos == -1:
		push_error("Start marker not found.")
		return {}
		
	var end_pos = source_scene_text.find(end_marker, start_pos)
	if end_pos == -1:
		push_error("End marker not found.")
		return {}
		
	end_pos += end_marker.length()
	
	var before_text = source_scene_text.substr(0, start_pos)
	var middle_text = source_scene_text.substr(start_pos, end_pos - start_pos)
	var after_text = source_scene_text.substr(end_pos)
	
	return {
		"before": before_text,
		"middle": middle_text,
		"after": after_text
	}
	
func _on_LineEdit_text_entered(new_text: String) -> void:
	var API_KEY = load_env()
	
	var currentGameIndex = SceneSwitcher.gameNumber
	var nextGameIndex = currentGameIndex + 1
	var source_scene_path
	if (currentGameIndex == 1):
		source_scene_path = "res://scenes/game.tscn"
	else:
		source_scene_path = "res://scenes/game" + str(currentGameIndex) + ".tscn"
		
	# Load the source scene
	var source_scene = ResourceLoader.load(source_scene_path)
	if source_scene == null:
		push_error("Source scene not found: %s" % source_scene_path)
		return
	
	var file = FileAccess.open(source_scene_path, FileAccess.ModeFlags.READ)
	if file == null:
		push_error("Failed to open source scene file: %s" % source_scene_path)
		return
	
	var source_scene_text = file.get_as_text()
	file.close()
	
	var result = split_game_scene_text(source_scene_text)
	
	mostRecentResult = result

	var request_body = JSON.new().stringify({
		"model": "gpt-4",
		"messages": [
			{"role": "system", "content": "An expert coder in Godot 4.0"},
			{"role": "user", "content": "The nodes for the game.tscn file for my current scene is provided below."},
			{"role": "user", "content": result["after"]},
			{"role": "user", "content": "Use the following text prompt to make minor additions/changes 
			to the the nodes of my game.tscn file, ensuring correct syntax and that we follow Godot 4.0 conventions."},
			{"role": "user", "content": new_text},
			{"role": "user", "content": "Now provide the correct nodes of the game.tscn file based off the prompt 
			to reflect the updated scene. Make sure to spawn any nodes roughly in the vicinity of existing nodes. 
			Make sure to provide ONLY .tscn format code and none of your words as I am parsing your output as code only."},
		],
		"temperature": 0.0
	})

	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + API_KEY
	]

	http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)
	
func load_env() -> String:
	var file = FileAccess.open("res://.env", FileAccess.READ)
	var content = file.get_as_text()
	if content.begins_with("OPENAI_API_KEY="):
		return content.replace("OPENAI_API_KEY=", "").strip_edges()
	return ""

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()	
	var message = response["choices"][0]["message"]["content"]
	
	print("openai output")
	print(message)
	
	var next_game_index = SceneSwitcher.gameNumber + 1
	var new_scene_path = "res://scenes/game" + str(next_game_index) + ".tscn"

	# Save generated code to the new .tscn file
	var file = FileAccess.open(new_scene_path, FileAccess.ModeFlags.WRITE)
	if file == null:
		push_error("Failed to open file for writing: %s" % new_scene_path)
		return
	
	var new_scene_text = mostRecentResult["before"] + mostRecentResult["middle"] + mostRecentResult["after"] + message

	file.store_string(new_scene_text)
	file.close()
	print_debug("New scene saved to: ", new_scene_path)

	# Switch to the newly created scene
	SceneSwitcher.switch_scene(new_scene_path)


func _on_line_edit_focus_entered() -> void:
	pass

func add_key_action(action="shoot", key=Key.KEY_F):
	if not InputMap.has_action(action):
		InputMap.add_action(action)

	var f_key_event = InputEventKey.new()
	f_key_event.keycode = key # Set the key to "E"
	f_key_event.pressed = true  # Define it as a key press event

	InputMap.action_add_event(action, f_key_event)
