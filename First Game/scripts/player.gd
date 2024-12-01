extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite2D
@onready var overlay: CanvasLayer = $"../Overlay"

const projectilePath = preload('res://scenes/projectile.tscn')
@onready var next_stage_line_edit: LineEdit = $"../LineEdit"

func _ready() -> void:
	pass
func _physics_process(delta):
	var line_edit = overlay.get_node("LineEdit")
	if line_edit.has_focus():
		return
	if next_stage_line_edit.has_focus():
		return
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if Input.is_action_just_pressed("shoot"):
		shoot()
	
	# Get the input direction: -1, 0, 1
	var direction = Input.get_axis("move_left", "move_right")
	
	# Flip the Sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# Play animations
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")
	
	# Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
func shoot(imagePath="res://assets/sprites/fire.webp", speed=300):
	var projectile = projectilePath.instantiate()
	projectile.position = $Marker2D.global_position if not animated_sprite.flip_h else $Marker2D2.global_position
	var direction = Vector2.RIGHT if not animated_sprite.flip_h else Vector2.LEFT
	projectile.set_direction(direction)
	projectile.set_speed(speed)
	var image = load(imagePath)
	projectile.get_node("Sprite2D").texture = image
	get_parent().add_child(projectile)
	
