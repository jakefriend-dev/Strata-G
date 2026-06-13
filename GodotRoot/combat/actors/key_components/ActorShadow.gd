extends ColorRect

#func estimate_size(s: Sprite):
#	var size: Vector2 = s.texture.get_size()
#	size.x *= 0.6
#	size.y *= 0.3
#
#	rect_size = size
#	recenter()
#	pass

func recenter():
	rect_position = -(rect_size/2.0)
	pass




