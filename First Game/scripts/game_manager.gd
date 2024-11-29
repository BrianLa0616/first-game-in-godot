extends Node

var score = 0

@onready var score_label = $ScoreLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
func add_point():
	score += 1
	score_label.text = "You collected " + str(score) + " coins."
