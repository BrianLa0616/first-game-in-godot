extends CharacterBody2D
# Called when the node enters the scene tree for the first time.
var direction = Vector2(0, 0)
var speed = 300
var distance_traveled = 0

func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	velocity = direction * speed
	distance_traveled += speed * delta
	if distance_traveled > 200:
		queue_free()
	move_and_slide()
	pass

func set_direction(direction: Vector2) -> void:
	self.direction = direction
	
func set_speed(speed) -> void:
	self.speed = speed
	
