extends CanvasLayer

@onready var line_edit: LineEdit = $LineEdit
@onready var open_ai: Node = $"../OpenAI"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#line_edit.text_submitted.connect(_on_LineEdit_text_entered)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_line_edit_text_submitted(text: String) -> void:
	#Uncomment when you want to store an embedding
	#open_ai.get_embedding(text)
	open_ai.categorize(text)
	
