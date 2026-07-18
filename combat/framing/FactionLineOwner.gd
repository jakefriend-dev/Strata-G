extends YSort

var coord: Vector2

# ---

func _ready():
	change_active(true)
	pass

func change_active(tf: bool):
	$Offset/Particles2D.emitting = tf
	pass
