extends Node

@onready var line_edit: LineEdit = $"../LineEdit"
@onready var http_request: HTTPRequest = $"../LineEdit/HTTPRequest"

var url = "https://api.openai.com/v1/chat/completions"
var embeddingUrl = "https://api.openai.com/v1/embeddings"

var mostRecentResult

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	line_edit.text_submitted.connect(_on_LineEdit_text_entered)

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


func _on_line_edit_text_submitted(new_text: String) -> void:
	pass # Replace with function body.
