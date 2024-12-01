extends Area2D

@onready var animation_player = $AnimationPlayer
signal collected

func _on_body_entered(body):
	animation_player.play("pickup")
	emit_signal("collected")
