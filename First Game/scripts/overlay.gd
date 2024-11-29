extends CanvasLayer

signal request_completed(response_data)

@onready var line_edit: LineEdit = $LineEdit
@onready var http_request: HTTPRequest = $LineEdit/HTTPRequest



var url = "https://api.openai.com/v1/chat/completions"
var embeddingUrl = "https://api.openai.com/v1/embeddings"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#line_edit.text_submitted.connect(_on_LineEdit_text_entered)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_line_edit_text_submitted(new_text: String) -> void:
	var API_KEY = load_env()
	#var request_body = JSON.new().stringify({
		#"model": "gpt-3.5-turbo",  # Change to "gpt-4" if desired
		#"messages": [
			#{"role": "system", "content": "An expert coder in godot 4.0"},
			#{"role": "user", "content": new_text}
		#],
		#"temperature": 0.7
	#})
	
	var request_body = JSON.new().stringify({
		"model": "text-embedding-3-small",  # Change to "gpt-4" if desired
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
	#save_array(message)
	emit_signal("request_completed", message)
	
func save_array(array):
	var data = load_array()
	data.append(array)
	var file = FileAccess.open("res://data/array_data.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	
	return data

func load_array() -> Array:
	if FileAccess.file_exists("res://data/array_data.json"):
		var file = FileAccess.open("res://data/array_data.json", FileAccess.READ)
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
	var dict = load_array()
	for i in range(dict.size()):
		var difference = cosine_difference(dict[i], query)
		if difference < best_difference:
			best_index = i
			best_difference = difference
	return [best_index, best_difference]
	
	
