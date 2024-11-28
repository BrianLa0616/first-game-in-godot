extends Node

var score = 0

@onready var score_label = $ScoreLabel
@onready var line_edit: LineEdit = $"../LineEdit"
@onready var http_request: HTTPRequest = $"../LineEdit/HTTPRequest"

var url = "https://api.openai.com/v1/chat/completions"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	line_edit.text_submitted.connect(_on_LineEdit_text_entered)
	
func add_point():
	score += 1
	score_label.text = "You collected " + str(score) + " coins."

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
	
func _on_LineEdit_text_entered(new_text: String) -> void:
	var API_KEY = load_env()
	var request_body = JSON.new().stringify({
		"model": "gpt-3.5-turbo",  # Change to "gpt-4" if desired
		"messages": [
			{"role": "system", "content": "An expert coder in godot 4.0"},
			{"role": "user", "content": new_text}
		],
		"temperature": 0.7
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
	print(message)
