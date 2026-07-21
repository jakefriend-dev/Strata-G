extends MoveAction

func PREVIEW(motion: Vector2):
	if actor.action_points == 0:
		error_text = "Can't walk when no AP"
		return
	
	if motion == Vector2.ZERO:
		error_text = "walkdir not set correctly"
		return
	
	var to_coord: Vector2 = actor.coord + motion
	if !support.is_tile_traversable_exact(actor, to_coord):
		error_text = "Can't walk that way!"
		return
	
	passfail = true
	pass

func ACT(motion: Vector2):
	var dur: float = actor.tile_walk_speed
	
	var exact_coord: Vector2 = actor.coord + motion
	actor.hotmove(exact_coord, dur)
	
	yield(utils.yt(dur, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	end_action()
	pass

