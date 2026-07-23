extends MoveAction

# COMMON move, so we don't want to reference a built-in 'actor' var; we want to send that in.



func PREVIEW():
	print("-\nWALK's preview manual_variant: ",manual_variant," when actor coord: ",actor.coord)
	
	if actor.action_points == 0:
		print("Walk outcome FAIL, action points")
		error_text = "Can't walk when no AP"
		return
	
	if manual_variant == Vector2.ZERO:
		print("Walk outcome FAIL, zerovec")
		error_text = "walkdir not set correctly"
		return
	
	var to_coord: Vector2 = actor.coord + manual_variant
	if !support.is_tile_traversable_exact(actor, to_coord):
		print("Walk outcome FAIL, can't walk that way")
		error_text = "Can't walk that way!"
		return
	
	print("Walk outcome PASS")
	passfail = true
	pass

func ACT():
#	print("WALK's act manual_variant: ",manual_variant)
	
	var dur: float = actor.tile_walk_speed
	
	var exact_coord: Vector2 = actor.coord + manual_variant
	actor.hotslide(exact_coord, dur)
#	print(actor.name,"'s WALK start (",manual_variant,") at: ",actor.get_tree().get_frame())
	
	yield(utils.yt(dur, actor), "timeout")
	if !batman.is_my_action(actor): return
	
#	print(actor.name,"'s WALK end at: ",actor.get_tree().get_frame())
	
	end_action()
	pass

