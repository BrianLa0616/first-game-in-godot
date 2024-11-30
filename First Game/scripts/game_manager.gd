extends Node

var score = 0

@onready var score_label = $ScoreLabel
@onready var next_level_button: Button = $"../NextLevelButton"
@onready var overlay: CanvasLayer = $"../Overlay"
@onready var player: CharacterBody2D = $"../Player"
@onready var world_generation: Node = $"../WorldGeneration"

const coinPath = preload("res://scenes/coin.tscn")
const enemyPath = preload("res://scenes/slime.tscn")
const platformPath = preload("res://scenes/platform.tscn")

var url = "https://api.openai.com/v1/chat/completions"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	overlay.connect("request_completed", Callable(self, "_on_request_completed"))
	world_generation.connect("world_request_completed", Callable(self, "_on_world_request_completed"))
	
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
		
func _on_world_request_completed(message: Array) -> void:	
	var result = world_generation.closest_match(message)
	if result[0] == 0 and result[1] < .5:
		# add more coins
		for i in range(10):
			var coin = coinPath.instantiate()
			get_parent().add_child(coin)
	if result[0] == 1 and result[1] < .5:
		# add more slimes
		var enemy = enemyPath.instantiate()
		get_parent().add_child(enemy)
	if result[0] == 2 and result[1] < .5:
		# add more platforms
		for i in range(3):
			var platform = platformPath.instantiate()
			get_parent().add_child(platform)
	if result[0] == 3 and result[1] < .5:
		pass # add more tiles
