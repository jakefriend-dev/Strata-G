extends MoveAction

# COMMON move, so we don't want to reference a built-in 'actor' var; we want to send that in.

func PREVIEW(who: Actor, motion: Vector2):
	if who.action_points == 0:
		error_text = "Can't walk when no AP"
		return
	
	if motion == Vector2.ZERO:
		error_text = "walkdir not set correctly"
		return
	
	var to_coord: Vector2 = who.coord + motion
	if !support.is_tile_traversable_exact(who, to_coord):
		error_text = "Can't walk that way!"
		return
	
	passfail = true
	pass

func ACT(who: Actor, motion: Vector2):
	var dur: float = who.tile_walk_speed
	
	var exact_coord: Vector2 = who.coord + motion
	who.hotmove(exact_coord, dur)
	
	yield(utils.yt(dur, who), "timeout")
	if !batman.is_my_action(who): return
	
	end_action()
	pass

