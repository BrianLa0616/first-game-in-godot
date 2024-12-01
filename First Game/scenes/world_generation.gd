extends Node

signal request_completed(response_data)

@onready var http_request: HTTPRequest = $HTTPRequest
@onready var GameManager: Node = %GameManager
@onready var player: CharacterBody2D = $"../Player"

const coinPath = preload("res://scenes/gen_coin.tscn")
const enemyPath = preload("res://scenes/slime.tscn")
const platformPath = preload("res://scenes/platform.tscn")

var url = "https://api.openai.com/v1/chat/completions"
var embeddingUrl = "https://api.openai.com/v1/embeddings"

#var mostRecentResult

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

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
	
	var next_game_index = SceneSwitcher.gameNumber + 1
	var new_scene_path = "res://scenes/game" + str(next_game_index) + ".tscn"

	# Save generated code to the new .tscn file
	var newFile = FileAccess.open(new_scene_path, FileAccess.ModeFlags.WRITE)
	if newFile == null:
		push_error("Failed to open file for writing: %s" % new_scene_path)
		return
	
	#var new_scene_text = mostRecentResult["before"] + mostRecentResult["middle"] + mostRecentResult["after"] + message

	newFile.store_string(source_scene_text)
	newFile.close()
	print_debug("New scene saved to: ", new_scene_path)
	
	#var result = split_game_scene_text(source_scene_text)
	#
	#mostRecentResult = result

	#var request_body = JSON.new().stringify({
		#"model": "gpt-4",
		#"messages": [
			#{"role": "system", "content": "An expert coder in Godot 4.0"},
			#{"role": "user", "content": "The nodes for the game.tscn file for my current scene is provided below."},
			#{"role": "user", "content": result["after"]},
			#{"role": "user", "content": "Use the following text prompt to make minor additions/changes 
			#to the the nodes of my game.tscn file, ensuring correct syntax and that we follow Godot 4.0 conventions."},
			#{"role": "user", "content": new_text},
			#{"role": "user", "content": "Now provide the correct nodes of the game.tscn file based off the prompt 
			#to reflect the updated scene. Make sure to spawn any nodes roughly in the vicinity of existing nodes. 
			#Make sure to provide ONLY .tscn format code and none of your words as I am parsing your output as code only."},
		#],
		#"temperature": 0.0
	#})
	
	var request_body = JSON.new().stringify({
		"model": "text-embedding-3-small",
		"input": new_text
	})

	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + API_KEY
	]

	http_request.request(embeddingUrl, headers, HTTPClient.METHOD_POST, request_body)
	
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
	#var message = response["choices"][0]["message"]["content"]
	var message = response["data"][0]["embedding"]
	#save_world_array(message)
	
	var next_game_index = SceneSwitcher.gameNumber + 1
	var new_scene_path = "res://scenes/game" + str(next_game_index) + ".tscn"
	
	SceneSwitcher.scenePrompt = message
	
	# Switch to the newly created scene
	SceneSwitcher.switch_scene(new_scene_path)
	
func save_world_array(array):
	var data = load_world_array()
	data.append(array)
	var file = FileAccess.open("res://data/world_array_data.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	
	return data

func load_world_array() -> Array:
	if FileAccess.file_exists("res://data/world_array_data.json"):
		var file = FileAccess.open("res://data/world_array_data.json", FileAccess.READ)
		var json = JSON.new()
		var data = json.parse_string(file.get_as_text())
		file.close()
		return data
	return []
	
func cosine_difference(vec_a, vec_b):
	# returns the cosine similarity of 2 embeddings
	
	if vec_a.size() != vec_b.size():
		print("Vectors must be the same size")
		return 0.0

	var dot_product = 0.0
	var magnitude_a = 0.0
	var magnitude_b = 0.0
	
	# Calculate dot product and magnitudes
	for i in range(vec_a.size()):
		dot_product += vec_a[i] * vec_b[i]
		magnitude_a += vec_a[i] * vec_a[i]
		magnitude_b += vec_b[i] * vec_b[i]
	
	# Calculate magnitudes
	magnitude_a = sqrt(magnitude_a)
	magnitude_b = sqrt(magnitude_b)
	
	# Avoid division by zero
	if magnitude_a == 0.0 or magnitude_b == 0.0:
		print("One or both vectors have zero magnitude")
		return 0.0
	
	# Return cosine similarity
	return 1 - (dot_product / (magnitude_a * magnitude_b))
	
func closest_match(query) -> Array:
	# return index of the closest match and its cosine similarity
	var best_index = -1
	var best_difference = 1
	var dict = load_world_array()
	for i in range(dict.size()):
		var difference = cosine_difference(dict[i], query)
		if difference < best_difference:
			best_index = i
			best_difference = difference
	print(best_index)
	print(best_difference)
	return [best_index, best_difference]

func _on_line_edit_focus_entered() -> void:
	pass


func _on_line_edit_text_submitted(new_text: String) -> void:
	pass # Replace with function body.


#### world request ####

func _on_collected():
	GameManager.add_point()
		
func _on_world_request_completed(message: Array) -> void:
	print("on world request completed")	
	var result = self.closest_match(message)
	if result[0] == 0 and result[1] < .5:
		print("adding more coins")
		# add more coins
		var coins_node = get_parent().get_node("Coins")
		if coins_node == null:
			print("Error: 'Coins' node not found!")
			return
		for i in range(25):
			var coin = coinPath.instantiate()
			coin.position = Vector2(randf_range(15, 1000), randf_range(-100, 120))
			coin.connect("collected", Callable(self, "_on_collected"))
			coins_node.add_child(coin)
	elif result[0] == 1 and result[1] < .5:
		# add more slimes
		print("adding more slimes")
		for i in range(10):
			var enemy = enemyPath.instantiate()
			enemy.position = Vector2(randf_range(15, 1000), randf_range(-100, 150))
			get_parent().add_child.call_deferred(enemy)
	elif result[0] == 2 and result[1] < .5:
		# add more platforms
		print("adding more platforms")
		for i in range(10):
			var platform = platformPath.instantiate()
			platform.position = Vector2(randf_range(15, 1000), randf_range(-100, 150))
			get_parent().add_child.call_deferred(platform)
	elif result[0] == 3 and result[1] < .5:
		# add a lot more coins
		print("adding a lot more coins")
		var coins_node = get_parent().get_node("Coins")
		if coins_node == null:
			print("Error: 'Coins' node not found!")
			return
		for i in range(100):
			var coin = coinPath.instantiate()
			coin.position = Vector2(randf_range(15, 1000), randf_range(-100, 120))
			coin.connect("collected", Callable(self, "_on_collected"))
			coins_node.add_child(coin)
	elif result[0] == 4 and result[1] < .5:
		# add a lot more slimes
		print("adding a lot more slimes")
		for i in range(100):
			var enemy = enemyPath.instantiate()
			enemy.position = Vector2(randf_range(15, 1000), randf_range(-100, 150))
			get_parent().add_child.call_deferred(enemy)
	else:
		print("didn't match any choices")
