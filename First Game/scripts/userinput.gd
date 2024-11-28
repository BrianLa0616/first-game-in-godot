extends CanvasLayer

@onready var line_edit: LineEdit = $LineEdit

var url = "https://api.openai.com/v1/chat/completions"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	line_edit.text_submitted.connect(_on_LineEdit_text_entered)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_LineEdit_text_entered(new_text: String) -> void:
	load_env()
	pass
	
func load_env() -> String:
	var file = FileAccess.open("res://.env", FileAccess.READ)
	var content = file.get_as_text()
	print(content)
	if content.begins_with("OPENAI_API_KEY="):
		return content.replace("OPENAI_API_KEY=", "").strip_edges()
	return ""
