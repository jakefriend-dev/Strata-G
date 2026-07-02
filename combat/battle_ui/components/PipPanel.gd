extends Panel

var pipcount: int # Set/controlled by BUI
var value: int = 4 # Set/controlled by BUI
# Preset on instancing BEFORE adding to tree, but in theory always max
# Setting this is controlled by BUI so all data is fed at once from the same general algorithm

var sprite: Sprite
var bui: Node2D

# ---

func _ready():
	sprite = $Sprite
	pass

func refresh():
	if sprite.frame != value:
		sprite.frame = value
	pass


