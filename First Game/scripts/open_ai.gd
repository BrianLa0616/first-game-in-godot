extends Node

@onready var embedding_request: HTTPRequest = $EmbeddingRequest
@onready var generation_request: HTTPRequest = $GenerationRequest
@onready var categorize_request: HTTPRequest = $CategorizeRequest
@onready var shoot_request: HTTPRequest = $ShootRequest

signal generation_completed(response_data)
signal categorization_completed(response_data)

const url = "https://api.openai.com/v1/chat/completions"
const embeddingUrl = "https://api.openai.com/v1/embeddings"
const image_embeddings_path = "res://data/image_embeddings.json"
const image_name_path = "res://data/image_info.json"

var API_KEY = load_env()
var original_input = ""
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func load_env() -> String:
	var file = FileAccess.open("res://.env", FileAccess.READ)
	var content = file.get_as_text()
	if content.begins_with("OPENAI_API_KEY="):
		return content.replace("OPENAI_API_KEY=", "").strip_edges()
	return ""
	
func save_array(sentence: String, embedding: Array, data_path=image_embeddings_path, info_path=image_name_path):
	var embedding_data = load_array(data_path)
	embedding_data.append(embedding)
	var file = FileAccess.open(data_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(embedding_data))
	file.close()
	
	var sentence_data = load_array(info_path)
	sentence_data.append(sentence)
	file = FileAccess.open(info_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(sentence_data))
	file.close()
	
	return embedding_data

func load_array(path: String) -> Array:
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
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
	
func closest_match(query, data_path=image_embeddings_path) -> Array:
	# return index of the closest match and its cosine similarity
	var query_embedding = (await get_embedding(query))[0]
	var best_index = -1
	var best_difference = 1
	var dict = load_array(data_path)
	for i in range(dict.size()):
		var difference = cosine_difference(dict[i], query_embedding)
		if difference < best_difference:
			best_index = i
			best_difference = difference

	return [best_index, best_difference]

func get_embedding(text: String):
	original_input = text
	var request_body = JSON.new().stringify({
		"model": "text-embedding-3-small",  # Change to "gpt-4" if desired
		"input": text
	})

	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + API_KEY
	]

	var request_result = embedding_request.request(embeddingUrl, headers, HTTPClient.METHOD_POST, request_body)
	if request_result == OK:
		var signal_response = await embedding_request.request_completed
		return process_embedding_response(signal_response)
	
	print("Embeddings not properly parsed")
	return []
	
func process_embedding_response(signal_response: Array) -> Array:
	var result: int = signal_response[0]
	var response_code: int = signal_response[1]
	var headers: PackedStringArray = signal_response[2]
	var body: PackedByteArray = signal_response[3]
	
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	var message = response["data"][0]["embedding"]
	#save_array(original_input, message, image_embeddings_path, image_name_path)
	return [message, original_input]

func get_generation(new_text: String):
	original_input = new_text
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

	generation_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

func _on_generation_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	var message = response["choices"][0]["message"]["content"]
	emit_signal("generation_completed", [message, original_input])

func categorize(input: String):
	original_input = input
	const tools = [{
		"type": "function",
		"function": {
			"name": "handle_action",
			"description": "Handles game actions based on input.",
			"parameters": {
				"type": "object",
				"properties": {
					"action": {
						"type": "string",
						"enum": ["shoot", "build", "spawn", "gameplay", "none"],
					}
				},
				"required": ["action"]
			}
		}
	}]

	var request_body = JSON.new().stringify({
		"model": "gpt-4o",  # Change to "gpt-4" if desired
		"messages": [
			{"role": "user", "content": "Categorize the user input into 5 categories: shoot, build, spawn, gameplay, or none. Always use function calling.\n" + input}
		],
		"temperature": 0.7,
		"tools": tools
	})

	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + API_KEY
	]

	categorize_request.request(url, headers, HTTPClient.METHOD_POST, request_body)
	
func _on_categorize_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	var tool_call = response["choices"][0]["message"]["tool_calls"][0]
	var arguments = tool_call['function']['arguments']
	json.parse(arguments)
	arguments = json.get_data()
	var message = arguments["action"]
	emit_signal("categorization_completed", [message, original_input])

func parse_shoot(input: String):
	original_input = input
	const tools = [{
		"type": "function",
		"function": {
			"name": "handle_shooting",
			"description": "Handles shooting actions based on input. Returns projectile item and its speed",
			"parameters": {
				"type": "object",
				"properties": {
					"projectile": {
						"type": "string",
						"default": "fire"
					},
					"speed": {
						"type": "integer",
						"default": 300
					}
				},
				"required": ["projectile", "speed"]
			}
		}
	}]

	var request_body = JSON.new().stringify({
		"model": "gpt-4o",  # Change to "gpt-4" if desired
		"messages": [
			{"role": "user", "content": "Parse the user input to shoot something. Always use function calling.\n" + input}
		],
		"temperature": 0.7,
		"tools": tools
	})

	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + API_KEY
	]
	var request_result = await shoot_request.request(url, headers, HTTPClient.METHOD_POST, request_body)
	if request_result == OK:
		var signal_response = await shoot_request.request_completed
		return process_shoot_response(signal_response)
	
	print("Shooting not properly parsed")
	return []
	
func process_shoot_response(signal_response: Array):
	var result: int = signal_response[0]
	var response_code: int = signal_response[1]
	var headers: PackedStringArray = signal_response[2]
	var body: PackedByteArray = signal_response[3]
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	var tool_call = response["choices"][0]["message"]["tool_calls"][0]
	var arguments = tool_call['function']['arguments']
	json.parse(arguments)
	arguments = json.get_data()
	var projectile = arguments["projectile"]
	var speed = arguments["speed"]
	var message = [projectile, speed]
	return  [message, original_input]
