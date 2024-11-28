extends CharacterBody2D
# Called when the node enters the scene tree for the first time.
var direction = Vector2(0, 0)
const speed = 300


func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	velocity = direction * speed
	move_and_slide()
	pass

func set_direction(dir: Vector2) -> void:
	direction = dir
