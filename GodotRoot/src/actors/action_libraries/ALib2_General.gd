extends ActionLibrary

var actor: Actor

func hotmove(to_coord: Vector2, dur: float):
	tween.interpolate_property(actor, "position", null, batman.grid_gpos.get_cellv(to_coord), dur,Tween.TRANS_CIRC, Tween.EASE_IN_OUT)
	tween.start()
	pass

func hotjump(to_coord: Vector2, dur: float, height: float = 100.0):
	tween.interpolate_property(actor, "position", null, batman.grid_gpos.get_cellv(to_coord), dur,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.interpolate_property(actor.vis_object, "position:y", null, -height, dur/2.0,Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tween.interpolate_property(actor.vis_object, "position:y", -height, 0.0, dur/2.0,Tween.TRANS_CUBIC, Tween.EASE_IN, dur/2.0)
	tween.start()
	pass

