extends Node

var score = 0

@onready var score_label = $ScoreLabel
@onready var next_level_button: Button = $"../NextLevelButton"
@onready var player: CharacterBody2D = $"../Player"
@onready var WorldGeneration: Node = $"../WorldGeneration"
@onready var open_ai: Node = $"../OpenAI"

const enemyPath = preload("res://scenes/slime.tscn")

var url = "https://api.openai.com/v1/chat/completions"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if (SceneSwitcher.scenePrompt != null):
		print("calling world request completed")
		WorldGeneration._on_world_request_completed(SceneSwitcher.scenePrompt)
	open_ai.connect("categorization_completed", Callable(self, "_on_categorization_completed"))
	
	if not InputMap.has_action("shoot"):
		InputMap.add_action("shoot")
		
	var ev = InputEventKey.new()
	ev.keycode = KEY_F
	InputMap.action_add_event("shoot", ev)


	
func add_point():
	score += 1
	score_label.text = "You collected " + str(score) + " coins."
	
func _on_categorization_completed(message: Array) -> void:	
	var output = message[0]
	var original_input = message[1]
	match output:
		"shoot":
			message = await open_ai.parse_shoot(original_input)
			output = message[0]
			print(message)
			var input = message[1]
			var path = await get_image_path(output[0])
			var speed = output[1]
			player.shoot(path, speed)
		"build":
			print("a")
		"spawn":
			var enemy = enemyPath.instantiate()
			print(player.global_position)
			enemy.global_position = player.global_position + Vector2(10, -10)
			print(type_string(typeof(player.global_position)))
			get_parent().add_child(enemy)
		"gameplay":
			print("c")
		"next level":
			WorldGeneration._on_LineEdit_text_entered(message[1])
		"none":
			print("no matching functionality")

func get_image_path(object):
	var path = ""
	const image_paths = ["res://assets/sprites/fire.webp", "res://assets/sprites/ice.webp", "res://assets/sprites/thunder.webp"]
	var result = await open_ai.closest_match(object)
	path = image_paths[result[0]]
	return path
