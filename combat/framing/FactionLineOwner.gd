extends YSort

func _ready():
	change_active(true)
	pass

func change_active(tf: bool):
	$Offset/Particles2D.emitting = tf
	pass
