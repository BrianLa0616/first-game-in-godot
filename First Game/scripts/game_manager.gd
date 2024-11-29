extends Node

var score = 0

@onready var score_label = $ScoreLabel
@onready var next_level_button: Button = $"../NextLevelButton"
@onready var overlay: CanvasLayer = $"../Overlay"
@onready var player: CharacterBody2D = $"../Player"

const enemyPath = preload("res://scenes/slime.tscn")

var url = "https://api.openai.com/v1/chat/completions"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	overlay.connect("request_completed", Callable(self, "_on_request_completed"))
	
func add_point():
	score += 1
	score_label.text = "You collected " + str(score) + " coins."

func _on_request_completed(message: Array) -> void:	
	var result = overlay.closest_match(message)
	if result[0] == 0 and result[1] < .5:
		player.shoot()
	if result[0] == 2 and result[1] < .5:
		var enemy = enemyPath.instantiate()
		get_parent().add_child(enemy)
