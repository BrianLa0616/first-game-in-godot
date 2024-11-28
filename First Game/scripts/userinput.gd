extends CanvasLayer

@onready var line_edit: LineEdit = $LineEdit
@onready var http_request: HTTPRequest = $LineEdit/HTTPRequest



var url = "https://api.openai.com/v1/chat/completions"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	line_edit.text_submitted.connect(_on_LineEdit_text_entered)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
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
	pass # Replace with function body.


func _on_text_edit_focus_entered() -> void:
	pass # Replace with function body.
