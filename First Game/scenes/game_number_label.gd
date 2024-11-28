extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.text = "Game number " + str(SceneSwitcher.gameNumber)
