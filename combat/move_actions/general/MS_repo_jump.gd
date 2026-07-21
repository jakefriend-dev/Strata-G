extends MoveAction

var post_jump_rumble_time: float = 0.2

func PREVIEW():
	var target: Vector2 = support.get_rand_faction_tile_for_actormoving(actor, actor.faction)
	if target == actor.coord:
		error_text = "Nowhere eligible to jump to"
		print("Repo preview fail")
		return
	
	print("Repo preview success to: ",target)
	add_cell(target, ROWS.NEUTRAL)
	passfail = true
	pass

func ACT():
	var dur: float = 0.5
	
	var target: Vector2 = get_first_cell_by_MPD_type(ROWS.NEUTRAL)
	print("Repo gonna jump to: ",target)
	actor.hotjump(target, dur)
	
	yield(utils.yt(dur, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	yield(utils.yt(post_jump_rumble_time, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	end_action()
	pass

